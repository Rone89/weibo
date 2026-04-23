import Foundation

@MainActor
final class DynamicViewModel: ObservableObject {
    enum FeedType: String, CaseIterable, Identifiable {
        case all
        case video

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return L10n.dynamicFeedAll
            case .video:
                return L10n.dynamicFeedVideo
            }
        }
    }

    @Published private(set) var hasSession: Bool
    @Published private(set) var selectedFeed: FeedType = .all
    @Published private(set) var items: [DynamicFeedItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = false
    @Published private(set) var errorMessage: String?

    let apiClient: BiliAPIClient
    private let sessionStore: SessionStore
    private var snapshots: [FeedType: FeedSnapshot] = [:]

    init(apiClient: BiliAPIClient, sessionStore: SessionStore) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.hasSession = sessionStore.hasCookie
    }

    func loadIfNeeded() async {
        syncSessionState()

        guard hasSession else {
            clearVisibleData()
            return
        }

        let snapshot = snapshots[selectedFeed] ?? FeedSnapshot()
        if snapshot.hasLoaded {
            apply(snapshot: snapshot)
        } else {
            await reload()
        }
    }

    func reload() async {
        syncSessionState()

        guard hasSession else {
            clearVisibleData()
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let page = try await fetchPage(feed: selectedFeed, offset: "")
            let snapshot = FeedSnapshot(
                items: page.items,
                nextOffset: page.nextOffset,
                hasMore: page.hasMore,
                hasLoaded: true
            )
            snapshots[selectedFeed] = snapshot
            apply(snapshot: snapshot)
        } catch {
            errorMessage = error.localizedDescription
            items = []
            canLoadMore = false
        }
    }

    func loadMore() async {
        syncSessionState()

        guard hasSession else { return }
        guard !isLoading else { return }
        guard !isLoadingMore else { return }
        guard canLoadMore else { return }

        var snapshot = snapshots[selectedFeed] ?? FeedSnapshot()
        guard !snapshot.nextOffset.isEmpty else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchPage(feed: selectedFeed, offset: snapshot.nextOffset)
            let existingIDs = Set(snapshot.items.map(\.id))
            snapshot.items.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
            snapshot.nextOffset = page.nextOffset
            snapshot.hasMore = page.hasMore
            snapshot.hasLoaded = true
            snapshots[selectedFeed] = snapshot
            apply(snapshot: snapshot)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectFeed(_ feed: FeedType) async {
        guard feed != selectedFeed else { return }
        selectedFeed = feed
        errorMessage = nil

        let snapshot = snapshots[feed] ?? FeedSnapshot()
        if snapshot.hasLoaded {
            apply(snapshot: snapshot)
        } else {
            items = []
            canLoadMore = false
            await reload()
        }
    }

    private func fetchPage(feed: FeedType, offset: String) async throws -> DynamicFeedPage {
        var query: [String: String] = [
            "type": feed.rawValue,
            "page": "1",
            "timezone_offset": "-480",
            "features": "itemOpusStyle"
        ]

        if !offset.isEmpty {
            query["offset"] = offset
        }

        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.dynamicFeed,
            query: query
        )

        let parsedItems = JSONValue.dictionaries(data["items"])
            .map(DynamicFeedItem.init)
            .filter { $0.hasDisplayContent }

        return DynamicFeedPage(
            items: parsedItems,
            nextOffset: JSONValue.string(data["offset"]) ?? "",
            hasMore: JSONValue.bool(data["has_more"]) ?? false
        )
    }

    private func syncSessionState() {
        let latest = sessionStore.hasCookie
        if latest != hasSession {
            snapshots = [:]
            if !latest {
                items = []
                canLoadMore = false
            }
        }
        hasSession = latest
    }

    private func clearVisibleData() {
        items = []
        canLoadMore = false
        errorMessage = nil
    }

    private func apply(snapshot: FeedSnapshot) {
        items = snapshot.items
        canLoadMore = snapshot.hasMore && !snapshot.nextOffset.isEmpty
    }
}

private struct FeedSnapshot {
    var items: [DynamicFeedItem] = []
    var nextOffset: String = ""
    var hasMore = false
    var hasLoaded = false
}
