import Foundation

@MainActor
final class VideoCommentsViewModel: ObservableObject {
    enum SortMode: CaseIterable, Identifiable {
        case hottest
        case newest

        var id: String {
            switch self {
            case .hottest:
                return "hottest"
            case .newest:
                return "newest"
            }
        }

        var apiMode: String {
            switch self {
            case .hottest:
                return "3"
            case .newest:
                return "2"
            }
        }

        var title: String {
            switch self {
            case .hottest:
                return L10n.videoCommentsSortHot
            case .newest:
                return L10n.videoCommentsSortNew
            }
        }
    }

    @Published private(set) var sortMode: SortMode = .hottest
    @Published private(set) var topReplies: [VideoComment] = []
    @Published private(set) var replies: [VideoComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = false
    @Published private(set) var totalCount = 0
    @Published private(set) var inputPlaceholder: String?
    @Published private(set) var childInputPlaceholder: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let apiClient: BiliAPIClient
    let replyTypeValue: Int
    private var currentOID: Int?
    private var nextOffset = ""
    private var nextLegacyPage = 1
    private var isUsingLegacyPaging = false
    private var hasLoaded = false

    init(apiClient: BiliAPIClient, replyType: Int = 1) {
        self.apiClient = apiClient
        self.replyTypeValue = replyType
    }

    func loadIfNeeded(oid: Int?) async {
        guard let oid, oid > 0 else { return }

        if currentOID != oid {
            currentOID = oid
            hasLoaded = false
            nextOffset = ""
            nextLegacyPage = 1
            isUsingLegacyPaging = false
            topReplies = []
            replies = []
        }

        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        guard let currentOID, currentOID > 0 else { return }
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        actionMessage = nil
        defer { isLoading = false }

        do {
            let page = try await fetchPage(oid: currentOID, offset: "", pageNumber: 1, sortMode: sortMode)
            topReplies = page.topReplies
            replies = page.replies
            nextOffset = page.nextOffset
            nextLegacyPage = page.nextPageNumber
            isUsingLegacyPaging = page.isLegacyPaging
            canLoadMore = page.isLegacyPaging
                ? !page.isEnd
                : (!page.isEnd && !page.nextOffset.isEmpty)
            totalCount = page.totalCount
            inputPlaceholder = page.inputPlaceholder
            childInputPlaceholder = page.childInputPlaceholder
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            topReplies = []
            replies = []
            canLoadMore = false
        }
    }

    func loadMore() async {
        guard let currentOID, currentOID > 0 else { return }
        guard !isLoading else { return }
        guard !isLoadingMore else { return }
        guard canLoadMore else { return }
        if !isUsingLegacyPaging, nextOffset.isEmpty { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchPage(
                oid: currentOID,
                offset: isUsingLegacyPaging ? "" : nextOffset,
                pageNumber: nextLegacyPage,
                sortMode: sortMode
            )
            let existingIDs = Set(replies.map(\.id))
            replies.append(contentsOf: page.replies.filter { !existingIDs.contains($0.id) })
            nextOffset = page.nextOffset
            nextLegacyPage = page.nextPageNumber
            isUsingLegacyPaging = page.isLegacyPaging
            canLoadMore = page.isLegacyPaging
                ? !page.isEnd
                : (!page.isEnd && !page.nextOffset.isEmpty)
            totalCount = max(totalCount, page.totalCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setSortMode(_ sortMode: SortMode) async {
        guard self.sortMode != sortMode else { return }
        self.sortMode = sortMode
        hasLoaded = false
        nextOffset = ""
        nextLegacyPage = 1
        isUsingLegacyPaging = false
        await reload()
    }

    func postComment(message: String, replyingTo: VideoComment? = nil) async -> Bool {
        guard let currentOID, currentOID > 0 else { return false }

        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        do {
            let csrf = try await apiClient.requireCSRFToken()
            var form: [String: String] = [
                "type": "\(replyTypeValue)",
                "oid": "\(currentOID)",
                "message": trimmed,
                "csrf": csrf
            ]

            if let replyingTo {
                if let root = replyingTo.rootNumericID {
                    form["root"] = "\(root)"
                }
                if let parent = replyingTo.numericID {
                    form["parent"] = "\(parent)"
                }
            }

            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.replyAdd,
                form: form
            )

            let successMessage = replyingTo == nil ? L10n.videoCommentsPosted : L10n.videoCommentsReplyPosted
            await reload()
            actionMessage = successMessage
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggleLike(for comment: VideoComment) async {
        guard let currentOID, currentOID > 0 else { return }
        guard let rpid = comment.numericID else {
            errorMessage = L10n.videoCommentsLikeUnavailable
            return
        }

        do {
            errorMessage = nil
            let shouldLike = !comment.isLiked
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.replyLike,
                form: [
                    "type": "\(replyTypeValue)",
                    "oid": "\(currentOID)",
                    "rpid": "\(rpid)",
                    "action": shouldLike ? "1" : "0",
                    "csrf": csrf
                ]
            )

            topReplies = updateLikeState(in: topReplies, targetID: comment.id, isLiked: shouldLike)
            replies = updateLikeState(in: replies, targetID: comment.id, isLiked: shouldLike)
            actionMessage = shouldLike ? L10n.videoCommentsLiked : L10n.videoCommentsUnliked
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchPage(
        oid: Int,
        offset: String,
        pageNumber: Int,
        sortMode: SortMode
    ) async throws -> VideoCommentPage {
        let paginationString = #"{"offset":"\#(offset)"}"#
        do {
            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.replyMain,
                query: [
                    "oid": "\(oid)",
                    "type": "\(replyTypeValue)",
                    "mode": sortMode.apiMode,
                    "pagination_str": paginationString
                ]
            )
            return VideoCommentPage(json: data)
        } catch {
            let legacyData = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.replyList,
                query: [
                    "oid": "\(oid)",
                    "type": "\(replyTypeValue)",
                    "sort": sortMode == .hottest ? "1" : "2",
                    "pn": "\(pageNumber)",
                    "ps": "20"
                ]
            )
            return VideoCommentPage(json: legacyData)
        }
    }

    private func updateLikeState(in comments: [VideoComment], targetID: String, isLiked: Bool) -> [VideoComment] {
        comments.map { comment in
            guard comment.id == targetID else { return comment }
            return comment.toggledLikeState(to: isLiked)
        }
    }
}
