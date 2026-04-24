import Foundation

@MainActor
final class VideoCommentRepliesViewModel: ObservableObject {
    @Published private(set) var rootComment: VideoComment?
    @Published private(set) var replies: [VideoComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = false
    @Published private(set) var totalCount = 0
    @Published private(set) var inputPlaceholder: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    private let apiClient: BiliAPIClient
    private let oid: Int
    private let replyType: Int
    private let rootID: Int
    private let seedRootComment: VideoComment?
    private var nextPage = 1

    init(
        apiClient: BiliAPIClient,
        oid: Int,
        replyType: Int,
        rootID: Int,
        seedRootComment: VideoComment?
    ) {
        self.apiClient = apiClient
        self.oid = oid
        self.replyType = replyType
        self.rootID = rootID
        self.seedRootComment = seedRootComment
        self.rootComment = seedRootComment
    }

    func loadIfNeeded() async {
        guard replies.isEmpty, !isLoading else { return }
        await reload()
    }

    func reload() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        actionMessage = nil
        nextPage = 1
        defer { isLoading = false }

        do {
            let page = try await fetchPage(page: nextPage)
            rootComment = page.rootComment ?? seedRootComment
            replies = page.replies
            totalCount = page.totalCount
            inputPlaceholder = page.inputPlaceholder
            nextPage = 2
            canLoadMore = replies.count < totalCount
        } catch {
            errorMessage = error.localizedDescription
            replies = []
            canLoadMore = false
        }
    }

    func loadMore() async {
        guard !isLoading else { return }
        guard !isLoadingMore else { return }
        guard canLoadMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchPage(page: nextPage)
            let existingIDs = Set(replies.map(\.id))
            replies.append(contentsOf: page.replies.filter { !existingIDs.contains($0.id) })
            totalCount = max(totalCount, page.totalCount)
            nextPage += 1
            canLoadMore = replies.count < totalCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func postComment(message: String, replyingTo: VideoComment?) async -> Bool {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        do {
            let csrf = try await apiClient.requireCSRFToken()
            var form: [String: String] = [
                "type": "\(replyType)",
                "oid": "\(oid)",
                "root": "\(rootID)",
                "message": trimmed,
                "csrf": csrf
            ]

            if let parent = replyingTo?.numericID ?? rootComment?.numericID ?? seedRootComment?.numericID {
                form["parent"] = "\(parent)"
            } else {
                form["parent"] = "\(rootID)"
            }

            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.replyAdd,
                form: form
            )

            let successMessage = L10n.videoCommentsReplyPosted
            await reload()
            actionMessage = successMessage
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggleLike(for comment: VideoComment) async {
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
                    "type": "\(replyType)",
                    "oid": "\(oid)",
                    "rpid": "\(rpid)",
                    "action": shouldLike ? "1" : "0",
                    "csrf": csrf
                ]
            )

            if rootComment?.id == comment.id {
                rootComment = rootComment?.toggledLikeState(to: shouldLike)
            }
            replies = replies.map { reply in
                guard reply.id == comment.id else { return reply }
                return reply.toggledLikeState(to: shouldLike)
            }
            actionMessage = shouldLike ? L10n.videoCommentsLiked : L10n.videoCommentsUnliked
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchPage(page: Int) async throws -> VideoCommentReplyPage {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.replyReplyList,
            query: [
                "oid": "\(oid)",
                "root": "\(rootID)",
                "pn": "\(page)",
                "type": "\(replyType)",
                "sort": "1"
            ]
        )
        return VideoCommentReplyPage(json: data)
    }
}
