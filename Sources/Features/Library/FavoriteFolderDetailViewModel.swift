import Foundation

@MainActor
final class FavoriteFolderDetailViewModel: ObservableObject {
    @Published private(set) var detail: FavoriteFolderDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let apiClient: BiliAPIClient
    let folder: FavoriteFolder

    init(apiClient: BiliAPIClient, folder: FavoriteFolder) {
        self.apiClient = apiClient
        self.folder = folder
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        actionMessage = nil

        do {
            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.favoriteFolderDetail,
                query: [
                    "media_id": "\(folder.id)",
                    "pn": "1",
                    "ps": "20",
                    "keyword": "",
                    "order": "mtime",
                    "type": "0",
                    "tid": "0",
                    "platform": "web"
                ]
            )
            detail = FavoriteFolderDetail(
                info: JSONValue.dictionary(data["info"]).map(FavoriteFolder.init),
                medias: JSONValue.dictionaries(data["medias"]).map(FavoriteMedia.init),
                hasMore: JSONValue.bool(data["has_more"]) ?? false
            )
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
        }

        isLoading = false
    }

    func remove(media: FavoriteMedia) async {
        guard let aid = media.video.aid else {
            errorMessage = "\u{7f3a}\u{5c11} aid\u{ff0c}\u{6682}\u{65f6}\u{4e0d}\u{80fd}\u{79fb}\u{51fa}\u{6536}\u{85cf}\u{5939}\u{3002}"
            return
        }

        do {
            let csrf = try apiClient.requireCSRFToken()
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

    func toggleFolderSubscription() async {
        do {
            let csrf = try apiClient.requireCSRFToken()
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
