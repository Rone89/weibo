import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    private let apiClient: BiliAPIClient

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
        _viewModel = StateObject(wrappedValue: SearchViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchHero
                    searchBar

                    if !viewModel.suggestions.isEmpty && !viewModel.query.isEmpty {
                        suggestionList
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if viewModel.hasCommittedSearch {
                        resultSection
                    } else {
                        landingSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background {
                BiliBackground {
                    Color.clear
                }
            }
            .navigationTitle(L10n.tabSearch)
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.reloadLanding()
            }
            .navigationDestination(for: VideoSummary.self) { video in
                VideoDetailView(
                    viewModel: VideoDetailViewModel(apiClient: apiClient, seedVideo: video)
                )
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color("AccentColor"))
                TextField(viewModel.placeholder, text: $viewModel.query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.submitSearch() }
                    }
                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .biliCardStyle()

            Button(L10n.searchAction) {
                Task { await viewModel.submitSearch() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentColor"))
        }
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            BiliSectionHeader(title: L10n.searchSuggestions, subtitle: L10n.suggestionSubtitle(viewModel.suggestions.count))

            VStack(spacing: 8) {
                ForEach(viewModel.suggestions) { item in
                    Button {
                        viewModel.useKeyword(item.term)
                    } label: {
                        HStack {
                            Image(systemName: "sparkle.magnifyingglass")
                                .foregroundStyle(Color("AccentColor"))
                            Text(item.highlightedText.isEmpty ? item.term : item.highlightedText)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .biliCardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                BiliSectionHeader(
                    title: L10n.searchResultTitle,
                    subtitle: L10n.resultsSubtitle(viewModel.results.count)
                )
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                }
            }

            if viewModel.results.isEmpty && !viewModel.isSearching {
                EmptyStateView(
                    title: L10n.noSearchResultTitle,
                    subtitle: L10n.noSearchResultSubtitle,
                    systemImage: "magnifyingglass.circle"
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.results) { video in
                        NavigationLink(value: video) {
                            VideoRow(video: video)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var landingSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if viewModel.isLoadingLanding {
                ProgressView(L10n.searchPanelLoading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }

            if !viewModel.history.isEmpty {
                section(title: L10n.searchHistory, subtitle: L10n.historySubtitle(viewModel.history.count)) {
                    FlowLayout(items: viewModel.history) { item in
                        keywordChip(title: item, tint: .secondary) {
                            viewModel.useKeyword(item)
                        } onDelete: {
                            viewModel.removeHistoryItem(item)
                        }
                    }

                    Button(L10n.clearHistory) {
                        viewModel.clearHistory()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            if !viewModel.trendingKeywords.isEmpty {
                section(title: L10n.hotSearch, subtitle: L10n.hotKeywordsSubtitle(viewModel.trendingKeywords.count)) {
                    FlowLayout(items: viewModel.trendingKeywords) { keyword in
                        keywordChip(title: keyword.keyword, tint: Color("AccentColor")) {
                            viewModel.useKeyword(keyword.keyword)
                        }
                    }
                }
            }

            if !viewModel.recommendedKeywords.isEmpty {
                section(title: L10n.recommendKeywords, subtitle: L10n.recommendedKeywordSubtitle(viewModel.recommendedKeywords.count)) {
                    FlowLayout(items: viewModel.recommendedKeywords) { keyword in
                        keywordChip(title: keyword.keyword, tint: .orange) {
                            viewModel.useKeyword(keyword.keyword)
                        }
                    }
                }
            }
        }
    }

    private func section<Content: View>(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: title, subtitle: subtitle)
            content()
        }
    }

    private func keywordChip(
        title: String,
        tint: Color,
        action: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 6) {
            Button(action: action) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(tint.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.tabSearch)
                .font(.system(size: 30, weight: .black, design: .rounded))
            Text(L10n.searchHeroSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                BiliMetricPill(text: "\(viewModel.trendingKeywords.count) \u{4e2a}\u{70ed}\u{8bcd}", systemImage: "flame.fill", tint: .orange)
                BiliMetricPill(text: "\(viewModel.history.count) \u{6761}\u{5386}\u{53f2}", systemImage: "clock.arrow.circlepath")
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.98),
                    Color(red: 0.96, green: 0.98, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
    }
}

private struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                content(item)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
