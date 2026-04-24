import SwiftUI

struct VideoDetailView: View {
    @StateObject var viewModel: VideoDetailViewModel
    @State private var selectedPage: VideoDetailPage?
    @State private var playerResetSeed = 0
    @State private var shouldIgnoreResume = false
    @State private var isDescriptionExpanded = false
    @State private var isPresentingFavoritePicker = false
    @State private var playerPanelMinY: CGFloat = 0
    @State private var hasReachedComments = false

    init(viewModel: VideoDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                playerPanel
                headerCard
                overviewSection

                if let errorMessage = viewModel.errorMessage {
                    messageCard(text: errorMessage, tint: .red)
                }

                if let actionMessage = viewModel.actionMessage {
                    messageCard(text: actionMessage, tint: Color("AccentColor"))
                }

                creatorCard
                actionPanel
                commentsSection

                if let detail = viewModel.detail, !detail.pages.isEmpty {
                    section(title: L10n.videoPages, subtitle: L10n.pageSubtitle) {
                        VStack(spacing: 10) {
                            ForEach(detail.pages) { page in
                                Button {
                                    shouldIgnoreResume = false
                                    selectedPage = page
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(L10n.pageTitle(page: page.page, part: page.part))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                                .multilineTextAlignment(.leading)
                                            Text(BiliFormatting.duration(page.duration))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedPage == page {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color("AccentColor"))
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(selectedPage == page ? Color("AccentColor").opacity(0.14) : Color(.secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if viewModel.isLoading {
                    ProgressView(L10n.videoDetailLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .coordinateSpace(name: "videoDetailScroll")
        .background {
            BiliBackground {
                Color.clear
            }
        }
        .navigationTitle(L10n.videoDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
            if selectedPage == nil {
                selectedPage = preferredInitialPage
            }
        }
        .refreshable {
            await viewModel.reload()
        }
        .navigationDestination(for: VideoSummary.self) { video in
            VideoDetailView(
                viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video)
            )
        }
        .navigationDestination(for: UserReference.self) { reference in
            UserProfileView(apiClient: viewModel.apiClient, reference: reference)
        }
        .sheet(isPresented: $isPresentingFavoritePicker) {
            FavoritePickerSheet(
                folders: viewModel.favoriteFolders,
                isLoading: viewModel.isLoadingFavoriteFolders,
                onSelect: { folder in
                    Task { await viewModel.addToFavorites(folder: folder) }
                },
                onLoad: {
                    Task { await viewModel.loadFavoriteFoldersIfNeeded(force: true) }
                }
            )
        }
    }

    private func messageCard(text: String, tint: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.08))
            )
    }

    private var currentTitle: String {
        viewModel.detail?.title ?? viewModel.seedVideo.title
    }

    private var currentPlayableVideo: VideoSummary {
        viewModel.currentPlayableVideo(page: selectedPage)
    }

    private var preferredInitialPage: VideoDetailPage? {
        if let remoteCID = viewModel.remoteResumeCID,
           let remotePage = viewModel.detail?.pages.first(where: { $0.cid == remoteCID }) {
            return remotePage
        }

        return viewModel.detail?.pages.first
    }

    private var currentCommentOID: Int? {
        viewModel.detail?.aid ?? viewModel.seedVideo.aid
    }

    private var playerReloadKey: String {
        let bvid = viewModel.detail?.bvid ?? viewModel.seedVideo.bvid
        let cid = selectedPage?.cid ?? viewModel.detail?.pages.first?.cid ?? viewModel.seedVideo.cid ?? 0
        return "\(bvid)-\(cid)-\(playerResetSeed)"
    }

    private var effectiveInitialSeekSeconds: TimeInterval? {
        if shouldIgnoreResume {
            return nil
        }

        let remoteProgress = selectedPage?.cid == viewModel.remoteResumeCID ? viewModel.remoteResumeSeconds : nil
        return remoteProgress
    }

    private var playerPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.hasRemoteResume && !shouldDockPlayer {
                HStack(spacing: 10) {
                    if let remoteResumeSeconds = viewModel.remoteResumeSeconds,
                       selectedPage?.cid == viewModel.remoteResumeCID {
                        BiliMetricPill(
                            text: L10n.videoRemoteResume(BiliFormatting.duration(Int(remoteResumeSeconds.rounded()))),
                            systemImage: "icloud.and.arrow.down"
                        )
                    }
                }
                .padding(.horizontal, 4)
            }

            if currentPlayableVideo.cid != nil {
                NativePlayerView(
                    displayMode: .embedded,
                    apiClient: viewModel.apiClient,
                    video: currentPlayableVideo,
                    selectedPage: selectedPage,
                    initialSeekSeconds: effectiveInitialSeekSeconds
                )
                .id(playerReloadKey)
            } else {
                ProgressView(L10n.nativePlayerResolving)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .padding(.vertical, 16)
                    .biliListCardStyle()
            }
        }
        .background(playerPositionTracker)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(shouldDockPlayer ? Color(.systemBackground).opacity(0.96) : .clear)
                .shadow(color: .black.opacity(shouldDockPlayer ? 0.08 : 0), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(shouldDockPlayer ? 0.54 : 1, anchor: .topTrailing)
        .offset(
            x: shouldDockPlayer ? 108 : 0,
            y: shouldDockPlayer ? dockedPlayerOffset : 0
        )
        .allowsHitTesting(!shouldDockPlayer)
        .zIndex(shouldDockPlayer ? 10 : 0)
    }

    private var headerCard: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncPosterImage(
                urlString: viewModel.detail?.coverURL ?? viewModel.seedVideo.coverURL,
                width: nil,
                height: 220
            )
            .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                BiliMetricPill(text: L10n.nativeReady, systemImage: "play.tv.fill", tint: .white)
                Text(currentTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .biliHeroCardStyle(cornerRadius: 12, tint: .blue)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: L10n.videoDetailOverviewTitle,
                subtitle: L10n.videoDetailOverviewSubtitle
            )

            LazyVGrid(columns: overviewColumns, spacing: 12) {
                overviewMetricCard(
                    title: L10n.videoDetailDurationTitle,
                    value: BiliFormatting.duration(currentPlayableVideo.duration),
                    systemImage: "clock.fill",
                    tint: .blue
                )
                overviewMetricCard(
                    title: L10n.videoDetailPublishedTitle,
                    value: BiliFormatting.relativeDate(viewModel.detail?.publishDate ?? viewModel.seedVideo.publishDate),
                    systemImage: "calendar",
                    tint: .orange
                )
                overviewMetricCard(
                    title: L10n.videoDetailWatchingTitle,
                    value: remoteWatchingText,
                    systemImage: "play.circle.fill",
                    tint: .teal
                )
                overviewMetricCard(
                    title: L10n.videoPages,
                    value: currentPageOverviewText,
                    systemImage: "list.number",
                    tint: .pink
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.videoDetailDescriptionTitle)
                    .font(.subheadline.weight(.semibold))

                Text(descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(needsDescriptionExpansion && !isDescriptionExpanded ? 4 : nil)
                    .fixedSize(horizontal: false, vertical: true)

                if needsDescriptionExpansion {
                    Button(isDescriptionExpanded ? L10n.videoDetailCollapseDescription : L10n.videoDetailExpandDescription) {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            isDescriptionExpanded.toggle()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
                }
            }
            .padding(16)
            .biliListCardStyle(cornerRadius: 24, tint: .blue)
        }
        .padding(18)
        .biliListCardStyle()
    }

    private var creatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: viewModel.detail?.authorName ?? viewModel.seedVideo.authorName,
                subtitle: L10n.detailAuthorSubtitle
            )

            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.uid(viewModel.detail?.authorID ?? viewModel.seedVideo.authorID ?? 0))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(
                        BiliFormatting.relativeDate(
                            viewModel.detail?.publishDate ?? viewModel.seedVideo.publishDate
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if let creatorReference {
                    NavigationLink(value: creatorReference) {
                        BiliSymbolOrb(systemImage: "person.crop.circle", tint: .blue, size: 38, lightweight: true)
                    }
                    .buttonStyle(.plain)
                }

                if let currentPage = selectedPage {
                    BiliMetricPill(
                        text: L10n.pageTitle(page: currentPage.page, part: currentPage.part),
                        systemImage: "list.number"
                    )
                }
            }

            HStack(spacing: 10) {
                BiliMetricPill(
                    text: BiliFormatting.compactCount(viewModel.detail?.viewCount ?? viewModel.seedVideo.viewCount),
                    systemImage: "play.fill"
                )
                BiliMetricPill(
                    text: BiliFormatting.compactCount(viewModel.detail?.danmakuCount ?? viewModel.seedVideo.danmakuCount),
                    systemImage: "text.bubble.fill"
                )
                BiliMetricPill(
                    text: BiliFormatting.compactCount(viewModel.displayedLikeCount),
                    systemImage: "hand.thumbsup.fill",
                    tint: .orange
                )
            }
        }
        .padding(18)
        .biliListCardStyle()
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.actionPanelTitle, subtitle: actionPanelSubtitle)

            if !viewModel.hasSession {
                Text(L10n.videoInteractionLoginHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: actionColumns, spacing: 12) {
                Button {
                    Task { await viewModel.toggleLike() }
                } label: {
                    interactionTile(
                        title: viewModel.isLiked ? L10n.videoUnlikeAction : L10n.videoLikeAction,
                        value: BiliFormatting.compactCount(viewModel.displayedLikeCount),
                        systemImage: viewModel.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
                        tint: .pink,
                        isActive: viewModel.isLiked,
                        isLoading: viewModel.isSubmittingLike
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasSession || viewModel.isSubmittingLike)

                Menu {
                    if coinMenuOptions.isEmpty {
                        Button(L10n.videoCoinLimitReached) {}
                            .disabled(true)
                    } else {
                        ForEach(coinMenuOptions) { option in
                            Button(option.title) {
                                Task {
                                    await viewModel.coinVideo(amount: option.amount, alsoLike: option.alsoLike)
                                }
                            }
                        }
                    }
                } label: {
                    interactionTile(
                        title: L10n.videoCoinAction,
                        value: BiliFormatting.compactCount(viewModel.displayedCoinCount),
                        systemImage: "centsign.circle.fill",
                        tint: .orange,
                        isActive: viewModel.userCoinCount > 0,
                        isLoading: viewModel.isSubmittingCoin
                    )
                }
                .disabled(!viewModel.hasSession || viewModel.isSubmittingCoin)

                Button {
                    if viewModel.isFavorited {
                        Task { await viewModel.removeFromFavorites() }
                    } else {
                        isPresentingFavoritePicker = true
                        Task { await viewModel.loadFavoriteFoldersIfNeeded() }
                    }
                } label: {
                    interactionTile(
                        title: viewModel.isFavorited ? L10n.videoFavoriteRemoveAction : L10n.addFavorite,
                        value: BiliFormatting.compactCount(viewModel.displayedFavoriteCount),
                        systemImage: viewModel.isFavorited ? "star.fill" : "star",
                        tint: .blue,
                        isActive: viewModel.isFavorited,
                        isLoading: viewModel.isSubmittingFavorite
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasSession || viewModel.isSubmittingFavorite)

                Button {
                    shouldIgnoreResume = true
                    playerResetSeed += 1
                } label: {
                    interactionTile(
                        title: L10n.playFromBeginning,
                        value: shouldShowRestartAction ? remoteWatchingText : L10n.videoInteractionRestartSubtitle,
                        systemImage: "gobackward",
                        tint: .teal,
                        isActive: shouldShowRestartAction
                    )
                }
                .buttonStyle(.plain)
                .disabled(currentPlayableVideo.cid == nil)
            }
        }
        .padding(18)
        .biliListCardStyle()
    }

    private var actionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var shouldShowRestartAction: Bool {
        viewModel.hasRemoteResume
    }

    private var shouldDockPlayer: Bool {
        playerPanelMinY < -12 && hasReachedComments
    }

    private var dockedPlayerOffset: CGFloat {
        -playerPanelMinY + 6
    }

    private var creatorReference: UserReference? {
        let mid = viewModel.detail?.authorID ?? viewModel.seedVideo.authorID
        guard let mid, mid > 0 else { return nil }
        return UserReference(
            mid: mid,
            name: viewModel.detail?.authorName ?? viewModel.seedVideo.authorName,
            avatarURL: viewModel.detail?.authorAvatarURL ?? viewModel.seedVideo.authorAvatarURL
        )
    }

    private var actionPanelSubtitle: String {
        viewModel.hasSession ? L10n.actionPanelSubtitle : L10n.videoInteractionLoginSubtitle
    }

    private var coinMenuOptions: [VideoCoinMenuOption] {
        guard viewModel.remainingCoinCount > 0 else { return [] }

        var options: [VideoCoinMenuOption] = []
        for amount in 1...viewModel.remainingCoinCount {
            options.append(
                VideoCoinMenuOption(
                    title: amount == 1 ? L10n.videoCoinOne : L10n.videoCoinTwo,
                    amount: amount,
                    alsoLike: false
                )
            )
            if !viewModel.isLiked {
                options.append(
                    VideoCoinMenuOption(
                        title: L10n.videoCoinAndLike(amount),
                        amount: amount,
                        alsoLike: true
                    )
                )
            }
        }
        return options
    }

    private var commentsSection: some View {
        VideoCommentsSection(
            apiClient: viewModel.apiClient,
            oid: currentCommentOID
        )
        .padding(18)
        .biliListCardStyle()
        .background(commentsThresholdTracker)
    }

    private var descriptionText: String {
        let rawText = viewModel.detail?.description ?? viewModel.seedVideo.subtitle ?? L10n.noDescription
        let normalized = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? L10n.noDescription : normalized
    }

    private var needsDescriptionExpansion: Bool {
        descriptionText.count > 120 || descriptionText.filter(\.isNewline).count >= 2
    }

    private var currentPageOverviewText: String {
        if let currentPage = selectedPage {
            return L10n.pageTitle(page: currentPage.page, part: currentPage.part)
        }

        let pageCount = viewModel.detail?.pages.count ?? 0
        guard pageCount > 0 else { return L10n.videoDetailSinglePart }
        return L10n.videoDetailPageCount(pageCount)
    }

    private var remoteWatchingText: String {
        guard let remoteResumeSeconds = viewModel.remoteResumeSeconds,
              remoteResumeSeconds > 5 else {
            return L10n.videoDetailWatchingEmpty
        }

        if let selectedPage,
           let duration = selectedPage.duration,
           selectedPage.cid == viewModel.remoteResumeCID,
           duration > 0 {
            return "\(BiliFormatting.duration(Int(remoteResumeSeconds.rounded()))) / \(BiliFormatting.duration(duration))"
        }

        return L10n.videoRemoteResume(BiliFormatting.duration(Int(remoteResumeSeconds.rounded())))
    }

    private var overviewColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func overviewMetricCard(title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BiliSymbolOrb(systemImage: systemImage, tint: tint, size: 36, lightweight: true)
                Spacer(minLength: 8)
            }

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .biliListCardStyle(cornerRadius: 24, tint: tint, interactive: true)
    }

    private func interactionTile(
        title: String,
        value: String,
        systemImage: String,
        tint: Color,
        isActive: Bool = false,
        isLoading: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(tint)
                        .frame(width: 36, height: 36)
                } else {
                    BiliSymbolOrb(
                        systemImage: systemImage,
                        tint: tint,
                        size: 36,
                        lightweight: true
                    )
                }
                Spacer(minLength: 8)
            }

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(title)
                .font(.caption)
                .foregroundStyle(isActive ? tint : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .biliListCardStyle(cornerRadius: 24, tint: tint, interactive: true)
    }

