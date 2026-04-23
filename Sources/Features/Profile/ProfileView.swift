import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var isPresentingCookieEditor = false
    @State private var isPresentingWebLogin = false

    init(apiClient: BiliAPIClient, sessionStore: SessionStore) {
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(apiClient: apiClient, sessionStore: sessionStore)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topBar

                    if viewModel.hasSession {
                        if viewModel.hasLoadedContent {
                            profileHero
                            sessionInsightSection
                            quickSummary
                            actionGrid
                            favoriteSection
                            loginSyncSection
                            migrationSection
                        } else if !viewModel.isLoading {
                            EmptyStateView(
                                title: L10n.profileLoadTitle,
                                subtitle: L10n.profileLoadSubtitle,
                                systemImage: "person.crop.circle.badge.clock",
                                actionTitle: L10n.profileLoadAction,
                                action: {
                                    Task { await viewModel.reload() }
                                }
                            )
                        }
                    } else {
                        loginGuide
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .biliCardStyle(tint: .red.opacity(0.24))
                    }

                    if viewModel.isLoading {
                        ProgressView(L10n.profileLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
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
            .sheet(isPresented: $isPresentingCookieEditor) {
                CookieEditorSheet(
                    initialCookie: viewModel.rawCookie,
                    onSave: { rawCookie in
                        Task { await viewModel.saveCookie(rawCookie) }
                    },
                    onClear: {
                        viewModel.clearCookie()
                    }
                )
            }
            .sheet(isPresented: $isPresentingWebLogin) {
                WebLoginView(apiClient: viewModel.apiClient) { rawCookie in
                    Task { await viewModel.saveCookie(rawCookie) }
                }
            }
            .task {
                await viewModel.loadIfNeeded()
            }
            .refreshable {
                await viewModel.reload()
            }
            .navigationDestination(for: FavoriteFolder.self) { folder in
                FavoriteFolderDetailView(apiClient: viewModel.apiClient, folder: folder)
            }
            .navigationDestination(for: VideoSummary.self) { video in
                VideoDetailView(viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video))
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.tabProfile)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                Text(L10n.profileHeroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                Button {
                    isPresentingWebLogin = true
                } label: {
                    BiliSymbolOrb(systemImage: "safari", tint: .blue)
                }
                .buttonStyle(.plain)

                Button {
                    isPresentingCookieEditor = true
                } label: {
                    BiliSymbolOrb(systemImage: "key.fill", tint: Color("AccentColor"))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loginSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: L10n.loginSyncTitle, subtitle: L10n.loginSyncSubtitle)

            HStack(spacing: 10) {
                BiliMetricPill(text: L10n.profileSyncStatus, systemImage: "arrow.triangle.2.circlepath")
                BiliMetricPill(text: L10n.justUpdated, systemImage: "checkmark.seal.fill", tint: .orange)
            }

            Button(L10n.syncNow) {
                Task {
                    await viewModel.refreshFromCurrentCookieStorage()
                }
            }
            .buttonStyle(.plain)
            .biliPrimaryActionButton(fillWidth: false)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .biliCardStyle(tint: .blue.opacity(0.24))
    }

    private var profileHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                AsyncPosterImage(
                    urlString: viewModel.profile?.avatarURL,
                    width: 84,
                    height: 84
                )
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.profile?.name ?? L10n.notLoggedIn)
                        .font(.title3.weight(.bold))
                    Text(L10n.uid(viewModel.profile?.mid ?? 0))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let signature = viewModel.profile?.signature, !signature.isEmpty {
                        Text(signature)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        if let level = viewModel.profile?.level {
                            profileBadge(L10n.level(level))
                        }
                        if (viewModel.profile?.vipStatus ?? 0) > 0 {
                            profileBadge(L10n.vip)
                        }
                        if let coins = viewModel.profile?.coinBalance {
                            profileBadge(L10n.coin(coins))
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                BiliMetricPill(text: L10n.profileSyncStatus, systemImage: "person.badge.shield.checkmark")
                BiliMetricPill(text: L10n.migrationInfoTitle, systemImage: "square.and.arrow.down")
            }
        }
        .padding(20)
        .biliCardStyle(tint: .pink.opacity(0.34), interactive: true)
    }

    private var quickSummary: some View {
        HStack(spacing: 12) {
            summaryCard(title: L10n.following, value: BiliFormatting.compactCount(viewModel.stat?.followingCount))
            summaryCard(title: L10n.followers, value: BiliFormatting.compactCount(viewModel.stat?.followerCount))
            summaryCard(title: L10n.dynamic, value: BiliFormatting.compactCount(viewModel.stat?.dynamicCount))
        }
    }

    private var sessionInsightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.profileSessionTitle, subtitle: L10n.profileSessionSubtitle)

            HStack(spacing: 10) {
                ForEach(cookieStatusItems, id: \.label) { item in
                    Text(item.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.isPresent ? Color("AccentColor") : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((item.isPresent ? Color("AccentColor") : Color.secondary).opacity(0.12), in: Capsule())
                }
            }

            Text(rawCookiePreview)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 10) {
                BiliMetricPill(text: L10n.favoriteFoldersSubtitle(viewModel.favoriteFolders.count), systemImage: "star.fill", tint: .orange)
                BiliMetricPill(text: L10n.profileSyncStatus, systemImage: "checkmark.shield")
            }
        }
        .padding(18)
        .biliCardStyle(tint: .blue.opacity(0.18))
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.commonActions, subtitle: L10n.commonActionsSubtitle)

            LazyVGrid(columns: actionColumns, spacing: 12) {
                NavigationLink {
                    HistoryView(apiClient: viewModel.apiClient)
                } label: {
                    BiliQuickActionTile(
                        title: L10n.historyTitle,
                        subtitle: L10n.profileHistorySubtitle,
                        systemImage: "clock.arrow.circlepath",
                        tint: Color("AccentColor")
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    WatchLaterView(apiClient: viewModel.apiClient)
                } label: {
                    BiliQuickActionTile(
                        title: L10n.watchLaterTitle,
                        subtitle: L10n.profileWatchLaterSubtitle,
                        systemImage: "bookmark.fill",
                        tint: .orange
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isPresentingWebLogin = true
                } label: {
                    BiliQuickActionTile(
                        title: L10n.webLoginTitle,
                        subtitle: L10n.profileWebLoginSubtitle,
                        systemImage: "safari.fill",
                        tint: .blue
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isPresentingCookieEditor = true
                } label: {
                    BiliQuickActionTile(
                        title: L10n.cookieImport,
                        subtitle: L10n.profileCookieSubtitle,
                        systemImage: "key.fill",
                        tint: .pink
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: L10n.favoritesTitle,
                subtitle: viewModel.favoriteFolders.isEmpty ? L10n.favoritesSubtitle : L10n.favoriteFoldersSubtitle(viewModel.favoriteFolders.count)
            )

            if viewModel.favoriteFolders.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    title: "\u{6682}\u{65e0}\u{53ef}\u{89c1}\u{6536}\u{85cf}\u{5939}",
                    subtitle: "\u{5982}\u{679c}\u{8d26}\u{53f7}\u{6ca1}\u{6709}\u{516c}\u{5f00}\u{6536}\u{85cf}\u{5939}\u{ff0c}\u{6216}\u{8005} Cookie \u{6743}\u{9650}\u{4e0d}\u{8db3}\u{ff0c}\u{8fd9}\u{91cc}\u{4f1a}\u{663e}\u{793a}\u{4e3a}\u{7a7a}\u{3002}",
                    systemImage: "star.square.on.square"
                )
            } else {
                if let spotlightFolder = viewModel.favoriteFolders.first {
                    NavigationLink(value: spotlightFolder) {
                        ProfileFavoriteSpotlightCard(folder: spotlightFolder)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.favoriteFolders.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Array(viewModel.favoriteFolders.dropFirst())) { folder in
                                NavigationLink(value: folder) {
                                    ProfileFavoriteFolderCard(folder: folder)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                favoriteLoadMoreSection
            }
        }
    }

    @ViewBuilder
    private var favoriteLoadMoreSection: some View {
        if viewModel.isLoadingMoreFavoriteFolders {
            ProgressView(L10n.loadingMore)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        } else if viewModel.canLoadMoreFavoriteFolders {
            Button(L10n.loadMore) {
                Task { await viewModel.loadMoreFavoriteFolders() }
            }
            .buttonStyle(.plain)
            .biliPrimaryActionButton(fillWidth: false)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var migrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: L10n.migrationInfoTitle, subtitle: L10n.loginGuideSubtitle)

            Text(L10n.migrationInfoText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(L10n.pasteCookieAgain) {
                    isPresentingCookieEditor = true
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton()

                Button(L10n.clearLoginState) {
                    viewModel.clearCookie()
                }
                .buttonStyle(.plain)
                .biliSecondaryActionButton()
            }
        }
        .padding(18)
        .biliCardStyle(tint: .orange.opacity(0.24))
    }

    private var loginGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            BiliSectionHeader(title: L10n.loginGuideTitle, subtitle: L10n.loginGuideSubtitle)

            Text(L10n.loginGuideText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.suggestInclude)
                    .font(.subheadline.weight(.semibold))
                Text("SESSDATA\u{3001}bili_jct\u{3001}DedeUserID")
                    .font(.callout.monospaced())
                    .foregroundStyle(Color("AccentColor"))
            }

            HStack(spacing: 10) {
                Button(L10n.webLoginTitle) {
                    isPresentingWebLogin = true
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton()

                Button("\u{7c98}\u{8d34} Cookie") {
                    isPresentingCookieEditor = true
                }
                .buttonStyle(.plain)
                .biliSecondaryActionButton()
            }
        }
        .padding(20)
        .biliCardStyle(tint: .pink.opacity(0.32), interactive: true)
    }

    private var actionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var cookieStatusItems: [(label: String, isPresent: Bool)] {
        [
            (L10n.profileCookieField("SESSDATA", isPresent: hasCookieField("SESSDATA")), hasCookieField("SESSDATA")),
            (L10n.profileCookieField("bili_jct", isPresent: hasCookieField("bili_jct")), hasCookieField("bili_jct")),
            (L10n.profileCookieField("DedeUserID", isPresent: hasCookieField("DedeUserID")), hasCookieField("DedeUserID"))
        ]
    }

    private var rawCookiePreview: String {
        let trimmed = viewModel.rawCookie.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return L10n.profileCookieEmptyPreview }

        if trimmed.count <= 120 {
            return trimmed
        }

        return String(trimmed.prefix(120)) + "..."
    }

    private func hasCookieField(_ name: String) -> Bool {
        viewModel.rawCookie
            .split(separator: ";")
            .contains { fragment in
                String(fragment)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .hasPrefix("\(name)=")
            }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .biliCardStyle(tint: .white, interactive: true, shadowOpacity: 0.05)
    }

    private func profileBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.7), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            )
    }
}

private struct ProfileFavoriteFolderCard: View {
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

private struct ProfileFavoriteSpotlightCard: View {
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
                Text(L10n.profileFavoritesSpotlightTitle)
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

private struct CookieEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var rawCookie: String
    let onSave: (String) -> Void
    let onClear: () -> Void

    init(initialCookie: String, onSave: @escaping (String) -> Void, onClear: @escaping () -> Void) {
        _rawCookie = State(initialValue: initialCookie)
        self.onSave = onSave
        self.onClear = onClear
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.cookieEditorHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $rawCookie)
                    .font(.callout.monospaced())
                    .frame(minHeight: 260)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                Spacer()
            }
            .padding(16)
            .navigationTitle(L10n.cookieEditorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.save) {
                        onSave(rawCookie)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(L10n.clearCurrentLogin) {
                        onClear()
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}
