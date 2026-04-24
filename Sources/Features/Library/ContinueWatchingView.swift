import SwiftUI

struct ContinueWatchingView: View {
    @ObservedObject private var playbackProgressStore = PlaybackProgressStore.shared
    @State private var isPresentingClearAllConfirmation = false
    @State private var pendingClearRecord: PlaybackProgressRecord?

    private let apiClient: BiliAPIClient

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if records.isEmpty {
                    EmptyStateView(
                        title: L10n.continueWatchingEmptyTitle,
                        subtitle: L10n.continueWatchingEmptySubtitle,
                        systemImage: "play.circle"
                    )
                } else {
                    summaryCard

                    LazyVStack(spacing: 14) {
                        ForEach(records) { record in
                            VStack(alignment: .leading, spacing: 10) {
                                NavigationLink(value: record.videoSummary) {
                                    VideoRow(video: record.videoSummary)
                                }
                                .buttonStyle(.plain)

                                footer(for: record)
                            }
                        }
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
        .navigationTitle(L10n.continueWatchingTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingClearAllConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(records.isEmpty)
            }
        }
        .navigationDestination(for: VideoSummary.self) { video in
            VideoDetailView(
                viewModel: VideoDetailViewModel(apiClient: apiClient, seedVideo: video)
            )
        }
        .alert(L10n.continueWatchingClearAllConfirmTitle, isPresented: $isPresentingClearAllConfirmation) {
            Button(L10n.clearAll, role: .destructive) {
                playbackProgressStore.clearAllProgress()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.continueWatchingClearAllConfirmMessage)
        }
        .alert(
            L10n.continueWatchingClearConfirmTitle,
            isPresented: Binding(
                get: { pendingClearRecord != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingClearRecord = nil
                    }
                }
            )
        ) {
            Button(L10n.continueWatchingClearAction, role: .destructive) {
                if let pendingClearRecord {
                    playbackProgressStore.clearProgress(pendingClearRecord)
                }
                pendingClearRecord = nil
            }
            Button(L10n.cancel, role: .cancel) {
                pendingClearRecord = nil
            }
        } message: {
            Text(L10n.continueWatchingClearConfirmMessage)
        }
    }

    private var records: [PlaybackProgressRecord] {
        playbackProgressStore.recentRecords
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(
                title: L10n.continueWatchingTitle,
                subtitle: L10n.continueWatchingManageSubtitle
            )

            HStack(spacing: 10) {
                BiliMetricPill(
                    text: L10n.itemCount(records.count),
                    systemImage: "play.circle.fill"
                )

                if let firstRecord = records.first {
                    BiliMetricPill(
                        text: BiliFormatting.relativeDate(firstRecord.updatedAt),
                        systemImage: "clock.fill"
                    )
                }

                BiliMetricPill(
                    text: L10n.libraryNativeBadge,
                    systemImage: "sparkles.tv",
                    tint: .orange
                )
            }
        }
        .padding(18)
        .biliListCardStyle(tint: Color("AccentColor"), interactive: true)
    }

    private func footer(for record: PlaybackProgressRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let partTitle = record.partTitle, !partTitle.isEmpty {
                    Text(partTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(BiliFormatting.relativeDate(record.updatedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(record.progressDetailText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color("AccentColor"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    NavigationLink(value: record.videoSummary) {
                        Text(L10n.continuePlayback)
                    }
                    .buttonStyle(.plain)
                    .biliPrimaryActionButton(fillWidth: false)

                    Button(L10n.playFromBeginning) {
                        playbackProgressStore.clearProgress(record)
                    }
                    .buttonStyle(.plain)
                    .biliSecondaryActionButton(fillWidth: false)

                    Button(L10n.continueWatchingClearAction) {
                        pendingClearRecord = record
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 6)
    }
}
