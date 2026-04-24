import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel

    init(apiClient: BiliAPIClient, reference: UserReference) {
        _viewModel = StateObject(
            wrappedValue: UserProfileViewModel(apiClient: apiClient, reference: reference)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                if let errorMessage = viewModel.errorMessage {
                    messageCard(text: errorMessage, tint: .red)
                }

                if let actionMessage = viewModel.actionMessage {
                    messageCard(text: actionMessage, tint: Color("AccentColor"))
                }

                relationSection
                recentVideosSection

                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView(L10n.userProfileLoading)
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
        .navigationTitle(viewModel.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.reload()
        }
        .navigationDestination(for: VideoSummary.self) { video in
            VideoDetailView(viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video))
        }
        .navigationDestination(for: UserReference.self) { reference in
            UserProfileView(apiClient: viewModel.apiClient, reference: reference)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                AsyncPosterImage(
                    urlString: viewModel.profile?.avatarURL ?? viewModel.reference.avatarURL,
                    width: 84,
                    height: 84
                )
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(L10n.uid(viewModel.profile?.mid ?? viewModel.reference.mid))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let signature = viewModel.profile?.signature, !signature.isEmpty {
                        Text(signature)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    HStack(spacing: 8) {
                        if let level = viewModel.profile?.level {
                            profileBadge(L10n.level(level), tint: Color("AccentColor"))
                        }
                        if (viewModel.profile?.vipStatus ?? 0) > 0 {
                            profileBadge(L10n.vip, tint: .orange)
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            if !viewModel.isCurrentUser {
                Button {
                    Task { await viewModel.toggleFollow() }
                } label: {
                    Label(
                        viewModel.isFollowing ? L10n.userProfileUnfollowAction : L10n.userProfileFollowAction,
                        systemImage: viewModel.isFollowing ? "person.badge.minus" : "person.badge.plus"
                    )
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton(fillWidth: false)
                .disabled(viewModel.isSubmittingFollow)
            }
        }
        .padding(20)
        .biliPanelCardStyle(tint: .blue.opacity(0.28), interactive: true)
    }

    private var relationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: L10n.userProfileRelationTitle,
                subtitle: L10n.userProfileRelationSubtitle
            )

            LazyVGrid(columns: relationColumns, spacing: 12) {
                NavigationLink {
                    UserRelationListView(
                        apiClient: viewModel.apiClient,
                        kind: .followings,
                        reference: viewModel.profile?.reference ?? viewModel.reference
                    )
                } label: {
                    relationCard(
                        title: L10n.userRelationFollowings,
                        value: BiliFormatting.compactCount(viewModel.relationStat?.followingCount),
                        systemImage: "person.2.fill",
                        tint: .blue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    UserRelationListView(
                        apiClient: viewModel.apiClient,
                        kind: .fans,
                        reference: viewModel.profile?.reference ?? viewModel.reference
                    )
                } label: {
                    relationCard(
                        title: L10n.userRelationFans,
                        value: BiliFormatting.compactCount(viewModel.relationStat?.followerCount ?? viewModel.profile?.followerCount),
                        systemImage: "person.3.fill",
                        tint: .pink
                    )
                }
                .buttonStyle(.plain)

                relationCard(
                    title: L10n.userProfileArchiveCount,
                    value: BiliFormatting.compactCount(viewModel.profile?.archiveCount),
                    systemImage: "play.rectangle.fill",
                    tint: .orange
                )

                relationCard(
                    title: L10n.tabDynamic,
                    value: BiliFormatting.compactCount(viewModel.relationStat?.dynamicCount),
                    systemImage: "bubble.left.and.bubble.right.fill",
                    tint: .teal
                )
            }
        }
        .padding(18)
        .biliListCardStyle()
    }

    @ViewBuilder
    private var recentVideosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: L10n.userProfileRecentVideos,
                subtitle: L10n.contentSubtitle(viewModel.recentVideos.count)
            )

            if viewModel.recentVideos.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    title: L10n.userProfileNoRecentVideosTitle,
                    subtitle: L10n.userProfileNoRecentVideosSubtitle,
                    systemImage: "play.slash"
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.recentVideos) { video in
                        NavigationLink(value: video) {
                            VideoRow(video: video)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .biliListCardStyle()
    }

    private var relationColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func relationCard(title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BiliSymbolOrb(systemImage: systemImage, tint: tint, size: 36, lightweight: true)
                Spacer(minLength: 8)
            }

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .biliListCardStyle(tint: tint, interactive: true)
    }

    private func profileBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
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
}

struct UserRelationListView: View {
    @StateObject private var viewModel: UserRelationListViewModel

    init(apiClient: BiliAPIClient, kind: UserRelationListKind, reference: UserReference) {
        _viewModel = StateObject(
            wrappedValue: UserRelationListViewModel(apiClient: apiClient, kind: kind, reference: reference)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .biliCardStyle(tint: .red.opacity(0.24))
                }

                if let actionMessage = viewModel.actionMessage {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(Color("AccentColor"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color("AccentColor").opacity(0.08))
                        )
                }

                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView(L10n.userRelationLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if viewModel.items.isEmpty {
                    EmptyStateView(
                        title: L10n.userRelationEmptyTitle(viewModel.kind.title),
                        subtitle: L10n.userRelationEmptySubtitle,
                        systemImage: viewModel.kind.systemImage
                    )
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.items) { item in
                            UserRelationRow(
                                item: item,
                                canFollow: viewModel.apiClient.sessionStore.hasCookie && item.mid != viewModel.reference.mid,
                                onToggleFollow: {
                                    Task { await viewModel.toggleFollow(for: item) }
                                }
                            )
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
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background {
            BiliBackground {
                Color.clear
            }
        }
        .navigationTitle("\(viewModel.reference.name)\(viewModel.kind.title)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.reload()
        }
        .navigationDestination(for: UserReference.self) { reference in
            UserProfileView(apiClient: viewModel.apiClient, reference: reference)
        }
    }
}

private struct UserRelationRow: View {
    let item: UserRelationListItem
    let canFollow: Bool
    let onToggleFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: item.reference) {
                HStack(spacing: 12) {
                    AsyncPosterImage(urlString: item.avatarURL, width: 48, height: 48)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(item.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            if item.officialType == 0 {
                                Text(L10n.userProfileOfficialBadge)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.12), in: Capsule())
                            }
                        }

                        if let signature = item.signature, !signature.isEmpty {
                            Text(signature)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            if canFollow {
                Button(action: onToggleFollow) {
                    Text(item.isFollowingByCurrentUser ? L10n.userProfileFollowingBadge : L10n.userProfileFollowAction)
                }
                .buttonStyle(.plain)
                .biliSecondaryActionButton(fillWidth: false)
            }
        }
        .padding(16)
        .biliListCardStyle(tint: .blue, interactive: true)
    }
}
