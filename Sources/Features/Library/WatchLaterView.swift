import SwiftUI

struct WatchLaterView: View {
    @StateObject private var viewModel: WatchLaterViewModel

    init(apiClient: BiliAPIClient) {
        _viewModel = StateObject(wrappedValue: WatchLaterViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if viewModel.isLoading && viewModel.entries.isEmpty {
                    ProgressView(L10n.watchLaterLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if viewModel.entries.isEmpty {
                    EmptyStateView(
                        title: L10n.watchLaterEmptyTitle,
                        subtitle: L10n.watchLaterEmptySubtitle,
                        systemImage: "bookmark",
                        actionTitle: L10n.watchLaterLoadAction,
                        action: {
                            Task { await viewModel.reload() }
                        }
                    )
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.entries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                NavigationLink(value: entry.video) {
                                    VideoRow(video: entry.video)
                                }
                                .buttonStyle(.plain)

                                HStack {
                                    if let progress = entry.progress, progress > 0 {
                                        Text(L10n.watchedPrefix(BiliFormatting.duration(progress)))
                                            .font(.caption)
                                            .foregroundStyle(Color("AccentColor"))
                                    }
                                    Spacer()
                                    Button(L10n.remove) {
                                        Task { await viewModel.remove(entry) }
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
        .navigationTitle(L10n.watchLaterTitle)
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
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentColor"))
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
