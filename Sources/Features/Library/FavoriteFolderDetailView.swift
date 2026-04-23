import SwiftUI

struct FavoriteFolderDetailView: View {
    @StateObject private var viewModel: FavoriteFolderDetailViewModel

    init(apiClient: BiliAPIClient, folder: FavoriteFolder) {
        _viewModel = StateObject(wrappedValue: FavoriteFolderDetailViewModel(apiClient: apiClient, folder: folder))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let actionMessage = viewModel.actionMessage {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(Color("AccentColor"))
                }

                header

                if viewModel.isLoading && viewModel.detail == nil {
                    ProgressView(L10n.favoritesLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if let detail = viewModel.detail, detail.medias.isEmpty {
                    EmptyStateView(
                        title: L10n.favoritesEmptyTitle,
                        subtitle: L10n.favoritesEmptySubtitle,
                        systemImage: "star",
                        actionTitle: L10n.favoritesLoadAction,
                        action: {
                            Task { await viewModel.reload() }
                        }
                    )
                } else if let detail = viewModel.detail {
                    LazyVStack(spacing: 14) {
                        ForEach(detail.medias) { media in
                            VStack(alignment: .leading, spacing: 8) {
                                NavigationLink(value: media.video) {
                                    VideoRow(video: media.video)
                                }
                                .buttonStyle(.plain)

                                HStack {
                                    if let favoriteTime = media.favoriteTime {
                                        Text(BiliFormatting.relativeDate(favoriteTime))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(L10n.removeFromFavorite) {
                                        Task { await viewModel.remove(media: media) }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                }
                                .padding(.horizontal, 6)
                            }
                        }
                    }

                    loadMoreSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle(viewModel.folder.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.reload()
        }
        .refreshable {
            await viewModel.reload()
        }
        .navigationDestination(for: VideoSummary.self) { video in
            VideoDetailView(viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.folder.title)
                .font(.title3.weight(.bold))
            Text(L10n.itemCount(viewModel.folder.mediaCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let intro = viewModel.folder.intro, !intro.isEmpty {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var loadMoreSection: some View {
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
