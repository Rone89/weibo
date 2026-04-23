import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit
import WebKit

struct NativePlayerView: View {
    enum DisplayMode {
        case standalone
        case embedded
    }

    private enum PlaybackSurfaceMode: String, CaseIterable, Identifiable {
        case native
        case compatibility

        var id: String { rawValue }

        var title: String {
            switch self {
            case .native:
                return L10n.playerModeNative
            case .compatibility:
                return L10n.playerModeCompatibility
            }
        }

        var systemImage: String {
            switch self {
            case .native:
                return "play.tv.fill"
            case .compatibility:
                return "safari.fill"
            }
        }
    }

    private enum PreferenceKeys {
        static let playbackSurfaceMode = "player.preference.surfaceMode.v1"
    }

    @StateObject private var viewModel: NativePlayerViewModel
    let displayMode: DisplayMode
    @State private var scrubPosition: Double = 0
    @State private var isScrubbing = false
    @State private var isPresentingFullscreen = false
    @State private var isPresentingCompatibilityPlayer = false
    @State private var preferredSurfaceMode: PlaybackSurfaceMode

    init(
        displayMode: DisplayMode = .standalone,
        apiClient: BiliAPIClient,
        video: VideoSummary,
        selectedPage: VideoDetailPage?,
        initialSeekSeconds: TimeInterval? = nil
    ) {
        self.displayMode = displayMode
        _preferredSurfaceMode = State(initialValue: Self.loadPreferredSurfaceMode())
        _viewModel = StateObject(
            wrappedValue: NativePlayerViewModel(
                apiClient: apiClient,
                video: video,
                selectedPage: selectedPage,
                initialSeekSeconds: initialSeekSeconds
            )
        )
    }