    private func section<Content: View>(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: title, subtitle: subtitle)
            content()
        }
        .padding(18)
        .biliListCardStyle()
    }

    private var playerPositionTracker: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("videoDetailScroll")).minY
            Color.clear
                .onAppear {
                    updatePlayerPanelPosition(minY)
                }
                .onChange(of: minY) { newValue in
                    updatePlayerPanelPosition(newValue)
                }
        }
    }

    private var commentsThresholdTracker: some View {
        GeometryReader { proxy in
            let hasReachedThreshold = proxy.frame(in: .named("videoDetailScroll")).minY < 280
            Color.clear
                .onAppear {
                    hasReachedComments = hasReachedThreshold
                }
                .onChange(of: hasReachedThreshold) { newValue in
                    hasReachedComments = newValue
                }
        }
    }

    private func updatePlayerPanelPosition(_ minY: CGFloat) {
        let snapped = (minY / 12).rounded() * 12
        if abs(playerPanelMinY - snapped) >= 12 || abs(snapped) < 1 {
            playerPanelMinY = snapped
        }
    }
}

private struct VideoCoinMenuOption: Identifiable {
    let title: String
    let amount: Int
    let alsoLike: Bool

    var id: String {
        "\(amount)-\(alsoLike)"
    }
}

private struct FavoritePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let folders: [FavoriteFolder]
    let isLoading: Bool
    let onSelect: (FavoriteFolder) -> Void
    let onLoad: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if isLoading && folders.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView(L10n.favoritePickerLoading)
                        Spacer()
                    }
                } else if folders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.favoritePickerEmpty)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button(L10n.favoritePickerLoadAction, action: onLoad)
                            .buttonStyle(.plain)
                            .biliPrimaryActionButton(fillWidth: false)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(folders) { folder in
                        Button {
                            onSelect(folder)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(folder.title)
                                        .foregroundStyle(.primary)
                                    Text(L10n.mediaCount(folder.mediaCount))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.favoritePickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
            }
            .task {
                onLoad()
            }
        }
    }
}
