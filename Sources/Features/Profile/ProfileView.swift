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
                VStack(alignment: .leading, spacing: 18) {
                    if viewModel.hasSession {
                        if viewModel.hasLoadedContent {
                            profileHeader
                            quickSummary
                            actionGrid
                            favoriteSection
                            loginSyncSection
                            cookieActionSection
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
                    }

                    if viewModel.isLoading {
                        ProgressView(L10n.profileLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle(L10n.tabProfile)
            .navigationBarTitleDisplayMode(.large)
            .background {
                BiliBackground {
                    Color.clear
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingCookieEditor = true
                    } label: {
                        Image(systemName: "key")
                    }
                }
            }
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
                WebLoginView { rawCookie in
                    Task { await viewModel.saveCookie(rawCookie) }
                }
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
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentColor"))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .biliCardStyle()
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                AsyncPosterImage(
                    urlString: viewModel.profile?.avatarURL,
                    width: 72,
                    height: 72
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
                Spacer()
            }

            HStack(spacing: 10) {
                BiliMetricPill(text: L10n.profileSyncStatus, systemImage: "person.badge.shield.checkmark")
                BiliMetricPill(text: L10n.migrationInfoTitle, systemImage: "square.and.arrow.down")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.78, blue: 0.83),
                            Color(red: 0.98, green: 0.92, blue: 0.73)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var quickSummary: some View {
        HStack(spacing: 12) {
            summaryCard(title: L10n.following, value: BiliFormatting.compactCount(viewModel.stat?.followingCount))
            summaryCard(title: L10n.followers, value: BiliFormatting.compactCount(viewModel.stat?.followerCount))
            summaryCard(title: L10n.dynamic, value: BiliFormatting.compactCount(viewModel.stat?.dynamicCount))
        }
        .padding(18)
        .biliCardStyle()
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: L10n.commonActions, subtitle: L10n.commonActionsSubtitle)

            HStack(spacing: 12) {
                NavigationLink {
                    HistoryView(apiClient: viewModel.apiClient)
                } label: {
                    actionCard(title: L10n.historyTitle, systemImage: "clock.arrow.circlepath")
                }

                NavigationLink {
                    WatchLaterView(apiClient: viewModel.apiClient)
                } label: {
                    actionCard(title: L10n.watchLaterTitle, systemImage: "bookmark")
                }
            }

            HStack(spacing: 12) {
                Button {
                    isPresentingWebLogin = true
                } label: {
                    actionCard(title: L10n.webLoginTitle, systemImage: "safari")
                }
                .buttonStyle(.plain)

                Button {
                    isPresentingCookieEditor = true
                } label: {
                    actionCard(title: L10n.cookieImport, systemImage: "key")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .biliCardStyle()
    }

    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: L10n.favoritesTitle, subtitle: L10n.favoritesSubtitle)

            if viewModel.favoriteFolders.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    title: "\u{6682}\u{65e0}\u{53ef}\u{89c1}\u{6536}\u{85cf}\u{5939}",
                    subtitle: "\u{5982}\u{679c}\u{8d26}\u{53f7}\u{6ca1}\u{6709}\u{516c}\u{5f00}\u{6536}\u{85cf}\u{5939}\u{ff0c}\u{6216}\u{8005} Cookie \u{6743}\u{9650}\u{4e0d}\u{8db3}\u{ff0c}\u{8fd9}\u{91cc}\u{4f1a}\u{663e}\u{793a}\u{4e3a}\u{7a7a}\u{3002}",
                    systemImage: "star.square.on.square"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.favoriteFolders) { folder in
                        NavigationLink(value: folder) {
                            HStack(spacing: 12) {
                                AsyncPosterImage(urlString: folder.coverURL, width: 110, height: 70)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(folder.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
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
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .biliCardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .biliCardStyle()
    }

    private var cookieActionSection: some View {
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
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))

                Button(L10n.clearLoginState) {
                    viewModel.clearCookie()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .biliCardStyle()
    }

    private var loginGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))

                Button("\u{7c98}\u{8d34} Cookie") {
                    isPresentingCookieEditor = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .biliCardStyle()
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
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color("AccentColor").opacity(0.12), lineWidth: 1)
        )
    }

    private func actionCard(title: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color("AccentColor").opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color("AccentColor"))
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }

    private func profileBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.7), in: Capsule())
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
