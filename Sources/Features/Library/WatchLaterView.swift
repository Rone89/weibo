import SwiftUI

struct WatchLaterView: View {
    @StateObject private var viewModel: WatchLaterViewModel
    @ObservedObject private var playbackProgressStore = PlaybackProgressStore.shared
    @State private var isPresentingClearConfirmation = false

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

                if let actionMessage = viewModel.actionMessage {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(Color("AccentColor"))
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
                                    if resumeRecord(for: entry) != nil {
                                        NavigationLink(value: entry.video) {
                                            Text(L10n.continuePlayback)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color("AccentColor"))
                                        }
                                        .buttonStyle(.plain)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.entries.isEmpty)
            }
        }
        .task {
            await viewModel.reload()
        }
        .refreshable {
            await viewModel.reload()
        }
        .navigationDestination(for: VideoSummary.self) { video in
            VideoDetailView(viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video))
        }
        .alert(L10n.watchLaterClearConfirmTitle, isPresented: $isPresentingClearConfirmation) {
            Button(L10n.clearAll, role: .destructive) {
                Task { await viewModel.clearAll() }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.watchLaterClearConfirmMessage)
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
            .buttonStyle(.plain)
            .biliPrimaryActionButton(fillWidth: false)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func resumeRecord(for entry: WatchLaterEntry) -> PlaybackProgressRecord? {
        playbackProgressStore.progress(for: entry.video, page: nil)
    }
}
