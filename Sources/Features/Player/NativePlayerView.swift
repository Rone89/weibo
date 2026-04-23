import AVKit
import MediaPlayer
import SwiftUI
import UIKit

struct NativePlayerView: View {
    enum DisplayMode {
        case standalone
        case embedded
    }

    @StateObject private var viewModel: NativePlayerViewModel
    let displayMode: DisplayMode
    @State private var scrubPosition: Double = 0
    @State private var isScrubbing = false
    @State private var isPresentingFullscreen = false

    init(
        displayMode: DisplayMode = .standalone,
        apiClient: BiliAPIClient,
        video: VideoSummary,
        selectedPage: VideoDetailPage?,
        initialSeekSeconds: TimeInterval? = nil
    ) {
        self.displayMode = displayMode
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
            if viewModel.isLoading {
                ProgressView(L10n.nativePlayerResolving)
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .task {
            await viewModel.load()
            scrubPosition = viewModel.currentPlaybackSeconds
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
        InteractivePlayerSurface(
            viewModel: viewModel,
            isFullscreen: false,
            onToggleFullscreen: {
                isPresentingFullscreen = true
            }
        )
        .frame(height: 260)
    }

    private var playerControlCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            playerHeader
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
                subtitle: L10n.nativeReady
            )

            if let source = viewModel.source, let note = source.note, source.mode != .webFallback {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
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
}

private struct NativePlayerFullscreenView: View {
    @ObservedObject var viewModel: NativePlayerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                InteractivePlayerSurface(
                    viewModel: viewModel,
                    isFullscreen: true,
                    onToggleFullscreen: {
                        isPresented = false
                    }
                )
                .aspectRatio(16 / 9, contentMode: .fit)
                Spacer(minLength: 0)
            }
        }
        .statusBarHidden(true)
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
                VideoPlayer(player: viewModel.player)
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
            .simultaneousGesture(dragGesture(in: proxy.size))
            .onTapGesture {
                toggleControls()
            }
        }
        .modifier(PlayerSurfaceStyle(isFullscreen: isFullscreen))
        .onAppear {
            scheduleAutoHideIfNeeded()
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
                        text: "\(L10n.gestureSeekTo) \(clockText(target))"
                    )
                case .brightness:
                    let level = min(max(dragStartBrightness - (value.translation.height / max(size.height, 1)), 0), 1)
                    UIScreen.main.brightness = level
                    gestureHUD = GestureHUD(
                        icon: "sun.max.fill",
                        text: "\(L10n.gestureBrightness) \(Int((level * 100).rounded()))%"
                    )
                case .volume:
                    let level = min(max(dragStartVolume - Float(value.translation.height / max(size.height, 1)), 0), 1)
                    systemVolumeController.setVolume(level)
                    gestureHUD = GestureHUD(
                        icon: "speaker.wave.2.fill",
                        text: "\(L10n.gestureVolume) \(Int((level * 100).rounded()))%"
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
        gestureHUD = GestureHUD(icon: icon, text: text)
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