    var body: some View {
        Group {
            switch displayMode {
            case .standalone:
                standaloneBody
            case .embedded:
                embeddedBody
            }
        }
        .overlay {
            if viewModel.isLoading && preferredSurfaceMode == .native {
                ProgressView(L10n.nativePlayerResolving)
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .task(id: preferredSurfaceMode) {
            switch preferredSurfaceMode {
            case .native:
                await viewModel.load()
                scrubPosition = viewModel.currentPlaybackSeconds
            case .compatibility:
                viewModel.stop()
                scrubPosition = 0
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.currentPlaybackSeconds) { newValue in
            guard !isScrubbing else { return }
            scrubPosition = newValue
        }
        .onChange(of: viewModel.totalDurationSeconds) { newValue in
            guard !isScrubbing else { return }
            scrubPosition = min(scrubPosition, newValue > 0 ? newValue : scrubPosition)
        }
        .fullScreenCover(isPresented: $isPresentingFullscreen) {
            NativePlayerFullscreenView(
                viewModel: viewModel,
                isPresented: $isPresentingFullscreen
            )
        }
        .sheet(isPresented: $isPresentingCompatibilityPlayer) {
            CompatibilityWebPlayerSheet(url: compatibilityURL)
        }
    }

    private var standaloneBody: some View {
        ScrollView {
            playerContent
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
        }
        .background {
            BiliBackground {
                Color.clear
            }
        }
        .navigationTitle(L10n.nativePlayerTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var embeddedBody: some View {
        playerContent
    }

    private var playerContent: some View {
        VStack(spacing: 18) {
            playerArea
            playerControlCard
        }
    }

    private var playerArea: some View {
        Group {
            switch preferredSurfaceMode {
            case .native:
                InteractivePlayerSurface(
                    viewModel: viewModel,
                    isFullscreen: false,
                    onToggleFullscreen: {
                        isPresentingFullscreen = true
                    }
                )
            case .compatibility:
                compatibilityPreviewCard
            }
        }
        .frame(height: 260)
    }

    private var playerControlCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            playerHeader
            playbackOverviewSection

            if preferredSurfaceMode == .native {
                transportSection

                if !viewModel.qualityOptions.isEmpty {
                    qualitySection
                }

                danmakuSection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let source = viewModel.source, source.mode == .webFallback {
                    unavailablePlaybackNote(source)
                }
            } else {
                compatibilityModeSection
            }
        }
        .padding(18)
        .biliCardStyle()
    }

    private func unavailablePlaybackNote(_ source: NativePlayableSource) -> some View {
        Text(source.note ?? L10n.nativeFallbackNote)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(0.08))
            )
    }

    private var playerHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            BiliSectionHeader(
                title: viewModel.source?.title ?? L10n.nativePlayerTitle,
                subtitle: preferredSurfaceMode == .native ? L10n.nativeReady : L10n.playerCompatibilityModeHint
            )

            if preferredSurfaceMode == .native,
               let source = viewModel.source,
               let note = source.note,
               source.mode != .webFallback {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if preferredSurfaceMode == .compatibility {
                Text(L10n.nativePlayerCompatibilitySubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            BiliGlassGroup(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(PlaybackSurfaceMode.allCases) { mode in
                        modeChip(for: mode)
                    }
                }
            }

            HStack(spacing: 10) {
                if preferredSurfaceMode == .native {
                    BiliMetricPill(
                        text: L10n.qualityCount(viewModel.qualityOptions.count),
                        systemImage: "rectangle.compress.vertical"
                    )
                    BiliMetricPill(
                        text: L10n.danmakuCount(viewModel.danmakuItems.count),
                        systemImage: "text.bubble"
                    )
                    if let source = viewModel.source, source.mode != .webFallback {
                        BiliMetricPill(
                            text: source.mode == .composite ? L10n.qualityStreamDash : L10n.qualityStreamDirect,
                            systemImage: source.mode == .composite ? "waveform.path.ecg.rectangle" : "link"
                        )
                    }
                } else {
                    BiliMetricPill(
                        text: L10n.playerModeCompatibility,
                        systemImage: "safari.fill",
                        tint: .blue
                    )
                    BiliMetricPill(
                        text: L10n.playerModeRemembered,
                        systemImage: "checkmark.circle.fill",
                        tint: .teal
                    )
                }
            }

            Button {
                setPreferredSurfaceMode(.compatibility, userInitiated: true)
            } label: {
                Label(
                    preferredSurfaceMode == .compatibility ? L10n.playerOpenCompatibility : L10n.nativePlayerWebFallback,
                    systemImage: "safari"
                )
            }
            .buttonStyle(.plain)
            .biliSecondaryActionButton(fillWidth: false)
        }
    }

    private var compatibilityPreviewCard: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncPosterImage(urlString: viewModel.video.coverURL, width: nil, height: 260)
                .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, .black.opacity(0.76)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                BiliMetricPill(
                    text: L10n.playerModeCompatibility,
                    systemImage: "safari.fill",
                    tint: .white,
                    foreground: .white
                )

                Text(viewModel.video.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(L10n.playerCompatibilityModeHint)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(2)

                Button {
                    openCompatibilityPlayer()
                } label: {
                    Label(L10n.playerOpenCompatibility, systemImage: "safari.fill")
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton(fillWidth: false)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .biliCardStyle(cornerRadius: 28, tint: .blue.opacity(0.24), interactive: true)
    }

    private var compatibilityModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(
                title: L10n.playerModeTitle,
                subtitle: L10n.playerModeSubtitle
            )

            Text(L10n.playerCompatibilityModeBody)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    openCompatibilityPlayer()
                } label: {
                    Label(L10n.playerOpenCompatibility, systemImage: "safari.fill")
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton(fillWidth: false)

                Button {
                    setPreferredSurfaceMode(.native, userInitiated: true)
                } label: {
                    Label(L10n.playerSwitchToNative, systemImage: "play.tv.fill")
                }
                .buttonStyle(.plain)
                .biliSecondaryActionButton(fillWidth: false)
            }
        }
    }

    private var playbackOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(
                title: L10n.playerOverviewTitle,
                subtitle: playbackOverviewSubtitle
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    BiliMetricPill(text: viewModel.video.authorName, systemImage: "person.fill")

                    if let selectedPage = viewModel.selectedPage {
                        BiliMetricPill(
                            text: L10n.pageTitle(page: selectedPage.page, part: selectedPage.part),
                            systemImage: "list.number"
                        )
                    }

                    BiliMetricPill(
                        text: BiliFormatting.duration(Int(playbackEffectiveDuration.rounded())),
                        systemImage: "clock.fill"
                    )

                    if let initialSeekSeconds = viewModel.initialSeekSeconds, initialSeekSeconds > 5 {
                        BiliMetricPill(
                            text: L10n.watchedPrefix(BiliFormatting.duration(Int(initialSeekSeconds.rounded()))),
                            systemImage: "arrow.clockwise"
                        )
                    }
                }
            }

            if !timelineShortcuts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(timelineShortcuts.enumerated()), id: \.offset) { _, shortcut in
                            Button(shortcut.title) {
                                viewModel.seek(to: shortcut.seconds)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color("AccentColor").opacity(0.12))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.74), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    private var transportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: L10n.playerControlsTitle,
                subtitle: "\(viewModel.currentTimeLabel) / \(viewModel.durationLabel)"
            )

            HStack(spacing: 12) {
                transportButton(
                    title: L10n.jumpBackward10,
                    systemImage: "gobackward.10",
                    action: { viewModel.seek(by: -10) }
                )

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Label(
                        viewModel.isPlaying ? L10n.pausePlayback : L10n.playPlayback,
                        systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill"
                    )
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton()
                .disabled(viewModel.playerItem == nil)

                transportButton(
                    title: L10n.jumpForward15,
                    systemImage: "goforward.15",
                    action: { viewModel.seek(by: 15) }
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Slider(
                    value: Binding(
                        get: { isScrubbing ? scrubPosition : viewModel.currentPlaybackSeconds },
                        set: { scrubPosition = $0 }
                    ),
                    in: 0...sliderUpperBound,
                    onEditingChanged: { editing in
                        if editing {
                            isScrubbing = true
                            scrubPosition = viewModel.currentPlaybackSeconds
                        } else {
                            isScrubbing = false
                            viewModel.seek(to: scrubPosition)
                        }
                    }
                )
                .tint(Color("AccentColor"))
                .disabled(viewModel.playerItem == nil)

                HStack {
                    Text(viewModel.currentTimeLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.durationLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Menu {
                    ForEach(viewModel.availablePlaybackRates, id: \.self) { rate in
                        Button(BiliFormatting.playbackRate(rate)) {
                            viewModel.setPlaybackRate(rate)
                        }
                    }
                } label: {
                    Label("\(L10n.playbackSpeed): \(viewModel.playbackRateLabel)", systemImage: "speedometer")
                }

                BiliMetricPill(
                    text: viewModel.isPlaying ? L10n.playingStatus : L10n.pausedStatus,
                    systemImage: viewModel.isPlaying ? "play.circle.fill" : "pause.circle"
                )

                BiliMetricPill(
                    text: L10n.playerGestureHint,
                    systemImage: "hand.tap"
                )
            }
        }
    }

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(
                title: L10n.qualityTitle,
                subtitle: viewModel.source?.currentQualityLabel
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.qualityOptions) { option in
                        Button {
                            Task {
                                await viewModel.selectQuality(option)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.label)
                                            .font(.subheadline.weight(.bold))
                                        if let detail = option.detail, !detail.isEmpty {
                                            Text(detail)
                                                .font(.caption)
                                                .foregroundStyle(viewModel.selectedQualityID == option.id ? .white.opacity(0.9) : .secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    if viewModel.selectedQualityID == option.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    qualityMetaRow(L10n.qualityMetaResolution, value: option.resolution)
                                    qualityMetaRow(L10n.qualityMetaBitrate, value: option.bitrate)
                                    qualityMetaRow(L10n.qualityMetaCodec, value: option.codecs)
                                    qualityMetaRow(L10n.qualityMetaFrameRate, value: option.frameRate)
                                    qualityMetaRow(L10n.qualityMetaDynamicRange, value: option.dynamicRange)
                                }

                                HStack(spacing: 8) {
                                    qualityBadge(option.streamBadge, isSelected: viewModel.selectedQualityID == option.id)
                                    if let audioDetail = option.audioDetail {
                                        qualityBadge(audioDetail, isSelected: viewModel.selectedQualityID == option.id)
                                    }
                                }
                            }
                            .foregroundStyle(viewModel.selectedQualityID == option.id ? .white : .primary)
                            .frame(width: 250, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(viewModel.selectedQualityID == option.id ? Color("AccentColor") : Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var danmakuSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                BiliSectionHeader(
                    title: L10n.danmakuTitle,
                    subtitle: viewModel.isShowingDanmakuOverlay ? L10n.danmakuTrackStyle : L10n.danmakuOverlayOff
                )
                Spacer()
                Toggle("", isOn: $viewModel.isShowingDanmakuOverlay)
                    .labelsHidden()
                    .onChange(of: viewModel.isShowingDanmakuOverlay) { newValue in
                        viewModel.setDanmakuOverlay(newValue)
                    }
            }

            if viewModel.isLoadingDanmaku {
                ProgressView(L10n.danmakuLoading)
            } else if viewModel.danmakuItems.isEmpty {
                Text(L10n.danmakuEmpty)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        BiliMetricPill(text: L10n.liveDanmaku, systemImage: "waveform")
                        BiliMetricPill(text: L10n.danmakuSampleSubtitle, systemImage: "text.bubble.fill")
                    }

                    ForEach(Array(viewModel.danmakuItems.prefix(12))) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color(biliHex: item.colorHex))
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)
                            Text(BiliFormatting.duration(Int(item.time)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color("AccentColor"))
                            Text(item.text)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private func transportButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .biliSecondaryActionButton()
        .disabled(viewModel.playerItem == nil)
    }

    private func qualityMetaRow(_ title: String, value: String?) -> some View {
        Group {
            if let value, !value.isEmpty {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text(value)
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private func qualityBadge(_ text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? .white.opacity(0.22) : Color("AccentColor").opacity(0.12))
            )
    }

    private var sliderUpperBound: Double {
        max(viewModel.totalDurationSeconds, max(viewModel.currentPlaybackSeconds, 1))
    }

    private var playbackOverviewSubtitle: String {
        if let selectedPage = viewModel.selectedPage {
            return L10n.playerOverviewPageSubtitle(selectedPage.part)
        }
        return L10n.playerOverviewSubtitle
    }

    private var playbackEffectiveDuration: TimeInterval {
        let fallback = TimeInterval(viewModel.selectedPage?.duration ?? viewModel.video.duration ?? 0)
        return max(viewModel.totalDurationSeconds, fallback)
    }

    private var timelineShortcuts: [(title: String, seconds: TimeInterval)] {
        guard playbackEffectiveDuration > 0 else { return [] }

        let duration = playbackEffectiveDuration
        return [
            (L10n.playerRestart, 0),
            (L10n.playerQuarter, duration * 0.25),
            (L10n.playerHalf, duration * 0.5),
            (L10n.playerThreeQuarter, duration * 0.75),
            (L10n.playerAlmostDone, max(duration - 15, duration * 0.9))
        ]
    }

    private var compatibilityURL: URL {
        viewModel.source?.fallbackWebURL ?? URL(string: "https://www.bilibili.com/video/\(viewModel.video.bvid)")!
    }

    private func modeChip(for mode: PlaybackSurfaceMode) -> some View {
        Button {
            setPreferredSurfaceMode(mode, userInitiated: true)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: mode.systemImage)
                Text(mode.title)
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(preferredSurfaceMode == mode ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(preferredSurfaceMode == mode ? Color("AccentColor") : Color(.systemBackground).opacity(0.72))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(preferredSurfaceMode == mode ? 0.0 : 0.05), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func setPreferredSurfaceMode(_ mode: PlaybackSurfaceMode, userInitiated: Bool) {
        if preferredSurfaceMode != mode {
            preferredSurfaceMode = mode
            UserDefaults.standard.set(mode.rawValue, forKey: PreferenceKeys.playbackSurfaceMode)
        }

        if mode == .compatibility && userInitiated {
            openCompatibilityPlayer()
        }
    }

    private func openCompatibilityPlayer() {
        isPresentingCompatibilityPlayer = true
    }

    private static func loadPreferredSurfaceMode(defaults: UserDefaults = .standard) -> PlaybackSurfaceMode {
        guard let rawValue = defaults.string(forKey: PreferenceKeys.playbackSurfaceMode),
              let mode = PlaybackSurfaceMode(rawValue: rawValue) else {
            return .native
        }
        return mode
    }
}

private struct NativePlayerFullscreenView: View {
    @ObservedObject var viewModel: NativePlayerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer(minLength: 0)
                InteractivePlayerSurface(
                    viewModel: viewModel,
                    isFullscreen: true,
                    onToggleFullscreen: {
                        isPresented = false
                    }
                )
                .aspectRatio(16 / 9, contentMode: .fit)

                fullscreenInfoBar
                    .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
        }
        .statusBarHidden(true)
    }

    private var fullscreenInfoBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.video.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            if let note = viewModel.source?.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
            } else {
                Text(L10n.playerGestureHint)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    fullscreenPill(viewModel.video.authorName, systemImage: "person.fill")

                    if let selectedPage = viewModel.selectedPage {
                        fullscreenPill(
                            L10n.pageTitle(page: selectedPage.page, part: selectedPage.part),
                            systemImage: "list.number"
                        )
                    }

                    if let quality = viewModel.source?.currentQualityLabel, !quality.isEmpty {
                        fullscreenPill(quality, systemImage: "sparkles.tv")
                    }

                    fullscreenPill(viewModel.playbackRateLabel, systemImage: "speedometer")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func fullscreenPill(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.12), in: Capsule())
    }
}

