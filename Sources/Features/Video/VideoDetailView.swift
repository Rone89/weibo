import SwiftUI

struct VideoDetailView: View {
    @StateObject var viewModel: VideoDetailViewModel
    @State private var selectedPage: VideoDetailPage?
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
                infoSection

                if let errorMessage = viewModel.errorMessage {
                    messageCard(text: errorMessage, tint: .red)
                }

                if let actionMessage = viewModel.actionMessage {
                    messageCard(text: actionMessage, tint: Color("AccentColor"))
                }

                actionPanel
                commentsSection

                if let detail = viewModel.detail, !detail.pages.isEmpty {
                    section(title: L10n.videoPages, subtitle: L10n.pageSubtitle) {
                        VStack(spacing: 10) {
                            ForEach(detail.pages) { page in
                                Button {
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
        return "\(bvid)-\(cid)"
    }

    private var effectiveInitialSeekSeconds: TimeInterval? {
        selectedPage?.cid == viewModel.remoteResumeCID ? viewModel.remoteResumeSeconds : nil
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

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(currentTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                if let creatorReference {
                    NavigationLink(value: creatorReference) {
                        HStack(spacing: 10) {
                            AsyncPosterImage(
                                urlString: viewModel.detail?.authorAvatarURL ?? viewModel.seedVideo.authorAvatarURL,
                                width: 44,
                                height: 44
                            )
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.detail?.authorName ?? viewModel.seedVideo.authorName)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(L10n.detailAuthorSubtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 10) {
                        AsyncPosterImage(
                            urlString: viewModel.detail?.authorAvatarURL ?? viewModel.seedVideo.authorAvatarURL,
                            width: 44,
                            height: 44
                        )
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.detail?.authorName ?? viewModel.seedVideo.authorName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(L10n.detailAuthorSubtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(14)
            .biliListCardStyle(cornerRadius: 22, tint: .blue)

            HStack(spacing: 10) {
                BiliMetricPill(
                    text: BiliFormatting.compactCount(viewModel.detail?.viewCount ?? viewModel.seedVideo.viewCount),
                    systemImage: "play.fill"
                )
                BiliMetricPill(
                    text: BiliFormatting.compactCount(viewModel.displayedReplyCount),
                    systemImage: "text.bubble.fill",
                    tint: .blue
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
            BiliSectionHeader(title: L10n.actionPanelTitle)

            if !viewModel.hasSession {
                Text(L10n.videoInteractionLoginHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.toggleLike() }
                } label: {
                    compactInteractionButton(
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
                    compactInteractionButton(
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
                    compactInteractionButton(
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
            }
        }
        .padding(18)
        .biliListCardStyle()
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

    private func compactInteractionButton(
        title: String,
        value: String,
        systemImage: String,
        tint: Color,
        isActive: Bool = false,
        isLoading: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(tint)
                        .frame(width: 30, height: 30)
                } else {
                    BiliSymbolOrb(
                        systemImage: systemImage,
                        tint: tint,
                        size: 30,
                        lightweight: true
                    )
                }

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(isActive ? tint : .secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 0.9)
        )
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
