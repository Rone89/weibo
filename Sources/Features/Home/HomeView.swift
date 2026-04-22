import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    private let apiClient: BiliAPIClient
    private let onTapSearch: () -> Void

    init(apiClient: BiliAPIClient, onTapSearch: @escaping () -> Void) {
        self.apiClient = apiClient
        self.onTapSearch = onTapSearch
        _viewModel = StateObject(wrappedValue: HomeViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroBanner
                    searchEntry

                    Picker(L10n.feedPicker, selection: $viewModel.selectedFeed) {
                        ForEach(HomeViewModel.FeedMode.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if viewModel.isLoading && currentVideos.isEmpty {
                        ProgressView(L10n.homeLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 30)
                    } else if currentVideos.isEmpty {
                        EmptyStateView(
                            title: L10n.homeEmptyTitle,
                            subtitle: L10n.homeEmptySubtitle,
                            systemImage: "play.slash"
                        )
                    } else {
                        BiliSectionHeader(
                            title: viewModel.selectedFeed.title,
                            subtitle: L10n.contentSubtitle(currentVideos.count)
                        )
                        LazyVStack(spacing: 14) {
                            ForEach(currentVideos) { video in
                                NavigationLink(value: video) {
                                    VideoRow(video: video)
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
            .background {
                BiliBackground {
                    Color.clear
                }
            }
            .navigationTitle(L10n.appTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadIfNeeded()
            }
            .refreshable {
                await viewModel.reload()
            }
            .navigationDestination(for: VideoSummary.self) { video in
                VideoDetailView(
                    viewModel: VideoDetailViewModel(apiClient: apiClient, seedVideo: video)
                )
            }
        }
    }

    private var currentVideos: [VideoSummary] {
        switch viewModel.selectedFeed {
        case .recommended:
            return viewModel.recommendedVideos
        case .hot:
            return viewModel.hotVideos
        }
    }

    private var searchEntry: some View {
        Button(action: onTapSearch) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color("AccentColor"))
                Text(viewModel.searchPlaceholder.isEmpty ? L10n.searchPlaceholderDefault : viewModel.searchPlaceholder)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .biliCardStyle()
        }
        .buttonStyle(.plain)
    }

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.appTitle)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    Text(L10n.homeHeroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Text(L10n.homeHeroBadge)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.8), in: Capsule())
            }

            HStack(spacing: 10) {
                BiliMetricPill(text: "\(viewModel.recommendedVideos.count) \u{6761}\u{63a8}\u{8350}", systemImage: "play.square.stack")
                BiliMetricPill(text: "\(viewModel.hotVideos.count) \u{6761}\u{70ed}\u{95e8}", systemImage: "flame.fill", tint: .orange)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.92, blue: 0.95),
                    Color(red: 0.99, green: 0.96, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 12)
    }
}
