import Foundation

@MainActor
final class FavoriteFolderDetailViewModel: ObservableObject {
    @Published private(set) var detail: FavoriteFolderDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let apiClient: BiliAPIClient
    let folder: FavoriteFolder
    private let pageSize = 20
    private var nextPage = 1

    init(apiClient: BiliAPIClient, folder: FavoriteFolder) {
        self.apiClient = apiClient
        self.folder = folder
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        actionMessage = nil
        nextPage = 1

        do {
            let loadedDetail = try await fetchDetail(page: nextPage)
            detail = loadedDetail
            nextPage = 2
            canLoadMore = loadedDetail.hasMore
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
            canLoadMore = false
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading else { return }
        guard !isLoadingMore else { return }
        guard canLoadMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let loadedDetail = try await fetchDetail(page: nextPage)
            if var currentDetail = detail {
                let existingIDs = Set(currentDetail.medias.map(\.id))
                currentDetail = FavoriteFolderDetail(
                    info: currentDetail.info ?? loadedDetail.info,
                    medias: currentDetail.medias + loadedDetail.medias.filter { !existingIDs.contains($0.id) },
                    hasMore: loadedDetail.hasMore
                )
                detail = currentDetail
            } else {
                detail = loadedDetail
            }
            nextPage += 1
            canLoadMore = loadedDetail.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(media: FavoriteMedia) async {
        guard let aid = media.video.aid else {
            errorMessage = "\u{7f3a}\u{5c11} aid\u{ff0c}\u{6682}\u{65f6}\u{4e0d}\u{80fd}\u{79fb}\u{51fa}\u{6536}\u{85cf}\u{5939}\u{3002}"
            return
        }

        do {
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.favoriteVideoBatchDeal,
                form: [
                    "resources": "\(aid):2",
                    "add_media_ids": "",
                    "del_media_ids": "\(folder.id)",
                    "csrf": csrf
                ]
            )
            if var currentDetail = detail {
                currentDetail.medias.removeAll { $0.id == media.id }
                detail = currentDetail
            }
            actionMessage = L10n.removedFromFavorite(folder.title)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchDetail(page: Int) async throws -> FavoriteFolderDetail {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.favoriteFolderDetail,
            query: [
                "media_id": "\(folder.id)",
                "pn": "\(page)",
                "ps": "\(pageSize)",
                "keyword": "",
                "order": "mtime",
                "type": "0",
                "tid": "0",
                "platform": "web"
            ]
        )
        return FavoriteFolderDetail(
            info: JSONValue.dictionary(data["info"]).map(FavoriteFolder.init),
            medias: JSONValue.dictionaries(data["medias"]).map(FavoriteMedia.init),
            hasMore: JSONValue.bool(data["has_more"]) ?? false
        )
    }

    func toggleFolderSubscription() async {
        do {
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.favoriteFolderSubscribe,
                form: [
                    "media_id": "\(folder.id)",
                    "csrf": csrf
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
