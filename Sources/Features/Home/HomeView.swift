import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @ObservedObject private var preferencesStore: AppPreferencesStore
    private let apiClient: BiliAPIClient
    private let onTapSearch: () -> Void
    private let onTapDynamic: () -> Void
    private let onTapHistory: () -> Void
    private let onTapProfile: () -> Void

    init(
        apiClient: BiliAPIClient,
        onTapSearch: @escaping () -> Void,
        onTapDynamic: @escaping () -> Void,
        onTapHistory: @escaping () -> Void,
        onTapProfile: @escaping () -> Void
    ) {
        self.apiClient = apiClient
        self._preferencesStore = ObservedObject(wrappedValue: apiClient.preferencesStore)
        self.onTapSearch = onTapSearch
        self.onTapDynamic = onTapDynamic
        self.onTapHistory = onTapHistory
        self.onTapProfile = onTapProfile
        _viewModel = StateObject(wrappedValue: HomeViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    introPanel
                    featuredCarousel
                    quickActions
                    feedSelector
                    liveSection
                    bangumiSection

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .biliCardStyle(tint: .red.opacity(0.24))
                    }

                    if viewModel.isLoading && currentVideos.isEmpty {
                        ProgressView(L10n.homeLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    } else if currentVideos.isEmpty && !hasSupplementalSections {
                        EmptyStateView(
                            title: L10n.homeEmptyTitle,
                            subtitle: L10n.homeEmptySubtitle,
                            systemImage: "play.slash",
                            actionTitle: L10n.homeLoadAction,
                            action: {
                                Task { await viewModel.reload() }
                            }
                        )
                    } else if !currentVideos.isEmpty {
                        highlightsSection
                        feedSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
            .background {
                BiliBackground {
                    Color.clear
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadIfNeeded()
            }
            .onChange(of: preferencesStore.isGuestRecommendationEnabled) { _ in
                Task { await viewModel.reload() }
            }
            .refreshable {
                await viewModel.reload()
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

    private var currentVideos: [VideoSummary] {
        switch viewModel.selectedFeed {
        case .recommended:
            return viewModel.recommendedVideos
        case .hot:
            return viewModel.hotVideos
        }
    }

    private var featuredVideos: [VideoSummary] {
        Array(currentVideos.prefix(3))
    }

    private var highlightVideos: [VideoSummary] {
        Array(currentVideos.dropFirst().prefix(4))
    }

    private var listVideos: [VideoSummary] {
        if currentVideos.count > 5 {
            return Array(currentVideos.dropFirst(5))
        }
        return currentVideos
    }

    private var isLoadingMoreCurrentFeed: Bool {
        switch viewModel.selectedFeed {
        case .recommended:
            return viewModel.isLoadingMoreRecommended
        case .hot:
            return viewModel.isLoadingMoreHot
        }
    }

    private var canLoadMoreCurrentFeed: Bool {
        switch viewModel.selectedFeed {
        case .recommended:
            return viewModel.canLoadMoreRecommended
        case .hot:
            return viewModel.canLoadMoreHot
        }
    }

    private var hasSupplementalSections: Bool {
        !viewModel.liveHighlights.isEmpty || !viewModel.bangumiHighlights.isEmpty
    }

    private var introPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.appTitle)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text(L10n.homeNativeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                HStack(spacing: 10) {
                    Button(action: onTapHistory) {
                        BiliSymbolOrb(systemImage: "clock.arrow.circlepath", lightweight: true)
                    }
                    .buttonStyle(.plain)

                    Button(action: onTapProfile) {
                        BiliSymbolOrb(systemImage: "person.crop.circle", lightweight: true)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: onTapSearch) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color("AccentColor"))
                    Text(viewModel.searchPlaceholder.isEmpty ? L10n.searchPlaceholderDefault : viewModel.searchPlaceholder)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Image(systemName: "sparkles")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .biliPanelCardStyle(tint: Color("AccentColor").opacity(0.32), interactive: true)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                BiliMetricPill(text: "\(viewModel.recommendedVideos.count) \u{6761}\u{63a8}\u{8350}", systemImage: "play.square.stack")
                BiliMetricPill(text: "\(viewModel.hotVideos.count) \u{6761}\u{70ed}\u{95e8}", systemImage: "flame.fill", tint: .orange)
                BiliMetricPill(text: L10n.homeHeroBadge, systemImage: "sparkles.tv", tint: .pink)
                if preferencesStore.isGuestRecommendationEnabled {
                    BiliMetricPill(text: L10n.guestModeTitle, systemImage: "person.crop.circle.badge.questionmark", tint: .blue)
                }
            }
        }
        .padding(20)
        .biliPanelCardStyle(tint: .pink.opacity(0.34), interactive: true)
    }

    @ViewBuilder
    private var featuredCarousel: some View {
        if featuredVideos.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 14) {
                BiliSectionHeader(title: L10n.homeFeaturedTitle, subtitle: L10n.homeFeaturedSubtitle)

                TabView {
                    ForEach(featuredVideos) { video in
                        NavigationLink(value: video) {
                            HomeFeaturedCard(video: video)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 248)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.commonActions, subtitle: L10n.homeQuickActionsSubtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    Button(action: onTapSearch) {
                        BiliQuickActionTile(
                            title: L10n.tabSearch,
                            subtitle: L10n.homeSearchActionSubtitle,
                            systemImage: "magnifyingglass",
                            tint: Color("AccentColor")
                        )
                        .frame(width: 170)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel.selectedFeed = .hot
                        }
                    } label: {
                        BiliQuickActionTile(
                            title: L10n.feedHot,
                            subtitle: L10n.homeHotActionSubtitle,
                            systemImage: "flame.fill",
                            tint: .orange
                        )
                        .frame(width: 170)
                    }
                    .buttonStyle(.plain)

                    Button(action: onTapDynamic) {
                        BiliQuickActionTile(
                            title: L10n.tabDynamic,
                            subtitle: L10n.homeDynamicActionSubtitle,
                            systemImage: "bubble.left.and.bubble.right.fill",
                            tint: .teal
                        )
                        .frame(width: 170)
                    }
                    .buttonStyle(.plain)

                    Button(action: onTapHistory) {
                        BiliQuickActionTile(
                            title: L10n.historyTitle,
                            subtitle: L10n.homeHistoryActionSubtitle,
                            systemImage: "clock.arrow.circlepath",
                            tint: .blue
                        )
                        .frame(width: 170)
                    }
                    .buttonStyle(.plain)

                    Button(action: onTapProfile) {
                        BiliQuickActionTile(
                            title: L10n.tabProfile,
                            subtitle: L10n.homeProfileActionSubtitle,
                            systemImage: "person.crop.circle.fill",
                            tint: .pink
                        )
                        .frame(width: 170)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var feedSelector: some View {
        HStack(spacing: 10) {
            feedChip(for: .recommended, systemImage: "sparkles")
            feedChip(for: .hot, systemImage: "flame.fill")
            Spacer(minLength: 8)
            Button {
                Task { await viewModel.reload() }
            } label: {
                BiliSymbolOrb(systemImage: "arrow.clockwise", tint: Color("AccentColor"), size: 40, lightweight: true)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var highlightsSection: some View {
        if !highlightVideos.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                BiliSectionHeader(title: L10n.homeHighlightsTitle, subtitle: L10n.contentSubtitle(highlightVideos.count))

                LazyVGrid(columns: highlightColumns, spacing: 12) {
                    ForEach(highlightVideos) { video in
                        NavigationLink(value: video) {
                            HomeCompactVideoCard(video: video)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var liveSection: some View {
        if !viewModel.liveHighlights.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                BiliSectionHeader(title: L10n.homeLiveTitle, subtitle: L10n.homeLiveSubtitle)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.liveHighlights) { item in
                            if let reference = item.streamerReference {
                                NavigationLink(value: reference) {
                                    HomeLiveCard(item: item)
                                        .frame(width: 240)
                                }
                                .buttonStyle(.plain)
                            } else {
                                HomeLiveCard(item: item)
                                    .frame(width: 240)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var bangumiSection: some View {
        if !viewModel.bangumiHighlights.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                BiliSectionHeader(title: L10n.homeBangumiTitle, subtitle: L10n.homeBangumiSubtitle)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.bangumiHighlights) { item in
                            HomeBangumiCard(item: item)
                                .frame(width: 208)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: viewModel.selectedFeed.title,
                subtitle: L10n.contentSubtitle(currentVideos.count),
                actionTitle: canLoadMoreCurrentFeed ? L10n.loadMore : nil,
                action: canLoadMoreCurrentFeed ? { Task { await loadMoreCurrentFeed() } } : nil
            )

            LazyVStack(spacing: 14) {
                ForEach(listVideos) { video in
                    NavigationLink(value: video) {
                        VideoRow(video: video)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        triggerLoadMoreIfNeeded(for: video)
                    }
                }
            }

            if isLoadingMoreCurrentFeed {
                ProgressView(L10n.loadingMore)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
    }

    private var highlightColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func feedChip(for mode: HomeViewModel.FeedMode, systemImage: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel.selectedFeed = mode
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(mode.title)
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(viewModel.selectedFeed == mode ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(viewModel.selectedFeed == mode ? Color("AccentColor") : Color(.systemBackground).opacity(0.72))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(viewModel.selectedFeed == mode ? 0.0 : 0.05), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func triggerLoadMoreIfNeeded(for video: VideoSummary) {
        guard shouldLoadMore(after: video) else { return }

        Task {
            await loadMoreCurrentFeed()
        }
    }

    private func shouldLoadMore(after video: VideoSummary) -> Bool {
        guard canLoadMoreCurrentFeed else { return false }

        let triggerIDs = Set(listVideos.suffix(3).map(\.id))
        return triggerIDs.contains(video.id)
    }

    private func loadMoreCurrentFeed() async {
        switch viewModel.selectedFeed {
        case .recommended:
            await viewModel.loadMoreRecommendedVideos()
        case .hot:
            await viewModel.loadMoreHotVideos()
        }
    }
}

private struct HomeLiveCard: View {
    let item: HomeLiveSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncPosterImage(urlString: item.coverURL, width: nil, height: 140)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(item.streamerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
                    .lineLimit(1)

                if let areaName = item.areaName, !areaName.isEmpty {
                    Text(areaName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .biliListCardStyle(tint: .pink, interactive: true)
    }
}

private struct HomeBangumiCard: View {
    let item: HomeBangumiSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncPosterImage(urlString: item.coverURL, width: nil, height: 172)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let updateLabel = item.updateLabel, !updateLabel.isEmpty {
                    Text(updateLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AccentColor"))
                        .lineLimit(1)
                }

                if let ratingLabel = item.ratingLabel, !ratingLabel.isEmpty {
                    Text(ratingLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .biliListCardStyle(tint: .orange, interactive: true)
    }
}

private struct HomeFeaturedCard: View {
    let video: VideoSummary

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncPosterImage(urlString: video.coverURL, width: nil, height: 248)
                .frame(maxWidth: .infinity)
                .drawingGroup(opaque: true)

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    BiliMetricPill(
                        text: BiliFormatting.compactCount(video.viewCount),
                        systemImage: "play.fill",
                        tint: .white,
                        foreground: .white
                    )
                    BiliMetricPill(
                        text: BiliFormatting.duration(video.duration),
                        systemImage: "clock.fill",
                        tint: .white,
                        foreground: .white
                    )
                }

                Text(video.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(video.reason ?? video.subtitle ?? L10n.homeHeroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .biliHeroCardStyle(cornerRadius: 28, tint: .pink)
    }
}

private struct HomeCompactVideoCard: View {
    let video: VideoSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncPosterImage(urlString: video.coverURL, width: nil, height: 112)
                .frame(maxWidth: .infinity)

            Text(video.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label(BiliFormatting.compactCount(video.viewCount), systemImage: "play.fill")
                Label(BiliFormatting.compactCount(video.danmakuCount), systemImage: "text.bubble.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .biliListCardStyle(tint: .blue, interactive: true)
    }
}
