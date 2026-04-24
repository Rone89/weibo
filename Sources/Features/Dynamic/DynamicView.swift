import SwiftUI

struct DynamicView: View {
    @StateObject private var viewModel: DynamicViewModel
    private let onTapProfile: () -> Void

    init(apiClient: BiliAPIClient, sessionStore: SessionStore, onTapProfile: @escaping () -> Void) {
        _viewModel = StateObject(
            wrappedValue: DynamicViewModel(apiClient: apiClient, sessionStore: sessionStore)
        )
        self.onTapProfile = onTapProfile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerPanel

                    if viewModel.hasSession {
                        filterBar
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

                    if !viewModel.hasSession {
                        loginPrompt
                    } else if viewModel.isLoading && viewModel.items.isEmpty {
                        ProgressView(L10n.dynamicLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else if viewModel.items.isEmpty {
                        EmptyStateView(
                            title: L10n.dynamicEmptyTitle,
                            subtitle: L10n.dynamicEmptySubtitle,
                            systemImage: "bubble.left.and.bubble.right",
                            actionTitle: L10n.dynamicReloadAction,
                            action: {
                                Task { await viewModel.reload() }
                            }
                        )
                    } else {
                        feedSection
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
                await viewModel.loadIfNeeded()
            }
            .refreshable {
                await viewModel.reload()
            }
            .navigationDestination(for: VideoSummary.self) { video in
                VideoDetailView(
                    viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video)
                )
            }
            .navigationDestination(for: DynamicFeedItem.self) { item in
                DynamicDetailView(
                    viewModel: DynamicDetailViewModel(apiClient: viewModel.apiClient, seedItem: item)
                )
            }
            .navigationDestination(for: UserReference.self) { reference in
                UserProfileView(apiClient: viewModel.apiClient, reference: reference)
            }
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tabDynamic)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text(L10n.dynamicHeroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button(action: onTapProfile) {
                    compactToolbarButton(systemImage: "person.crop.circle.fill", tint: Color("AccentColor"))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                BiliMetricPill(text: L10n.dynamicFeedAll, systemImage: "square.stack.3d.up.fill")
                BiliMetricPill(text: L10n.dynamicFeedVideo, systemImage: "play.rectangle.fill", tint: .orange)
                BiliMetricPill(text: L10n.dynamicSessionHint, systemImage: "person.badge.key", tint: .blue)
            }
        }
        .padding(20)
        .biliPanelCardStyle(tint: .pink.opacity(0.32), interactive: true)
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(DynamicViewModel.FeedType.allCases) { feed in
                Button {
                    Task {
                        await viewModel.selectFeed(feed)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: feed == .all ? "square.stack.3d.up" : "play.rectangle")
                        Text(feed.title)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(viewModel.selectedFeed == feed ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedFeed == feed ? Color("AccentColor").opacity(0.96) : Color(.secondarySystemBackground).opacity(0.96))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(viewModel.selectedFeed == feed ? 0.0 : 0.05), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 8)

            Button {
                Task { await viewModel.reload() }
            } label: {
                compactToolbarButton(systemImage: "arrow.clockwise", tint: Color("AccentColor"))
            }
            .buttonStyle(.plain)
        }
    }

    private var loginPrompt: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.dynamicLoginTitle, subtitle: L10n.dynamicLoginSubtitle)

