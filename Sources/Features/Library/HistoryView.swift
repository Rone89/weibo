import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var isPresentingClearConfirmation = false
    @State private var pendingDeleteEntry: HistoryEntry?

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

                if let actionMessage = viewModel.actionMessage {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(Color("AccentColor"))
                }

                if viewModel.isLoading && viewModel.entries.isEmpty {
                    ProgressView(L10n.historyLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if viewModel.entries.isEmpty {
                    EmptyStateView(
                        title: L10n.historyEmptyTitle,
                        subtitle: L10n.historyEmptySubtitle,
                        systemImage: "clock.arrow.circlepath",
                        actionTitle: L10n.historyLoadAction,
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
                                    Button(L10n.delete) {
                                        pendingDeleteEntry = entry
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
        .navigationTitle(L10n.historyTitle)
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
        .alert(L10n.historyClearConfirmTitle, isPresented: $isPresentingClearConfirmation) {
            Button(L10n.clearAll, role: .destructive) {
                Task { await viewModel.clearAll() }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.historyClearConfirmMessage)
        }
        .alert(
            L10n.historyDeleteConfirmTitle,
            isPresented: Binding(
                get: { pendingDeleteEntry != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeleteEntry = nil
                    }
                }
            )
        ) {
            Button(L10n.delete, role: .destructive) {
                if let entry = pendingDeleteEntry {
                    Task { await viewModel.remove(entry) }
                }
                pendingDeleteEntry = nil
            }
            Button(L10n.cancel, role: .cancel) {
                pendingDeleteEntry = nil
            }
        } message: {
            Text(L10n.historyDeleteConfirmMessage)
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