private struct InteractivePlayerSurface: View {
    enum DragMode {
        case seek
        case brightness
        case volume
    }

    struct GestureHUD: Equatable {
        let icon: String
        let text: String
        let level: Double?
    }

    @ObservedObject var viewModel: NativePlayerViewModel
    let isFullscreen: Bool
    let onToggleFullscreen: () -> Void

    @State private var areControlsVisible = true
    @State private var gestureHUD: GestureHUD?
    @State private var dragMode: DragMode?
    @State private var dragStartBrightness: CGFloat = UIScreen.main.brightness
    @State private var dragStartVolume: Float = AVAudioSession.sharedInstance().outputVolume
    @State private var dragStartTime: TimeInterval = 0
    @State private var pendingSeekTime: TimeInterval?
    @State private var hideControlsTask: Task<Void, Never>?
    @StateObject private var systemVolumeController = SystemVolumeController()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PlayerCanvasView(player: viewModel.player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

                danmakuOverlay(in: proxy.size)

                doubleTapHotspots

                if areControlsVisible {
                    playerChrome
                        .transition(.opacity)
                }

                if let gestureHUD {
                    gestureHUDView(gestureHUD)
                        .transition(.opacity)
                }

                HiddenSystemVolumeView(controller: systemVolumeController)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
            .background(Color.black)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture(in: proxy.size))
            .onTapGesture {
                toggleControls()
            }
        }
        .modifier(PlayerSurfaceStyle(isFullscreen: isFullscreen))
        .onAppear {
            areControlsVisible = true
            scheduleAutoHideIfNeeded()
        }
        .onChange(of: viewModel.isPlaying) { isPlaying in
            if isPlaying {
                scheduleAutoHideIfNeeded()
            } else {
                hideControlsTask?.cancel()
                withAnimation(.easeInOut(duration: 0.18)) {
                    areControlsVisible = true
                }
            }
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
    }

    private var playerChrome: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.black.opacity(0.72), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)
            .overlay(alignment: .topLeading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let quality = viewModel.source?.currentQualityLabel {
                            playerBadge("\(L10n.currentQuality): \(quality)", systemImage: "sparkles.tv")
                        }
                        if viewModel.isShowingDanmakuOverlay {
                            playerBadge(L10n.danmakuTrackStyle, systemImage: "text.line.first.and.arrowtriangle.forward")
                        }
                    }

                    Spacer()

                    Button(action: onToggleFullscreen) {
                        Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.35), in: Circle())
                    }
                }
                .padding(16)
            }

            Spacer(minLength: 0)

            LinearGradient(
                colors: [.clear, .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: isFullscreen ? 146 : 112)
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    if isFullscreen {
                        Text(L10n.playerGestureHint)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    HStack(spacing: 12) {
                        Button {
                            viewModel.togglePlayback()
                            scheduleAutoHideIfNeeded()
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(.white.opacity(0.14), in: Circle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            progressBar

                            HStack {
                                Text(viewModel.currentTimeLabel)
                                    .font(.caption.monospacedDigit())
                                Spacer()
                                Text(viewModel.durationLabel)
                                    .font(.caption.monospacedDigit())
                            }
                            .foregroundStyle(.white.opacity(0.82))
                        }

                        Menu {
                            ForEach(viewModel.availablePlaybackRates, id: \.self) { rate in
                                Button(BiliFormatting.playbackRate(rate)) {
                                    viewModel.setPlaybackRate(rate)
                                }
                            }
                        } label: {
                            Text(viewModel.playbackRateLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.white.opacity(0.14), in: Capsule())
                        }

                        Button {
                            viewModel.setDanmakuOverlay(!viewModel.isShowingDanmakuOverlay)
                            scheduleAutoHideIfNeeded()
                        } label: {
                            Image(systemName: viewModel.isShowingDanmakuOverlay ? "text.bubble.fill" : "text.bubble")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(.white.opacity(0.14), in: Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            let fraction = progressFraction

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.16))

                Capsule()
                    .fill(Color("AccentColor"))
                    .frame(width: max(10, proxy.size.width * fraction))
            }
        }
        .frame(height: 4)
    }

    private func danmakuOverlay(in size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(viewModel.overlayDanmaku) { overlayItem in
                danmakuBubble(overlayItem, in: size)
            }
        }
        .modifier(PlayerSurfaceStyle(isFullscreen: isFullscreen))
        .allowsHitTesting(false)
    }

    private var doubleTapHotspots: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(!areControlsVisible)
                .onTapGesture(count: 2) {
                    handleDoubleTapSeek(delta: -10, icon: "gobackward.10", text: L10n.jumpBackward10)
                }

            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(!areControlsVisible)
                .onTapGesture(count: 2) {
                    handleDoubleTapSeek(delta: 15, icon: "goforward.15", text: L10n.jumpForward15)
                }
        }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard viewModel.playerItem != nil else { return }

                if dragMode == nil {
                    dragStartBrightness = UIScreen.main.brightness
                    dragStartVolume = systemVolumeController.currentVolume
                    dragStartTime = viewModel.currentPlaybackSeconds
                    pendingSeekTime = nil

                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragMode = .seek
                    } else if value.startLocation.x < size.width / 2 {
                        dragMode = .brightness
                    } else {
                        dragMode = .volume
                    }
                }

                areControlsVisible = true
                hideControlsTask?.cancel()

                switch dragMode {
                case .seek:
                    let basis = max(viewModel.totalDurationSeconds, 60)
                    let delta = TimeInterval(value.translation.width / max(size.width, 1)) * basis
                    let target = min(max(dragStartTime + delta, 0), max(viewModel.totalDurationSeconds, dragStartTime + delta))
                    pendingSeekTime = target
                    gestureHUD = GestureHUD(
                        icon: "arrow.left.and.right.circle.fill",
                        text: "\(L10n.gestureSeekTo) \(clockText(target))",
                        level: target / max(viewModel.totalDurationSeconds, target > 0 ? target : 1)
                    )
                case .brightness:
                    let level = min(max(dragStartBrightness - (value.translation.height / max(size.height, 1)), 0), 1)
                    UIScreen.main.brightness = level
                    gestureHUD = GestureHUD(
                        icon: "sun.max.fill",
                        text: "\(L10n.gestureBrightness) \(Int((level * 100).rounded()))%",
                        level: level
                    )
                case .volume:
                    let level = min(max(dragStartVolume - Float(value.translation.height / max(size.height, 1)), 0), 1)
                    systemVolumeController.setVolume(level)
                    gestureHUD = GestureHUD(
                        icon: "speaker.wave.2.fill",
                        text: "\(L10n.gestureVolume) \(Int((level * 100).rounded()))%",
                        level: Double(level)
                    )
                case nil:
                    break
                }
            }
            .onEnded { _ in
                if dragMode == .seek, let pendingSeekTime {
                    viewModel.seek(to: pendingSeekTime)
                }

                dragMode = nil
                pendingSeekTime = nil
                dismissGestureHUDSoon()
                scheduleAutoHideIfNeeded()
            }
    }

    private func handleDoubleTapSeek(delta: TimeInterval, icon: String, text: String) {
        guard viewModel.playerItem != nil else { return }
        viewModel.seek(by: delta)
        gestureHUD = GestureHUD(
            icon: icon,
            text: text,
            level: viewModel.totalDurationSeconds > 0 ? viewModel.currentPlaybackSeconds / viewModel.totalDurationSeconds : nil
        )
        dismissGestureHUDSoon()
        scheduleAutoHideIfNeeded()
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.18)) {
            areControlsVisible.toggle()
        }
        scheduleAutoHideIfNeeded()
    }

    private func scheduleAutoHideIfNeeded() {
        hideControlsTask?.cancel()

        guard areControlsVisible, viewModel.isPlaying else { return }
        hideControlsTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                areControlsVisible = false
            }
        }
    }

    private func dismissGestureHUDSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(.easeInOut(duration: 0.18)) {
                gestureHUD = nil
            }
        }
    }

    private func gestureHUDView(_ hud: GestureHUD) -> some View {
        VStack(spacing: 10) {
            Image(systemName: hud.icon)
                .font(.title2.weight(.bold))
            Text(hud.text)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
            if let level = hud.level {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.18))
                        Capsule()
                            .fill(.white.opacity(0.92))
                            .frame(width: max(8, proxy.size.width * CGFloat(min(max(level, 0), 1))))
                    }
                }
                .frame(width: 120, height: 4)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func playerBadge(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.38), in: Capsule())
    }

    private func danmakuBubble(_ overlayItem: DanmakuOverlayItem, in size: CGSize) -> some View {
        let laneHeight = max(30, (size.height - 92) / CGFloat(max(viewModel.overlayLaneCount, 1)))
        let startX = size.width + 110
        let endX: CGFloat = -150
        let x = startX - (startX - endX) * CGFloat(overlayItem.progress)
        let y = 36 + laneHeight * CGFloat(overlayItem.laneIndex)

        return Text(overlayItem.item.text)
            .font(.system(size: danmakuFontSize(for: overlayItem.item), weight: .semibold))
            .foregroundStyle(Color(biliHex: overlayItem.item.colorHex))
            .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 2)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.16), in: Capsule())
            .position(x: x, y: y)
    }

    private func danmakuFontSize(for item: DanmakuItem) -> CGFloat {
        let clamped = min(max(item.fontSize, 18), 30)
        return CGFloat(clamped)
    }

    private var progressFraction: CGFloat {
        guard viewModel.totalDurationSeconds > 0 else { return 0 }
        return CGFloat(min(max(viewModel.currentPlaybackSeconds / viewModel.totalDurationSeconds, 0), 1))
    }

    private func clockText(_ seconds: TimeInterval) -> String {
        let safeSeconds = max(0, Int(seconds.rounded()))
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let remainSeconds = safeSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainSeconds)
    }
}

