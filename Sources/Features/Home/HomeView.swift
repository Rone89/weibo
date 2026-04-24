import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    private let apiClient: BiliAPIClient

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
        _viewModel = StateObject(wrappedValue: HomeViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    header

                    if let errorMessage = viewModel.errorMessage, viewModel.recommendedVideos.isEmpty {
                        messageCard(text: errorMessage)
                    }

                    if viewModel.isLoading && viewModel.recommendedVideos.isEmpty {
                        ProgressView(L10n.homeLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    } else if viewModel.recommendedVideos.isEmpty {
                        EmptyStateView(
                            title: L10n.homeEmptyTitle,
                            subtitle: L10n.homeEmptySubtitle,
                            systemImage: "play.slash",
                            actionTitle: L10n.homeLoadAction,
                            action: {
                                Task { await viewModel.reload() }
                            }
                        )
                    } else {
                        ForEach(viewModel.recommendedVideos) { video in
                            NavigationLink(value: video) {
                                VideoRow(video: video)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                triggerLoadMoreIfNeeded(for: video)
                            }
                        }

                        if viewModel.isLoadingMoreRecommended {
                            ProgressView(L10n.loadingMore)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                        }
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
            .navigationTitle(L10n.feedRecommended)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadIfNeeded()
            }
            .refreshable {
                await viewModel.refreshRecommendedVideos()
            }
            .navigationDestination(for: VideoSummary.self) { video in
                VideoDetailView(
                    viewModel: VideoDetailViewModel(apiClient: apiClient, seedVideo: video)
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            BiliSectionHeader(
                title: L10n.feedRecommended,
                subtitle: L10n.homeRecommendedSubtitle(viewModel.recommendedVideos.count)
            )

            Spacer(minLength: 8)

            if viewModel.isRefreshingRecommended {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func messageCard(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .biliCardStyle(tint: .red.opacity(0.24))
    }

    private func triggerLoadMoreIfNeeded(for video: VideoSummary) {
        guard viewModel.canLoadMoreRecommended else { return }
        let triggerIDs = Set(viewModel.recommendedVideos.suffix(3).map(\.id))
        guard triggerIDs.contains(video.id) else { return }

        Task {
            await viewModel.loadMoreRecommendedVideos()
        }
    }
}
