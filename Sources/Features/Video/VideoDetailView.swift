import SwiftUI

struct VideoDetailView: View {
    @StateObject var viewModel: VideoDetailViewModel
    @ObservedObject private var playbackProgressStore = PlaybackProgressStore.shared
    @State private var selectedPage: VideoDetailPage?
    @State private var isPresentingFavoritePicker = false

    init(viewModel: VideoDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                playerPanel
                headerCard

                if let errorMessage = viewModel.errorMessage {
                    messageCard(text: errorMessage, tint: .red)
                }

                if let actionMessage = viewModel.actionMessage {
                    messageCard(text: actionMessage, tint: Color("AccentColor"))
                }

                creatorCard
                actionPanel

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

                if !viewModel.relatedVideos.isEmpty {
                    section(title: L10n.relatedVideos, subtitle: L10n.relatedSubtitle) {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.relatedVideos) { video in
                                NavigationLink(value: video) {
                                    VideoRow(video: video)
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
                selectedPage = viewModel.detail?.pages.first
            }
        }
        .refreshable {
            await viewModel.reload()
        }
        .sheet(isPresented: $isPresentingFavoritePicker) {
            FavoritePickerSheet(
                folders: viewModel.favoriteFolders,
                isLoading: viewModel.isLoadingFavoriteFolders,
                onSelect: { folder in
                    Task { await viewModel.addToFavorite(folder: folder) }
                },
                onLoad: {
                    Task { await viewModel.prepareFavoriteFolders() }
                }
            )
        }
        .navigationDestination(for: VideoSummary.self) { video in
            VideoDetailView(
                viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video)
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

    private var playerReloadKey: String {
        let bvid = viewModel.detail?.bvid ?? viewModel.seedVideo.bvid
        let cid = selectedPage?.cid ?? viewModel.detail?.pages.first?.cid ?? viewModel.seedVideo.cid ?? 0
        return "\(bvid)-\(cid)"
    }

    private var currentResumeRecord: PlaybackProgressRecord? {
        if selectedPage != nil {
            return playbackProgressStore.progress(for: currentPlayableVideo, page: selectedPage)
        }

        return playbackProgressStore.progress(for: currentPlayableVideo, page: selectedPage) ??
            playbackProgressStore.bestProgress(
                bvid: viewModel.detail?.bvid ?? viewModel.seedVideo.bvid,
                pages: viewModel.detail?.pages ?? []
            )
    }

    private var playerPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let record = currentResumeRecord {
                HStack(spacing: 10) {
                    BiliMetricPill(
                        text: L10n.watchedPrefix(BiliFormatting.duration(Int(record.progressSeconds.rounded()))),
                        systemImage: "play.circle.fill"
                    )
                    BiliMetricPill(
                        text: BiliFormatting.relativeDate(record.updatedAt),
                        systemImage: "clock"
                    )
                }
                .padding(.horizontal, 4)
            }

            if currentPlayableVideo.cid != nil {
                NativePlayerView(
                    displayMode: .embedded,
                    apiClient: viewModel.apiClient,
                    video: currentPlayableVideo,
                    selectedPage: selectedPage,
                    initialSeekSeconds: currentResumeRecord?.progressSeconds
                )
                .id(playerReloadKey)
            } else {
                ProgressView(L10n.nativePlayerResolving)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .padding(.vertical, 16)
                    .biliCardStyle()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
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

            Text(viewModel.detail?.description ?? viewModel.seedVideo.subtitle ?? L10n.noDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                BiliMetricPill(text: BiliFormatting.compactCount(viewModel.detail?.viewCount ?? viewModel.seedVideo.viewCount), systemImage: "play.fill")
                BiliMetricPill(text: BiliFormatting.compactCount(viewModel.detail?.danmakuCount ?? viewModel.seedVideo.danmakuCount), systemImage: "text.bubble.fill")
                BiliMetricPill(text: BiliFormatting.compactCount(viewModel.detail?.likeCount ?? viewModel.seedVideo.likeCount), systemImage: "hand.thumbsup.fill", tint: .orange)
            }
        }
        .padding(18)
        .biliCardStyle()
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
                    text: BiliFormatting.compactCount(viewModel.detail?.likeCount ?? viewModel.seedVideo.likeCount),
                    systemImage: "hand.thumbsup.fill",
                    tint: .orange
                )
            }
        }
        .padding(18)
        .biliCardStyle()
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.actionPanelTitle, subtitle: L10n.actionPanelSubtitle)

            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.addToWatchLater() }
                } label: {
                    Label(L10n.addWatchLater, systemImage: "bookmark")
                }
                .buttonStyle(.plain)
                .biliSecondaryActionButton()

                Button {
                    isPresentingFavoritePicker = true
                } label: {
                    Label(L10n.addFavorite, systemImage: "star")
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton()
            }
        }
        .padding(18)
        .biliCardStyle()
    }

    private func section<Content: View>(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: title, subtitle: subtitle)
            content()
        }
        .padding(18)
        .biliCardStyle()
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
