import Foundation

@MainActor
final class UserRelationListViewModel: ObservableObject {
    @Published private(set) var items: [UserRelationListItem] = []
    @Published private(set) var totalCount = 0
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let apiClient: BiliAPIClient
    let kind: UserRelationListKind
    let reference: UserReference
    private let pageSize = 20
    private var nextPage = 1

    init(apiClient: BiliAPIClient, kind: UserRelationListKind, reference: UserReference) {
        self.apiClient = apiClient
        self.kind = kind
        self.reference = reference
    }

    var isCurrentUser: Bool {
        guard let currentID = apiClient.sessionStore.dedeUserID.flatMap(Int.init) else { return false }
        return currentID == reference.mid
    }

    func loadIfNeeded() async {
        guard items.isEmpty, !isLoading else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        actionMessage = nil
        nextPage = 1
        defer { isLoading = false }

        do {
            let page = try await fetchPage(page: nextPage)
            items = page.items
            totalCount = page.totalCount
            nextPage = 2
            canLoadMore = items.count < totalCount
        } catch {
            errorMessage = error.localizedDescription
            items = []
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
            let existingIDs = Set(items.map(\.id))
            items.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
            totalCount = max(totalCount, page.totalCount)
            nextPage += 1
            canLoadMore = items.count < totalCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFollow(for item: UserRelationListItem) async {
        guard apiClient.sessionStore.hasCookie else {
            errorMessage = L10n.userProfileFollowLoginHint
            return
        }
        guard item.mid != reference.mid else { return }

        do {
            let shouldFollow = !item.isFollowingByCurrentUser
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.userRelationModify,
                form: [
                    "fid": "\(item.mid)",
                    "act": shouldFollow ? "1" : "2",
                    "re_src": "11",
                    "gaia_source": "web_main",
                    "spmid": "333.1387",
                    "extend_content": #"{"entity":"user","entity_id":\#(item.mid),"fp":"\#(BiliAPIClient.userAgent)"}"#,
                    "csrf": csrf
                ],
                query: [
                    "statistics": #"{"appId":100,"platform":5}"#,
                    "x-bili-device-req-json": #"{"platform":"web","device":"pc","spmid":"333.1387"}"#
                ],
                headers: relationHeaders(mid: item.mid)
            )

            items = items.map { current in
                guard current.id == item.id else { return current }
                return current.updatedFollowState(shouldFollow)
            }
            actionMessage = shouldFollow ? L10n.userProfileFollowed : L10n.userProfileUnfollowed
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchPage(page: Int) async throws -> RelationListPage {
        let path = switch kind {
        case .followings:
            BiliEndpoint.userFollowings
        case .fans:
            BiliEndpoint.userFans
        }

        var query: [String: String] = [
            "vmid": "\(reference.mid)",
            "pn": "\(page)",
            "ps": "\(pageSize)",
            "order": "desc"
        ]

        if kind == .fans {
            query["order_type"] = "attention"
        } else {
            query["order_type"] = ""
        }

        let data = try await apiClient.requestEnvelopeData(path: path, query: query)
        return RelationListPage(
            items: JSONValue.dictionaries(data["list"]).map(UserRelationListItem.init),
            totalCount: JSONValue.int(data["total"]) ?? 0
        )
    }

    private func relationHeaders(mid: Int) -> [String: String] {
        [
            "origin": "https://space.bilibili.com",
            "referer": "https://space.bilibili.com/\(mid)/dynamic",
            "user-agent": BiliAPIClient.userAgent
        ]
    }
}

private struct RelationListPage {
    let items: [UserRelationListItem]
    let totalCount: Int
}
