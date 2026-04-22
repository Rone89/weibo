import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    init(apiClient: BiliAPIClient) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(apiClient: apiClient))
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
                    ProgressView(L10n.historyLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if viewModel.entries.isEmpty {
                    EmptyStateView(
                        title: L10n.historyEmptyTitle,
                        subtitle: L10n.historyEmptySubtitle,
                        systemImage: "clock.arrow.circlepath"
                    )
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.entries) { entry in
                            NavigationLink(value: entry.video) {
                                VStack(alignment: .leading, spacing: 8) {
                                    VideoRow(video: entry.video)
                                    HStack {
                                        if let pageTitle = entry.pageTitle, !pageTitle.isEmpty {
                                            Text(pageTitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if let progress = entry.progress, progress > 0 {
                                            Text(L10n.watchedPrefix(BiliFormatting.duration(progress)))
                                                .font(.caption)
                                                .foregroundStyle(Color("AccentColor"))
                                        }
                                        if let viewedAt = entry.viewedAt {
                                            Text(BiliFormatting.relativeDate(viewedAt))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 6)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle(L10n.historyTitle)
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
}
