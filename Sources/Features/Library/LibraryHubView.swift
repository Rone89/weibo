import SwiftUI

struct LibraryHubView: View {
    @StateObject private var viewModel: LibraryHubViewModel
    private let onTapSearch: () -> Void
    private let onTapProfile: () -> Void

    init(
        apiClient: BiliAPIClient,
        sessionStore: SessionStore,
        onTapSearch: @escaping () -> Void,
        onTapProfile: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: LibraryHubViewModel(apiClient: apiClient, sessionStore: sessionStore)
        )
        self.onTapSearch = onTapSearch
        self.onTapProfile = onTapProfile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .biliCardStyle(tint: .red.opacity(0.2))
                    }

                    if viewModel.hasSession {
                        overviewSection
                        quickActionsSection
                        favoritesSection
                        migrationSection
                    } else {
                        loginPrompt
                    }

                    if viewModel.isLoading {
                        ProgressView(L10n.profileLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background {
                BiliBackground {
                    Color.clear
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadIfNeeded()
            }
            .onAppear {
                Task {
                    await viewModel.loadIfNeeded()
                }
            }
            .refreshable {
                await viewModel.reload()
            }
            .navigationDestination(for: FavoriteFolder.self) { folder in
                FavoriteFolderDetailView(apiClient: viewModel.apiClient, folder: folder)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tabLibrary)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text(L10n.libraryHeroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                HStack(spacing: 10) {
                    Button(action: onTapSearch) {
                        BiliSymbolOrb(systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.plain)

                    Button(action: onTapProfile) {
                        BiliSymbolOrb(systemImage: "person.crop.circle")
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                BiliMetricPill(text: L10n.historyTitle, systemImage: "clock.arrow.circlepath")
                BiliMetricPill(text: L10n.watchLaterTitle, systemImage: "bookmark")
                BiliMetricPill(text: L10n.favoriteFoldersSubtitle(viewModel.favoriteFolders.count), systemImage: "star.fill", tint: .orange)
            }
        }
        .padding(20)
        .biliCardStyle(tint: Color("AccentColor").opacity(0.35), interactive: true)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.commonActions, subtitle: L10n.libraryActionsSubtitle)

            LazyVGrid(columns: quickActionColumns, spacing: 12) {
                NavigationLink {
                    HistoryView(apiClient: viewModel.apiClient)
                } label: {
                    BiliQuickActionTile(
                        title: L10n.historyTitle,
                        subtitle: L10n.libraryHistorySubtitle,
                        systemImage: "clock.arrow.circlepath",
                        tint: Color("AccentColor"),
                        badge: L10n.libraryNativeBadge
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    WatchLaterView(apiClient: viewModel.apiClient)
                } label: {
                    BiliQuickActionTile(
                        title: L10n.watchLaterTitle,
                        subtitle: L10n.libraryWatchLaterSubtitle,
                        systemImage: "bookmark.fill",
                        tint: .orange,
                        badge: L10n.libraryReadyBadge
                    )
                }
                .buttonStyle(.plain)

                Button(action: onTapSearch) {
                    BiliQuickActionTile(
                        title: L10n.tabSearch,
                        subtitle: L10n.librarySearchSubtitle,
                        systemImage: "magnifyingglass",
                        tint: .blue,
                        badge: L10n.searchAction
                    )
                }
                .buttonStyle(.plain)

                Button(action: onTapProfile) {
                    BiliQuickActionTile(
                        title: L10n.tabProfile,
                        subtitle: L10n.libraryProfileSubtitle,
                        systemImage: "person.crop.circle.fill",
                        tint: .pink,
                        badge: viewModel.hasSession ? L10n.libraryLoggedInBadge : nil
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.libraryOverviewTitle, subtitle: L10n.libraryOverviewSubtitle)

            HStack(spacing: 12) {
                overviewCard(
                    title: L10n.librarySessionCardTitle,
                    value: viewModel.hasSession ? L10n.libraryLoggedInBadge : L10n.notLoggedIn
                )
                overviewCard(
                    title: L10n.favoritesTitle,
                    value: "\(viewModel.favoriteFolders.count)"
                )
                overviewCard(
                    title: L10n.migrationInfoTitle,
                    value: L10n.libraryReadyBadge
                )
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: L10n.favoritesTitle,
                subtitle: viewModel.favoriteFolders.isEmpty ? L10n.libraryFavoritesEmptySubtitle : L10n.favoriteFoldersSubtitle(viewModel.favoriteFolders.count)
            )

            if viewModel.favoriteFolders.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    title: L10n.favoritePickerEmpty,
                    subtitle: L10n.favoritesSubtitle,
                    systemImage: "star.square.on.square"
                )
            } else {
                if let spotlightFolder = viewModel.favoriteFolders.first {
                    NavigationLink(value: spotlightFolder) {
                        LibraryFavoriteSpotlightCard(folder: spotlightFolder)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.favoriteFolders.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Array(viewModel.favoriteFolders.dropFirst())) { folder in
                                NavigationLink(value: folder) {
                                    LibraryFavoriteFolderCard(folder: folder)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var migrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: L10n.migrationInfoTitle, subtitle: L10n.libraryMigrationSubtitle)

            Text(L10n.migrationInfoText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                BiliMetricPill(text: L10n.loginSyncTitle, systemImage: "checkmark.seal.fill")
                BiliMetricPill(text: L10n.nativeReady, systemImage: "sparkles.tv", tint: .orange)
            }
        }
        .padding(18)
        .biliCardStyle(tint: Color("AccentColor").opacity(0.28))
    }

    private var loginPrompt: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.libraryLoginTitle, subtitle: L10n.libraryLoginSubtitle)

            Text(L10n.loginGuideText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(L10n.libraryLoginAction, action: onTapProfile)
                    .buttonStyle(.plain)
                    .biliPrimaryActionButton(fillWidth: false)

                Button(L10n.tabSearch, action: onTapSearch)
                    .buttonStyle(.plain)
                    .biliSecondaryActionButton(fillWidth: false)
            }
        }
        .padding(18)
        .biliCardStyle(tint: .pink.opacity(0.3), interactive: true)
    }

    private var quickActionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func overviewCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .biliCardStyle(tint: .white, interactive: true, shadowOpacity: 0.04)
    }
}

private struct LibraryFavoriteFolderCard: View {
    let folder: FavoriteFolder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncPosterImage(urlString: folder.coverURL, width: 220, height: 132)
                .frame(width: 220)

            VStack(alignment: .leading, spacing: 6) {
                Text(folder.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(L10n.mediaCount(folder.mediaCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let intro = folder.intro, !intro.isEmpty {
                    Text(intro)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 236, alignment: .leading)
        .padding(12)
        .biliCardStyle(tint: .orange.opacity(0.24), interactive: true)
    }
}

private struct LibraryFavoriteSpotlightCard: View {
    let folder: FavoriteFolder

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncPosterImage(urlString: folder.coverURL, width: nil, height: 210)
                .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.librarySpotlightTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))

                Text(folder.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(folder.intro?.isEmpty == false ? folder.intro! : L10n.mediaCount(folder.mediaCount))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .biliCardStyle(cornerRadius: 28, tint: .orange.opacity(0.28), interactive: true)
    }
}