private struct HiddenSystemVolumeView: UIViewRepresentable {
    let controller: SystemVolumeController

    func makeUIView(context: Context) -> MPVolumeView {
        controller.volumeView.showsRouteButton = false
        controller.volumeView.showsVolumeSlider = true
        return controller.volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

private struct PlayerCanvasView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerCanvasUIView {
        let view = PlayerCanvasUIView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerCanvasUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private struct CompatibilityWebPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let url: URL

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(L10n.nativePlayerCompatibilitySubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))

                CompatibleWebPlayer(url: url)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle(L10n.nativePlayerWebFallback)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct CompatibleWebPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = BiliAPIClient.userAgent
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        var request = URLRequest(url: url)
        request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard uiView.url != url else { return }
        var request = URLRequest(url: url)
        request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
        uiView.load(request)
    }
}

private final class PlayerCanvasUIView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            fatalError("Expected AVPlayerLayer backing layer")
        }
        return layer
    }
}

private final class SystemVolumeController: ObservableObject {
    let volumeView = MPVolumeView(frame: .zero)

    var currentVolume: Float {
        AVAudioSession.sharedInstance().outputVolume
    }

    func setVolume(_ value: Float) {
        let clamped = min(max(value, 0), 1)
        guard let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first else { return }
        slider.value = clamped
        slider.sendActions(for: .valueChanged)
        slider.sendActions(for: .touchUpInside)
    }
}

private struct PlayerSurfaceStyle: ViewModifier {
    let isFullscreen: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isFullscreen {
            content
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }
}

private extension Color {
    init(biliHex: String) {
        let hexString = biliHex.replacingOccurrences(of: "#", with: "")
        let hexValue = UInt64(hexString, radix: 16) ?? 0xFFFFFF
        let red = Double((hexValue & 0xFF0000) >> 16) / 255
        let green = Double((hexValue & 0x00FF00) >> 8) / 255
        let blue = Double(hexValue & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
