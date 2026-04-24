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
            List {
                header
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                if let errorMessage = viewModel.errorMessage, viewModel.recommendedVideos.isEmpty {
                    messageCard(text: errorMessage)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if viewModel.isLoading && viewModel.recommendedVideos.isEmpty {
                    ProgressView(L10n.homeLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.recommendedVideos) { video in
                        NavigationLink(value: video) {
                            VideoRow(video: video)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .onAppear {
                            triggerLoadMoreIfNeeded(for: video)
                        }
                    }

                    if viewModel.isLoadingMoreRecommended {
                        ProgressView(L10n.loadingMore)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