            Text(L10n.dynamicLoginBody)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(L10n.dynamicLoginAction, action: onTapProfile)
                .buttonStyle(.plain)
                .biliPrimaryActionButton(fillWidth: false)
        }
        .padding(18)
        .biliPanelCardStyle(tint: .blue.opacity(0.26), interactive: true)
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: viewModel.selectedFeed.title,
                subtitle: L10n.dynamicCountSubtitle(viewModel.items.count)
            )

            LazyVStack(spacing: 14) {
                ForEach(viewModel.items) { item in
                    NavigationLink(value: item) {
                        DynamicFeedCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        triggerLoadMoreIfNeeded(for: item)
                    }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView(L10n.loadingMore)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else if viewModel.canLoadMore {
                Button(L10n.loadMore) {
                    Task { await viewModel.loadMore() }
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton(fillWidth: false)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func triggerLoadMoreIfNeeded(for item: DynamicFeedItem) {
        guard viewModel.canLoadMore else { return }
        let triggerIDs = Set(viewModel.items.suffix(3).map(\.id))
        guard triggerIDs.contains(item.id) else { return }

        Task {
            await viewModel.loadMore()
        }
    }

    private func compactToolbarButton(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(Color(.systemBackground).opacity(0.96))
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 1)
    }
}

struct DynamicFeedCard: View {
    let item: DynamicFeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            authorRow

            if let topic = item.topic, !topic.isEmpty {
                Text("#\(topic)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
            }

            if !item.text.isEmpty {
                Text(item.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !item.images.isEmpty {
                DynamicImageGrid(images: item.images)
            }

            if let video = item.video {
                DynamicEmbeddedVideoCard(video: video)
            }

            if let quoted = item.quoted {
                DynamicQuotedCard(quoted: quoted)
            }

            statRow
        }
        .padding(18)
        .biliListCardStyle(tint: .pink, interactive: true)
    }

    private var authorRow: some View {
        HStack(spacing: 12) {
            authorIdentityContent
            Spacer(minLength: 0)
        }
    }

    private var authorIdentityContent: some View {
        HStack(spacing: 12) {
            AsyncPosterImage(urlString: item.author.avatarURL, width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.author.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let badge = item.author.badgeText, !badge.isEmpty {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color("AccentColor"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AccentColor").opacity(0.12), in: Capsule())
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 6) {
                    if let actionLabel = item.actionLabel, !actionLabel.isEmpty {
                        Text(actionLabel)
                            .lineLimit(1)
                    }
                    if let publishLabel = item.publishLabel, !publishLabel.isEmpty {
                        Text(publishLabel)
                            .lineLimit(1)
                    } else {
                        Text(BiliFormatting.relativeDate(item.publishedAt))
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            DynamicStatPill(
                text: BiliFormatting.compactCount(item.stats.likeCount),
                systemImage: item.stats.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
                tint: item.stats.isLiked ? .pink : Color("AccentColor")
            )
            DynamicStatPill(
                text: BiliFormatting.compactCount(item.stats.commentCount),
                systemImage: "ellipsis.bubble",
                tint: .blue
            )
            DynamicStatPill(
                text: BiliFormatting.compactCount(item.stats.shareCount),
                systemImage: "arrowshape.turn.up.right",
                tint: .orange
            )

            Spacer(minLength: 0)
        }
    }
}

struct DynamicEmbeddedVideoCard: View {
    let video: VideoSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncPosterImage(urlString: video.coverURL, width: 132, height: 84)

            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(BiliFormatting.compactCount(video.viewCount), systemImage: "play.fill")
                    Label(BiliFormatting.duration(video.duration), systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .biliListCardStyle(cornerRadius: 20, tint: .orange, interactive: true)
    }
}

struct DynamicQuotedCard: View {
    let quoted: DynamicFeedQuotedContent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quoted.authorName)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AccentColor"))

            if let topic = quoted.topic, !topic.isEmpty {
                Text("#\(topic)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !quoted.text.isEmpty {
                Text(quoted.text)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(4)
            }

            if !quoted.images.isEmpty {
                DynamicImageGrid(images: Array(quoted.images.prefix(3)))
            }

            if let video = quoted.video {
                DynamicEmbeddedVideoCard(video: video)
            }
        }
        .padding(14)
        .biliListCardStyle(cornerRadius: 22, tint: .blue)
    }
}

struct DynamicImageGrid: View {
    let images: [DynamicFeedImage]

    var body: some View {
        if images.count == 1, let first = images.first {
            AsyncPosterImage(urlString: first.url, width: nil, height: 220)
                .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(images.prefix(4)) { image in
                    AsyncPosterImage(urlString: image.url, width: nil, height: 120)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }
}

struct DynamicStatPill: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
    }
}
