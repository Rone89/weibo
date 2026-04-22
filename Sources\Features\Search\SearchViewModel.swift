import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    private enum Keys {
        static let history = "search.history"
    }

    @Published var query = "" {
        didSet {
            scheduleSuggestionFetch()
        }
    }
    @Published private(set) var placeholder = L10n.searchPlaceholderDefault
    @Published private(set) var suggestions: [SearchSuggestion] = []
    @Published private(set) var trendingKeywords: [TrendingKeyword] = []
    @Published private(set) var recommendedKeywords: [TrendingKeyword] = []
    @Published private(set) var history: [String] = []
    @Published private(set) var results: [VideoSummary] = []
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingLanding = false
    @Published private(set) var hasCommittedSearch = false
    @Published private(set) var errorMessage: String?

    private let apiClient: BiliAPIClient
    private var hasLoadedLanding = false
    private var suggestionTask: Task<Void, Never>?

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
        self.history = UserDefaults.standard.stringArray(forKey: Keys.history) ?? []
    }

    func loadLandingIfNeeded() async {
        guard !hasLoadedLanding else { return }
        await reloadLanding()
    }

    func reloadLanding() async {
        isLoadingLanding = true
        errorMessage = nil
        do {
            async let placeholder = fetchSearchPlaceholder()
            async let trending = fetchTrendingKeywords()
            async let recommended = fetchRecommendedKeywords()

            self.placeholder = try await placeholder
            self.trendingKeywords = try await trending
            self.recommendedKeywords = try await recommended
            self.hasLoadedLanding = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingLanding = false
    }

    func submitSearch() async {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyword = normalized.isEmpty ? placeholder : normalized
        guard !keyword.isEmpty else { return }

        query = keyword
        suggestions = []
        hasCommittedSearch = true
        isSearching = true
        errorMessage = nil
        addToHistory(keyword)

        do {
            let refererKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.searchByType,
                query: [
                    "search_type": "video",
                    "keyword": keyword,
                    "page": "1",
                    "page_size": "20",
                    "platform": "pc",
                    "web_location": "1430654"
                ],
                headers: [
                    "origin": "https://search.bilibili.com",
                    "referer": "https://search.bilibili.com/video?keyword=\(refererKeyword)"
                ],
                signedByWBI: true
            )
            results = JSONValue.dictionaries(data["result"]).map(VideoSummary.init)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isSearching = false
    }

    func useKeyword(_ keyword: String) {
        query = keyword
        Task { await submitSearch() }
    }

    func removeHistoryItem(_ item: String) {
        history.removeAll { $0 == item }
        UserDefaults.standard.set(history, forKey: Keys.history)
    }

    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: Keys.history)
    }

    private func scheduleSuggestionFetch() {
        suggestionTask?.cancel()
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            suggestions = []
            return
        }

        suggestionTask = Task {
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            await fetchSuggestions(for: normalized)
        }
    }

    private func fetchSuggestions(for text: String) async {
        do {
            let object = try await apiClient.requestJSON(
                baseURL: BiliBaseURL.search,
                path: BiliEndpoint.searchSuggest,
                query: [
                    "term": text,
                    "main_ver": "v1",
                    "highlight": text
                ]
            )

            guard let root = object as? [String: Any],
                  let result = JSONValue.dictionary(root["result"]) else {
                suggestions = []
                return
            }

            suggestions = JSONValue.dictionaries(result["tag"]).map(SearchSuggestion.init)
        } catch {
            suggestions = []
        }
    }

    private func fetchSearchPlaceholder() async throws -> String {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.searchDefault,
            query: ["web_location": "333.1365"],
            signedByWBI: true
        )
        return JSONValue.string(data["name"]) ?? L10n.searchPlaceholderDefault
    }

    private func fetchTrendingKeywords() async throws -> [TrendingKeyword] {
        let object = try await apiClient.requestJSON(
            baseURL: BiliBaseURL.search,
            path: BiliEndpoint.searchTrending,
            query: ["limit": "10"]
        )
        guard let root = object as? [String: Any] else {
            throw APIError.invalidPayload
        }
        let code = JSONValue.int(root["code"]) ?? -1
        guard code == 0 else {
            throw APIError.server(JSONValue.string(root["message"]) ?? L10n.trendingLoadFailed)
        }
        let data = JSONValue.dictionary(root["data"]) ?? [:]
        return JSONValue.dictionaries(data["list"]).map(TrendingKeyword.init)
    }

    private func fetchRecommendedKeywords() async throws -> [TrendingKeyword] {
        let data = try await apiClient.requestEnvelopeData(
            baseURL: BiliBaseURL.app,
            path: BiliEndpoint.searchRecommend,
            query: [
                "build": "8430300",
                "channel": "master",
                "version": "8.43.0",
                "c_locale": "zh_CN",
                "mobi_app": "android",
                "platform": "android",
                "s_locale": "zh_CN",
                "from": "2"
            ]
        )
        return JSONValue.dictionaries(data["list"]).map(TrendingKeyword.init)
    }

    private func addToHistory(_ keyword: String) {
        history.removeAll { $0 == keyword }
        history.insert(keyword, at: 0)
        if history.count > 12 {
            history = Array(history.prefix(12))
        }
        UserDefaults.standard.set(history, forKey: Keys.history)
    }
}
