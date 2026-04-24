import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @ObservedObject private var preferencesStore: AppPreferencesStore
    @State private var isPresentingCookieEditor = false
    @State private var isPresentingWebLogin = false

    init(apiClient: BiliAPIClient, sessionStore: SessionStore) {
        _preferencesStore = ObservedObject(wrappedValue: apiClient.preferencesStore)
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
                            browsingModeSection
                            quickSummary
                            actionGrid
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
                        browsingModeSection
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
                    BiliSymbolOrb(systemImage: "safari", tint: .blue, lightweight: true)
                }
                .buttonStyle(.plain)

                Button {
                    isPresentingCookieEditor = true
                } label: {
                    BiliSymbolOrb(systemImage: "key.fill", tint: Color("AccentColor"), lightweight: true)
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
        .biliPanelCardStyle(tint: .blue.opacity(0.24))
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
                BiliMetricPill(text: L10n.historyTitle, systemImage: "clock.arrow.circlepath", tint: .orange)
            }
        }
        .padding(20)
        .biliPanelCardStyle(tint: .pink.opacity(0.34), interactive: true)
    }

    private var quickSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.profileFocusTitle, subtitle: L10n.profileFocusSubtitle)

            LazyVGrid(columns: actionColumns, spacing: 12) {
                summaryCard(
                    title: L10n.profileFocusSessionTitle,
                    value: viewModel.hasSession ? L10n.libraryLoggedInBadge : L10n.notLoggedIn,
                    systemImage: "person.badge.key.fill",
                    tint: .blue
                )
                summaryCard(
                    title: L10n.historyTitle,
                    value: viewModel.hasSession ? L10n.libraryReadyBadge : L10n.dynamicSessionHint,
                    systemImage: "clock.arrow.circlepath",
                    tint: .teal
                )
                summaryCard(
                    title: L10n.profileSyncStatus,
                    value: viewModel.hasSession ? L10n.justUpdated : L10n.notLoggedIn,
                    systemImage: "arrow.triangle.2.circlepath",
                    tint: .orange
                )
                summaryCard(
                    title: L10n.profileCookieFieldsTitle,
                    value: L10n.profileCookieFieldCount(cookieFieldReadyCount, total: 3),
                    systemImage: "key.fill",
                    tint: .pink
                )
            }
        }
    }

    private var browsingModeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: L10n.browsingModeTitle, subtitle: L10n.browsingModeSubtitle)

            Toggle(isOn: Binding(
                get: { preferencesStore.isGuestRecommendationEnabled },
                set: { preferencesStore.setGuestRecommendationEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.guestModeTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.guestModeSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: Binding(
                get: { preferencesStore.isIncognitoPlaybackEnabled },
                set: { preferencesStore.setIncognitoPlaybackEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.incognitoPlaybackTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.incognitoPlaybackSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                if preferencesStore.isGuestRecommendationEnabled {
                    BiliMetricPill(text: L10n.guestModeTitle, systemImage: "person.crop.circle.badge.questionmark", tint: .blue)
                }
                if preferencesStore.isIncognitoPlaybackEnabled {
                    BiliMetricPill(text: L10n.incognitoPlaybackTitle, systemImage: "eye.slash.fill", tint: .pink)
                }
            }
        }
        .padding(18)
        .biliListCardStyle(tint: .blue)
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
                BiliMetricPill(text: L10n.historyTitle, systemImage: "clock.arrow.circlepath", tint: .orange)
                BiliMetricPill(text: L10n.profileSyncStatus, systemImage: "checkmark.shield")
            }
        }
        .padding(18)
        .biliPanelCardStyle(tint: .blue.opacity(0.18))
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

                Button {
                    Task { await viewModel.refreshFromCurrentCookieStorage() }
                } label: {
                    BiliQuickActionTile(
                        title: L10n.syncNow,
                        subtitle: L10n.loginSyncSubtitle,
                        systemImage: "arrow.triangle.2.circlepath",
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
        .biliPanelCardStyle(tint: .orange.opacity(0.24))
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
        .biliPanelCardStyle(tint: .pink.opacity(0.32), interactive: true)
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

    private var cookieFieldReadyCount: Int {
        cookieStatusItems.filter(\.isPresent).count
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

    private func summaryCard(title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BiliSymbolOrb(systemImage: systemImage, tint: tint, size: 36, lightweight: true)
                Spacer(minLength: 8)
            }

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .biliListCardStyle(tint: tint, interactive: true)
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
