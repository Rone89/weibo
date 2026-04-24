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
                VStack(alignment: .leading, spacing: 20) {
                    headerPanel

                    if !viewModel.suggestions.isEmpty && !viewModel.query.isEmpty {
                        suggestionPanel
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .biliCardStyle(tint: .red.opacity(0.24))
                    }

                    if viewModel.hasCommittedSearch {
                        resultSection
                    } else {
                        landingSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background {
                BiliBackground {
                    Color.clear
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadLandingIfNeeded()
            }
            .refreshable {
                if viewModel.hasCommittedSearch {
                    await viewModel.submitSearch()
                } else {
                    await viewModel.reloadLanding()
                }
            }
            .navigationDestination(for: VideoSummary.self) { video in
                VideoDetailView(
                    viewModel: VideoDetailViewModel(apiClient: apiClient, seedVideo: video)
                )
            }
            .navigationDestination(for: UserReference.self) { reference in
                UserProfileView(apiClient: apiClient, reference: reference)
            }
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tabSearch)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text(L10n.searchDiscoverySubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                BiliSymbolOrb(systemImage: "sparkle.magnifyingglass", tint: .blue, size: 42, lightweight: true)
            }

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
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .biliPanelCardStyle(tint: Color("AccentColor").opacity(0.34), interactive: true)

                Button(L10n.searchAction) {
                    Task { await viewModel.submitSearch() }
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton(fillWidth: false)
                .disabled(viewModel.isSearching)
            }

            HStack(spacing: 10) {
                BiliMetricPill(text: "\(viewModel.trendingKeywords.count) \u{4e2a}\u{70ed}\u{8bcd}", systemImage: "flame.fill", tint: .orange)
                BiliMetricPill(text: "\(viewModel.history.count) \u{6761}\u{5386}\u{53f2}", systemImage: "clock.arrow.circlepath")
                if viewModel.hasCommittedSearch {
                    BiliMetricPill(text: viewModel.selectedScope.title, systemImage: viewModel.selectedScope.systemImage)
                    BiliMetricPill(text: L10n.resultsSubtitle(viewModel.totalResultsCount), systemImage: "text.cursor")
                }
            }
        }
        .padding(20)
        .biliPanelCardStyle(tint: .blue.opacity(0.3), interactive: true)
    }

    private var suggestionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.searchSuggestions, subtitle: L10n.suggestionSubtitle(viewModel.suggestions.count))

            VStack(spacing: 10) {
                ForEach(viewModel.suggestions) { item in
                    Button {
                        viewModel.useKeyword(item.term)
                    } label: {
                        HStack(spacing: 12) {
                            BiliSymbolOrb(systemImage: "sparkle.magnifyingglass", tint: Color("AccentColor"), size: 38, lightweight: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.term)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                if !item.highlightedText.isEmpty, item.highlightedText != item.term {
                                    Text(item.highlightedText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                        }
                        .padding(14)
                        .biliListCardStyle(tint: Color("AccentColor"), interactive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            scopeSelector

            if viewModel.selectedScope == .video {
                videoFilterSection
            }

            HStack(alignment: .center) {
                BiliSectionHeader(
                    title: viewModel.selectedScope.title,
                    subtitle: L10n.resultsSubtitle(viewModel.totalResultsCount)
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
                resultList

                if viewModel.isLoadingMoreResults {
                    ProgressView(L10n.loadingMore)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                } else if viewModel.canLoadMoreResults {
                    Button(L10n.loadMore) {
                        Task { await viewModel.loadMoreResults() }
                    }
                    .buttonStyle(.plain)
                    .biliPrimaryActionButton(fillWidth: false)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var scopeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SearchScope.allCases) { scope in
                    Button {
                        Task { await viewModel.selectScope(scope) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: scope.systemImage)
                            Text(scope.title)
                            if let count = viewModel.scopeCounts[scope] {
                                Text(count > 99 ? "99+" : "\(count)")
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(viewModel.selectedScope == scope ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedScope == scope ? Color("AccentColor") : Color(.systemBackground).opacity(0.72))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(viewModel.selectedScope == scope ? 0 : 0.05), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var videoFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(
                title: L10n.searchFilterTitle,
                subtitle: L10n.searchFilterSubtitle
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(VideoSearchOrder.allCases) { order in
                        filterChip(
                            title: order.title,
                            isSelected: viewModel.selectedVideoOrder == order
                        ) {
                            Task { await viewModel.selectVideoOrder(order) }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(VideoDurationFilter.allCases) { duration in
                        filterChip(
                            title: duration.title,
                            isSelected: viewModel.selectedVideoDuration == duration
                        ) {
                            Task { await viewModel.selectVideoDuration(duration) }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .biliListCardStyle(tint: .blue)
    }

    @ViewBuilder
    private var resultList: some View {
        switch viewModel.selectedScope {
        case .video:
            videoResultsList
        case .user:
            LazyVStack(spacing: 14) {
                ForEach(userResults) { item in
                    NavigationLink(value: item.reference) {
                        SearchUserCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var videoResultsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let topResult = videoResults.first {
                NavigationLink(value: topResult) {
                    SearchBestMatchCard(
                        query: viewModel.query,
                        video: topResult
                    )
                }
                .buttonStyle(.plain)
            }

            if videoResults.count > 1 {
                LazyVStack(spacing: 14) {
                    ForEach(Array(videoResults.dropFirst())) { video in
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
            if !discoveryKeywords.isEmpty {
                searchDiscoveryRow
            }

            if let spotlight = viewModel.trendingKeywords.first ?? viewModel.recommendedKeywords.first {
                Button {
                    viewModel.useKeyword(spotlight.keyword)
                } label: {
                    SearchSpotlightCard(keyword: spotlight)
                }
                .buttonStyle(.plain)
            }

            if viewModel.isLoadingLanding {
                ProgressView(L10n.searchPanelLoading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if viewModel.history.isEmpty &&
                        viewModel.trendingKeywords.isEmpty &&
                        viewModel.recommendedKeywords.isEmpty {
                EmptyStateView(
                    title: L10n.searchLandingEmptyTitle,
                    subtitle: L10n.searchLandingEmptySubtitle,
                    systemImage: "sparkles.rectangle.stack",
                    actionTitle: L10n.searchLandingLoadAction,
                    action: {
                        Task { await viewModel.reloadLanding() }
                    }
                )
            }

            if !viewModel.history.isEmpty {
                SearchKeywordPanel(
                    title: L10n.searchHistory,
                    subtitle: L10n.historySubtitle(viewModel.history.count),
                    actionTitle: L10n.clearHistory,
                    action: { viewModel.clearHistory() }
                ) {
                    SearchTagWrapLayout(spacing: 10, lineSpacing: 10) {
                        ForEach(viewModel.history, id: \.self) { item in
                            keywordChip(
                                title: item,
                                tint: .secondary,
                                action: { viewModel.useKeyword(item) },
                                onDelete: { viewModel.removeHistoryItem(item) }
                            )
                        }
                    }
                }
            }

            if !viewModel.trendingKeywords.isEmpty {
                SearchKeywordPanel(
                    title: L10n.hotSearch,
                    subtitle: L10n.hotKeywordsSubtitle(viewModel.trendingKeywords.count)
                ) {
                    SearchTagWrapLayout(spacing: 10, lineSpacing: 10) {
                        ForEach(viewModel.trendingKeywords) { keyword in
                            keywordChip(title: keyword.keyword, tint: Color("AccentColor")) {
                                viewModel.useKeyword(keyword.keyword)
                            }
                        }
                    }
                }
            }

            if !viewModel.recommendedKeywords.isEmpty {
                SearchKeywordPanel(
                    title: L10n.recommendKeywords,
                    subtitle: L10n.recommendedKeywordSubtitle(viewModel.recommendedKeywords.count)
                ) {
                    SearchTagWrapLayout(spacing: 10, lineSpacing: 10) {
                        ForEach(viewModel.recommendedKeywords) { keyword in
                            keywordChip(title: keyword.keyword, tint: .orange) {
                                viewModel.useKeyword(keyword.keyword)
                            }
                        }
                    }
                }
            }
        }
    }

    private var searchDiscoveryRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.searchDiscoveryTitle, subtitle: L10n.searchDiscoverySubtitle2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(discoveryKeywords) { keyword in
                        Button {
                            viewModel.useKeyword(keyword.keyword)
                        } label: {
                            SearchDiscoveryCard(keyword: keyword)
                                .frame(width: 200)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
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
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    if onDelete == nil {
                        Image(systemName: "arrow.up.left")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(tint)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(tint.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
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

    private var discoveryKeywords: [TrendingKeyword] {
        let combined = viewModel.trendingKeywords + viewModel.recommendedKeywords
        var seen = Set<String>()
        return combined.filter { keyword in
            seen.insert(keyword.keyword).inserted
        }
        .prefix(6)
        .map { $0 }
    }

    private var videoResults: [VideoSummary] {
        viewModel.results.compactMap { item in
            guard case let .video(video) = item else { return nil }
            return video
        }
    }

    private var userResults: [SearchUserResult] {
        viewModel.results.compactMap { item in
            guard case let .user(result) = item else { return nil }
            return result
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color("AccentColor") : Color(.systemBackground).opacity(0.72))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(isSelected ? 0 : 0.05), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }

}

private struct SearchBestMatchCard: View {
    let query: String
    let video: VideoSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.searchBestMatchTitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))

                    Text(query.isEmpty ? video.title : query)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(L10n.searchBestMatchSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                BiliSymbolOrb(systemImage: "play.rectangle.fill", tint: .orange, size: 48, lightweight: true)
            }

            DynamicEmbeddedVideoCard(video: video)
        }
        .padding(18)
        .biliListCardStyle(tint: .orange, interactive: true)
    }
}

private struct SearchDiscoveryCard: View {
    let keyword: TrendingKeyword

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                BiliSymbolOrb(systemImage: "sparkles", tint: .blue, size: 38, lightweight: true)
                Spacer(minLength: 8)
                if let reason = keyword.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                        .lineLimit(1)
                }
            }

            Text(keyword.keyword)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(keyword.reason ?? L10n.searchHeroSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .biliListCardStyle(tint: .blue, interactive: true)
    }
}

private struct SearchSpotlightCard: View {
    let keyword: TrendingKeyword

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.searchSpotlightTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))

                Text(keyword.keyword)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text(keyword.reason ?? L10n.searchHeroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            BiliSymbolOrb(systemImage: "arrow.up.right.circle.fill", tint: .orange, size: 52)
        }
        .padding(20)
        .biliHeroCardStyle(cornerRadius: 28, tint: .orange)
    }
}

private struct SearchKeywordPanel<Content: View>: View {
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    private let content: Content

    init(
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: title, subtitle: subtitle, actionTitle: actionTitle, action: action)
            content
        }
        .padding(18)
        .biliListCardStyle(tint: Color("AccentColor"))
    }
}

private struct SearchUserCard: View {
    let item: SearchUserResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncPosterImage(urlString: item.avatarURL, width: 56, height: 56)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)

                    if let level = item.level {
                        Text(L10n.level(level))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color("AccentColor"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AccentColor").opacity(0.12), in: Capsule())
                    }

                    if item.isLive {
                        Text(L10n.searchUserLiveBadge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.pink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.pink.opacity(0.12), in: Capsule())
                    }
                }

                if let signature = item.signature, !signature.isEmpty {
                    Text(signature)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    if let fansCount = item.fansCount {
                        Label(BiliFormatting.compactCount(fansCount), systemImage: "person.2.fill")
                    }
                    if let videosCount = item.videosCount {
                        Label(BiliFormatting.compactCount(videosCount), systemImage: "play.rectangle.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let verifyInfo = item.verifyInfo, !verifyInfo.isEmpty {
                    Text(verifyInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .biliListCardStyle(tint: .blue, interactive: true)
    }
}

private struct SearchTagWrapLayout: Layout {
    var spacing: CGFloat = 10
    var lineSpacing: CGFloat = 10

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let proposedWidth = currentRowWidth == 0 ? size.width : currentRowWidth + spacing + size.width

            if proposedWidth > maxWidth, currentRowWidth > 0 {
                totalHeight += currentRowHeight + lineSpacing
                maxRowWidth = max(maxRowWidth, currentRowWidth)
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth = proposedWidth
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        totalHeight += currentRowHeight
        maxRowWidth = max(maxRowWidth, currentRowWidth)
        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var origin = CGPoint(x: bounds.minX, y: bounds.minY)
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += currentRowHeight + lineSpacing
                currentRowHeight = 0
            }

            subview.place(
                at: origin,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            origin.x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}
