import AVFoundation
import Foundation

@MainActor
final class NativePlayerViewModel: ObservableObject {
    @Published private(set) var source: NativePlayableSource?
    @Published private(set) var playerItem: AVPlayerItem?
    @Published private(set) var player = AVPlayer()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var danmakuItems: [DanmakuItem] = []
    @Published private(set) var visibleDanmaku: [DanmakuItem] = []
    @Published private(set) var overlayDanmaku: [DanmakuOverlayItem] = []
    @Published private(set) var isLoadingDanmaku = false
    @Published private(set) var selectedQuality: Int?
    @Published private(set) var selectedQualityID: String?
    @Published private(set) var currentPlaybackSeconds: TimeInterval = 0
    @Published private(set) var totalDurationSeconds: TimeInterval = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackRate: Float = 1
    @Published var isShowingDanmakuOverlay = true

    let apiClient: BiliAPIClient
    let video: VideoSummary
    let selectedPage: VideoDetailPage?
    let initialSeekSeconds: TimeInterval?

    private var playbackObserver: Any?
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var playerFailureObserver: NSObjectProtocol?
    private var playerStallObserver: NSObjectProtocol?
    private let danmakuTravelDuration: TimeInterval = 6
    private let danmakuLaneCount = 4
    private let progressStore: PlaybackProgressStore
    private var lastPersistedBucket = -1
    private var qualityHydrationTask: Task<Void, Never>?
    private var danmakuTask: Task<Void, Never>?

    init(
        apiClient: BiliAPIClient,
        video: VideoSummary,
        selectedPage: VideoDetailPage?,
        initialSeekSeconds: TimeInterval? = nil,
        progressStore: PlaybackProgressStore = .shared
    ) {
        self.apiClient = apiClient
        self.video = video
        self.selectedPage = selectedPage
        self.initialSeekSeconds = initialSeekSeconds
        self.progressStore = progressStore
        self.player.automaticallyWaitsToMinimizeStalling = false
        self.player.allowsExternalPlayback = true
    }

    var qualityOptions: [PlaybackQualityOption] {
        source?.qualityOptions ?? []
    }

    var overlayLaneCount: Int {
        danmakuLaneCount
    }

    var availablePlaybackRates: [Float] {
        [0.75, 1.0, 1.25, 1.5, 2.0]
    }

    var currentTimeLabel: String {
        playbackClockText(currentPlaybackSeconds)
    }

    var durationLabel: String {
        playbackClockText(totalDurationSeconds)
    }

    var playbackRateLabel: String {
        BiliFormatting.playbackRate(playbackRate)
    }

    func load() async {
        qualityHydrationTask?.cancel()
        danmakuTask?.cancel()
        isLoading = true
        errorMessage = nil
        totalDurationSeconds = TimeInterval(selectedPage?.duration ?? video.duration ?? 0)

        do {
            let playable = try await resolveBootstrapSource(preferredQuality: selectedQuality)
            source = playable

            if let option = try await resolveInitialQuality(from: playable) {
                selectedQuality = option.qn
                selectedQualityID = option.id
                source = makeSource(from: playable, selectedOption: option)
                restorePlaybackProgressIfNeeded()
            } else {
                selectedQuality = nil
                selectedQualityID = nil
            }

            startObservingPlaybackTime()
            isLoading = false

            danmakuTask = Task { [weak self] in
                guard let self else { return }
                await self.loadDanmakuIfNeeded()
            }

            qualityHydrationTask = Task { [weak self] in
                guard let self else { return }
                await self.hydrateQualityOptions(preferredQuality: self.selectedQuality)
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func togglePlayback() {
        guard playerItem != nil else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
            persistPlaybackProgress(force: true)
        } else {
            activateAudioSession()
            player.playImmediately(atRate: playbackRate)
            isPlaying = true
        }
    }

    func seek(by delta: TimeInterval) {
        seek(to: currentPlaybackSeconds + delta)
    }

    func seek(to seconds: TimeInterval) {
        guard playerItem != nil else { return }

        let upperBound = totalDurationSeconds > 0
            ? totalDurationSeconds
            : max(max(currentPlaybackSeconds, seconds), 0)
        let clamped = min(max(seconds, 0), upperBound)
        let target = CMTime(seconds: clamped, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.currentPlaybackSeconds = clamped
                self.updateVisibleDanmaku(at: clamped)
                self.persistPlaybackProgress(force: true)
            }
        }
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        guard playerItem != nil else { return }
        if isPlaying {
            player.playImmediately(atRate: rate)
        }
    }

    func selectQuality(_ option: PlaybackQualityOption) async {
        guard selectedQualityID != option.id else { return }
        isLoading = true
        errorMessage = nil
        let shouldAutoplay = isPlaying

        do {
            try await applyQuality(option, preserveTime: true, autoplay: shouldAutoplay)
            selectedQuality = option.qn
            selectedQualityID = option.id
            if let current = source {
                source = NativePlayableSource(
                    title: current.title,
                    mode: option.mode == .direct ? .direct : .composite,
                    fallbackWebURL: current.fallbackWebURL,
                    note: note(for: option),
                    qualityOptions: current.qualityOptions,
                    defaultQuality: option,
                    currentQualityLabel: option.label
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func setDanmakuOverlay(_ isEnabled: Bool) {
        isShowingDanmakuOverlay = isEnabled
        updateVisibleDanmaku(at: currentPlaybackSeconds)
    }

    func stop() {
        qualityHydrationTask?.cancel()
        qualityHydrationTask = nil
        danmakuTask?.cancel()
        danmakuTask = nil
        persistPlaybackProgress(force: true)
        player.pause()
        clearPlayerItemObservers()
        if let playbackObserver {
            player.removeTimeObserver(playbackObserver)
            self.playbackObserver = nil
        }
        player.replaceCurrentItem(with: nil)
        playerItem = nil
        currentPlaybackSeconds = 0
        totalDurationSeconds = TimeInterval(selectedPage?.duration ?? video.duration ?? 0)
        isPlaying = false
        selectedQualityID = nil
        lastPersistedBucket = -1
        visibleDanmaku = []
        overlayDanmaku = []
    }

    private func resolveBootstrapSource(preferredQuality: Int?) async throws -> NativePlayableSource {
        guard let cid = selectedPage?.cid ?? video.cid else {
            throw APIError.server("\u{7f3a}\u{5c11} cid\u{ff0c}\u{65e0}\u{6cd5}\u{89e3}\u{6790}\u{64ad}\u{653e}\u{5730}\u{5740}\u{3002}")
        }

        let requestedQn = preferredQuality ?? 80
        guard let webURL = URL(string: "https://www.bilibili.com/video/\(video.bvid)?p=\(selectedPage?.page ?? 1)") else {
            throw APIError.invalidURL
        }

        let directData = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.videoPlayURL,
            query: [
                "avid": video.aid.map(String.init) ?? "",
                "bvid": video.bvid,
                "cid": "\(cid)",
                "qn": "\(requestedQn)",
                "fnval": "0",
                "fnver": "0",
                "fourk": "1",
                "voice_balance": "1",
                "gaia_source": "pre-load",
                "isGaiaAvoided": "true",
                "web_location": "1315873"
            ].filter { !$0.value.isEmpty },
            headers: [
                "Referer": "\(BiliBaseURL.web)/",
                "Origin": BiliBaseURL.web
            ],
            signedByWBI: true
        )

        if let durl = JSONValue.dictionaries(directData["durl"]).first,
           let urlString = JSONValue.string(durl["url"]),
           let url = URL(string: urlString.normalizedBiliURLString) {
            let qn = JSONValue.int(directData["quality"]) ?? requestedQn
            let label = ((directData["accept_description"] as? [String])?.first).flatMap { $0.isEmpty ? nil : $0 } ?? "QN \(qn)"
            let directOption = PlaybackQualityOption(
                qn: qn,
                label: label,
                detail: L10n.playerFastStartBadge,
                mode: .direct,
                resolution: nil,
                bitrate: nil,
                codecs: nil,
                frameRate: nil,
                dynamicRange: nil,
                videoURL: url,
                audioURL: nil
            )

            return NativePlayableSource(
                title: video.title,
                mode: .direct,
                fallbackWebURL: webURL,
                note: L10n.nativeDirectNote,
                qualityOptions: [directOption],
                defaultQuality: directOption,
                currentQualityLabel: directOption.label
            )
        }

        return try await resolvePlayableSource(preferredQuality: preferredQuality)
    }

    private func resolvePlayableSource(preferredQuality: Int?) async throws -> NativePlayableSource {
        guard let cid = selectedPage?.cid ?? video.cid else {
            throw APIError.server("\u{7f3a}\u{5c11} cid\u{ff0c}\u{65e0}\u{6cd5}\u{89e3}\u{6790}\u{64ad}\u{653e}\u{5730}\u{5740}\u{3002}")
        }

        let requestedQn = preferredQuality ?? 80
        guard let webURL = URL(string: "https://www.bilibili.com/video/\(video.bvid)?p=\(selectedPage?.page ?? 1)") else {
            throw APIError.invalidURL
        }
        let playbackHeaders = [
            "Referer": "\(BiliBaseURL.web)/",
            "Origin": BiliBaseURL.web
        ]

        async let dashDataTask = apiClient.requestEnvelopeData(
            path: BiliEndpoint.videoPlayURL,
            query: [
                "avid": video.aid.map(String.init) ?? "",
                "bvid": video.bvid,
                "cid": "\(cid)",
                "qn": "\(requestedQn)",
                "fnval": "4048",
                "fnver": "0",
                "fourk": "1",
                "voice_balance": "1",
                "gaia_source": "pre-load",
                "isGaiaAvoided": "true",
                "web_location": "1315873"
            ].filter { !$0.value.isEmpty },
            headers: playbackHeaders,
            signedByWBI: true
        )

        async let directDataTask = apiClient.requestEnvelopeData(
            path: BiliEndpoint.videoPlayURL,
            query: [
                "avid": video.aid.map(String.init) ?? "",
                "bvid": video.bvid,
                "cid": "\(cid)",
                "qn": "\(requestedQn)",
                "fnval": "0",
                "fnver": "0",
                "fourk": "1",
                "voice_balance": "1",
                "gaia_source": "pre-load",
                "isGaiaAvoided": "true",
                "web_location": "1315873"
            ].filter { !$0.value.isEmpty },
            headers: playbackHeaders,
            signedByWBI: true
        )

        let (dashData, directData) = try await (dashDataTask, directDataTask)

        let qualityOptions = buildQualityOptions(dashData: dashData, directData: directData, preferredQuality: requestedQn)

        if let defaultQuality = chooseDefaultQuality(from: qualityOptions, preferredQuality: requestedQn) {
            return NativePlayableSource(
                title: video.title,
                mode: defaultQuality.mode == .direct ? .direct : .composite,
                fallbackWebURL: webURL,
                note: note(for: defaultQuality),
                qualityOptions: qualityOptions,
                defaultQuality: defaultQuality,
                currentQualityLabel: defaultQuality.label
            )
        }

        if let durl = JSONValue.dictionaries(directData["durl"]).first,
           let urlString = JSONValue.string(durl["url"]),
           let url = URL(string: urlString.normalizedBiliURLString) {
            let fallbackOption = PlaybackQualityOption(
                qn: requestedQn,
                label: "QN \(requestedQn)",
                detail: nil,
                mode: .direct,
                resolution: nil,
                bitrate: nil,
                codecs: nil,
                frameRate: nil,
                dynamicRange: nil,
                videoURL: url,
                audioURL: nil
            )

            return NativePlayableSource(
                title: video.title,
                mode: .direct,
                fallbackWebURL: webURL,
                note: L10n.nativeDirectNote,
                qualityOptions: [fallbackOption],
                defaultQuality: fallbackOption,
                currentQualityLabel: fallbackOption.label
            )
        }

        return NativePlayableSource(
            title: self.video.title,
            mode: .webFallback,
            fallbackWebURL: webURL,
            note: L10n.nativeFallbackNote,
            qualityOptions: [],
            defaultQuality: nil,
            currentQualityLabel: nil
        )
    }

    private func buildQualityOptions(
        dashData: [String: Any],
        directData: [String: Any],
        preferredQuality: Int
    ) -> [PlaybackQualityOption] {
        let acceptedQualities = (dashData["accept_quality"] as? [Int]) ??
            (dashData["accept_quality"] as? [NSNumber])?.map(\.intValue) ??
            []
        let acceptedDescriptions = (dashData["accept_description"] as? [String]) ??
            (directData["accept_description"] as? [String]) ??
            []
        let descriptionMap = Dictionary(uniqueKeysWithValues: zip(acceptedQualities, acceptedDescriptions))

        let dash = JSONValue.dictionary(dashData["dash"])
        let videos = JSONValue.dictionaries(dash?["video"])
        let audios = JSONValue.dictionaries(dash?["audio"])
        let flacAudio = JSONValue.dictionary(JSONValue.dictionary(dash?["flac"])?["audio"])
        let dolbyAudio = JSONValue.dictionaries(JSONValue.dictionary(dash?["dolby"])?["audio"]).first
        let defaultAudioURL = urlFrom(json: audios.first) ?? urlFrom(json: flacAudio) ?? urlFrom(json: dolbyAudio)

        let dashOptions = Dictionary(grouping: videos, by: { JSONValue.int($0["id"]) ?? 0 })
            .compactMap { qn, candidates -> PlaybackQualityOption? in
                let orderedCandidates = candidates.sorted(by: compareDashCandidates)
                guard qn > 0, let candidate = orderedCandidates.first, let videoURL = urlFrom(json: candidate) else {
                    return nil
                }
                let label = descriptionMap[qn] ?? "QN \(qn)"
                let resolution = resolutionText(from: candidate)
                let bitrate = bitrateText(from: candidate)
                let codecs = codecText(from: candidate)
                let frameRate = frameRateText(from: candidate)
                let dynamicRange = dynamicRangeText(from: candidate)
                return PlaybackQualityOption(
                    qn: qn,
                    label: label,
                    detail: detailText(
                        resolution: resolution,
                        bitrate: bitrate,
                        codecs: codecs
                    ),
                    mode: defaultAudioURL == nil ? .direct : .composite,
                    resolution: resolution,
                    bitrate: bitrate,
                    codecs: codecs,
                    frameRate: frameRate,
                    dynamicRange: dynamicRange,
                    videoURL: videoURL,
                    audioURL: defaultAudioURL
                )
            }
            .sorted { lhs, rhs in
                if lhs.qn == preferredQuality { return true }
                if rhs.qn == preferredQuality { return false }
                return lhs.qn > rhs.qn
            }

        var allOptions = dashOptions
        if let durl = JSONValue.dictionaries(directData["durl"]).first,
           let videoURL = urlFrom(json: durl) {
            let qn = JSONValue.int(directData["quality"]) ?? preferredQuality
            let directOption = PlaybackQualityOption(
                qn: qn,
                label: descriptionMap[qn] ?? "QN \(qn)",
                detail: nil,
                mode: .direct,
                resolution: nil,
                bitrate: nil,
                codecs: nil,
                frameRate: nil,
                dynamicRange: nil,
                videoURL: videoURL,
                audioURL: nil
            )

            allOptions.removeAll { $0.mode == .direct && $0.qn == qn }
            allOptions.insert(directOption, at: 0)
        }

        return allOptions
    }

    private func chooseDefaultQuality(from options: [PlaybackQualityOption], preferredQuality: Int) -> PlaybackQualityOption? {
        options.first(where: { $0.mode == .direct && $0.qn == preferredQuality }) ??
            options.first(where: { $0.mode == .direct }) ??
            options.first(where: { $0.qn == preferredQuality }) ??
            options.first
    }

    private func hydrateQualityOptions(preferredQuality: Int?) async {
        do {
            let fullSource = try await resolvePlayableSource(preferredQuality: preferredQuality)
            guard !Task.isCancelled else { return }
            guard fullSource.mode != .webFallback else { return }

            let currentMode: PlaybackQualityOption.StreamMode = source?.mode == .direct ? .direct : .composite
            let resolvedCurrentOption =
                fullSource.qualityOptions.first(where: { $0.id == selectedQualityID }) ??
                fullSource.qualityOptions.first(where: { $0.qn == selectedQuality && $0.mode == currentMode }) ??
                fullSource.qualityOptions.first(where: { $0.qn == selectedQuality }) ??
                fullSource.defaultQuality

            guard let resolvedCurrentOption else { return }

            source = makeSource(from: fullSource, selectedOption: resolvedCurrentOption)
            selectedQuality = resolvedCurrentOption.qn
            selectedQualityID = resolvedCurrentOption.id
        } catch {
            // Keep the fast-start stream when richer metadata hydration fails.
        }
    }

    private func applyQuality(_ option: PlaybackQualityOption, preserveTime: Bool, autoplay: Bool) async throws {
        let previousTime = preserveTime ? player.currentTime() : .zero
        let shouldResume = autoplay || isPlaying || player.rate > 0

        let item = try await makePlayerItem(for: option)
        errorMessage = nil
        player.replaceCurrentItem(with: item)
        playerItem = item
        observePlayerItem(item)
        totalDurationSeconds = TimeInterval(selectedPage?.duration ?? video.duration ?? 0)

        if preserveTime && previousTime.seconds.isFinite && previousTime.seconds > 0 {
            await player.seek(to: previousTime)
            currentPlaybackSeconds = previousTime.seconds
        } else {
            currentPlaybackSeconds = 0
        }

        if shouldResume {
            activateAudioSession()
            player.playImmediately(atRate: playbackRate)
            isPlaying = true
        } else {
            player.pause()
            isPlaying = false
        }
    }

    private func startObservingPlaybackTime() {
        guard playbackObserver == nil else { return }

        playbackObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.35, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.refreshPlaybackState(with: time)
        }
    }

    private func updateVisibleDanmaku(at playbackTime: TimeInterval) {
        guard isShowingDanmakuOverlay else {
            visibleDanmaku = []
            overlayDanmaku = []
            return
        }

        let windowStart = max(0, playbackTime - danmakuTravelDuration)
        let windowEnd = playbackTime + 0.4
        let candidates = danmakuItems
            .filter { $0.time >= windowStart && $0.time <= windowEnd }
            .prefix(12)

        var laneBusyUntil = Array(repeating: -Double.greatestFiniteMagnitude, count: danmakuLaneCount)
        var liveItems: [DanmakuOverlayItem] = []

        for item in candidates {
            let lane = nextDanmakuLane(for: item.time, laneBusyUntil: &laneBusyUntil)
            let progress = min(max((playbackTime - item.time) / danmakuTravelDuration, 0), 1)

            liveItems.append(
                DanmakuOverlayItem(
                    item: item,
                    laneIndex: lane,
                    progress: progress
                )
            )
        }

        overlayDanmaku = liveItems
        visibleDanmaku = liveItems
            .map(\.item)
            .sorted { $0.time > $1.time }
    }

    private func loadDanmakuIfNeeded() async {
        guard danmakuItems.isEmpty else { return }
        guard let cid = selectedPage?.cid ?? video.cid else { return }

        isLoadingDanmaku = true
        defer { isLoadingDanmaku = false }

        do {
            guard let danmakuURL = URL(string: "https://comment.bilibili.com/\(cid).xml") else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: danmakuURL)
            request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
            let (data, response) = try await apiClient.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                throw APIError.invalidResponse
            }

            danmakuItems = DanmakuXMLParser().parse(data: data)
            updateVisibleDanmaku(at: currentPlaybackSeconds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func makeCompositeItem(videoURL: URL, audioURL: URL?) async throws -> AVPlayerItem? {
        guard let audioURL else {
            let asset = makeMediaAsset(url: videoURL)
            guard try await asset.load(.isPlayable) else {
                throw APIError.server(L10n.nativeStreamUnavailable)
            }
            return AVPlayerItem(asset: asset)
        }

        let videoAsset = makeMediaAsset(url: videoURL)
        let audioAsset = makeMediaAsset(url: audioURL)

        async let videoTracks = try videoAsset.loadTracks(withMediaType: .video)
        async let audioTracks = try audioAsset.loadTracks(withMediaType: .audio)
        async let videoDuration = try videoAsset.load(.duration)
        async let audioDuration = try audioAsset.load(.duration)

        guard let videoTrack = try await videoTracks.first,
              let audioTrack = try await audioTracks.first else {
            return nil
        }

        let duration = CMTimeMinimum(try await videoDuration, try await audioDuration)
        let composition = AVMutableComposition()
        let timeRange = CMTimeRange(start: .zero, duration: duration)

        if let composedVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try composedVideo.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            let transform = try await videoTrack.load(.preferredTransform)
            composedVideo.preferredTransform = transform
        }

        if let composedAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try composedAudio.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }

        return AVPlayerItem(asset: composition)
    }

    private func urlFrom(json: [String: Any]?) -> URL? {
        let primaryCandidates = [
            JSONValue.string(json?["base_url"]),
            JSONValue.string(json?["baseUrl"]),
            JSONValue.string(json?["url"])
        ].compactMap { $0 }
        let candidates = primaryCandidates +
            JSONValue.stringArray(json?["backup_url"]) +
            JSONValue.stringArray(json?["backupUrl"])

        return candidates
            .map(\.normalizedBiliURLString)
            .compactMap(URL.init(string:))
            .first
    }

    private func refreshPlaybackState(with time: CMTime) {
        let seconds = max(0, time.seconds.isFinite ? time.seconds : 0)
        currentPlaybackSeconds = seconds

        let itemDuration = player.currentItem?.duration.seconds ?? 0
        if itemDuration.isFinite, itemDuration > 0 {
            totalDurationSeconds = itemDuration
        }

        isPlaying = player.timeControlStatus == .playing || player.rate > 0
        updateVisibleDanmaku(at: seconds)
        persistPlaybackProgressIfNeeded()
    }

    private func playbackClockText(_ seconds: TimeInterval) -> String {
        let safeSeconds = max(0, Int(seconds.rounded()))
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let remainSeconds = safeSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainSeconds)
    }

    private func restorePlaybackProgressIfNeeded() {
        let restoredSeconds = initialSeekSeconds ?? progressStore.progress(for: video, page: selectedPage)?.progressSeconds
        guard let restoredSeconds, restoredSeconds > 5 else { return }

        let effectiveDuration = max(totalDurationSeconds, TimeInterval(selectedPage?.duration ?? video.duration ?? 0))
        if effectiveDuration > 0, restoredSeconds >= effectiveDuration - 8 {
            return
        }

        seek(to: restoredSeconds)
    }

    private func persistPlaybackProgressIfNeeded() {
        persistPlaybackProgress(force: false)
    }

    private func persistPlaybackProgress(force: Bool) {
        guard playerItem != nil else { return }
        let bucket = Int(currentPlaybackSeconds / 5)
        guard force || bucket != lastPersistedBucket else { return }
        lastPersistedBucket = bucket

        progressStore.saveProgress(
            video: video,
            page: selectedPage,
            progressSeconds: currentPlaybackSeconds,
            durationSeconds: totalDurationSeconds,
            title: source?.title ?? video.title
        )
    }

    private func note(for option: PlaybackQualityOption) -> String {
        switch option.mode {
        case .composite:
            return L10n.nativeDashNote
        case .direct:
            return option.codecs == nil ? L10n.nativeDirectNote : L10n.nativeVideoOnlyNote
        }
    }

    private func compareDashCandidates(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        let lhsCodecPriority = codecPriority(from: lhs)
        let rhsCodecPriority = codecPriority(from: rhs)
        if lhsCodecPriority != rhsCodecPriority {
            return lhsCodecPriority > rhsCodecPriority
        }

        let lhsBandwidth = JSONValue.int(lhs["bandwidth"]) ?? 0
        let rhsBandwidth = JSONValue.int(rhs["bandwidth"]) ?? 0
        if lhsBandwidth != rhsBandwidth {
            return lhsBandwidth > rhsBandwidth
        }

        let lhsCodecid = JSONValue.int(lhs["codecid"]) ?? 0
        let rhsCodecid = JSONValue.int(rhs["codecid"]) ?? 0
        return lhsCodecid > rhsCodecid
    }

    private func codecPriority(from json: [String: Any]) -> Int {
        let rawCodec = (JSONValue.string(json["codecs"]) ?? "").lowercased()
        let codecid = JSONValue.int(json["codecid"]) ?? 0

        if rawCodec.contains("avc1") || codecid == 7 {
            return 3
        }
        if rawCodec.contains("hev1") || rawCodec.contains("hvc1") || codecid == 12 {
            return 2
        }
        if rawCodec.contains("av01") || codecid == 13 {
            return 1
        }
        return 0
    }

    private func detailText(resolution: String?, bitrate: String?, codecs: String?) -> String? {
        let parts = [resolution, bitrate, codecs].reduce(into: [String]()) { partialResult, value in
            guard let value, !value.isEmpty else { return }
            partialResult.append(value)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    private func resolutionText(from json: [String: Any]) -> String? {
        guard let width = JSONValue.int(json["width"]),
              let height = JSONValue.int(json["height"]),
              width > 0,
              height > 0 else {
            return nil
        }
        return "\(width)x\(height)"
    }

    private func bitrateText(from json: [String: Any]) -> String? {
        guard let bandwidth = JSONValue.int(json["bandwidth"]), bandwidth > 0 else {
            return nil
        }

        if bandwidth >= 1_000_000 {
            return String(format: "%.1f Mbps", Double(bandwidth) / 1_000_000)
        }
        return String(format: "%.0f kbps", Double(bandwidth) / 1_000)
    }

    private func codecText(from json: [String: Any]) -> String? {
        let rawCodec = (JSONValue.string(json["codecs"]) ?? "").lowercased()
        if rawCodec.contains("av01") {
            return "AV1"
        }
        if rawCodec.contains("hev1") || rawCodec.contains("hvc1") {
            return "HEVC"
        }
        if rawCodec.contains("avc1") {
            return "AVC"
        }

        if let codecid = JSONValue.int(json["codecid"]) {
            switch codecid {
            case 12:
                return "HEVC"
            case 13:
                return "AV1"
            case 7:
                return "AVC"
            default:
                break
            }
        }

        guard !rawCodec.isEmpty else { return nil }
        return rawCodec.uppercased()
    }

    private func frameRateText(from json: [String: Any]) -> String? {
        guard let rawValue = JSONValue.string(json["frame_rate"]), !rawValue.isEmpty else {
            return nil
        }

        if rawValue.contains("/") {
            let pieces = rawValue.split(separator: "/")
            if pieces.count == 2,
               let numerator = Double(pieces[0]),
               let denominator = Double(pieces[1]),
               denominator != 0 {
                let fps = numerator / denominator
                return fps >= 50
                    ? String(format: "%.0f fps", fps)
                    : String(format: "%.1f fps", fps)
            }
        }

        if let fps = Double(rawValue) {
            return fps >= 50
                ? String(format: "%.0f fps", fps)
                : String(format: "%.1f fps", fps)
        }

        return rawValue
    }

    private func dynamicRangeText(from json: [String: Any]) -> String? {
        if (JSONValue.int(json["dolby_type"]) ?? 0) > 0 {
            return L10n.qualityDolbyVision
        }

        if (JSONValue.int(json["hdr_type"]) ?? 0) > 0 {
            return L10n.qualityHDR
        }

        guard let rawValue = JSONValue.string(json["dynamic_range"]), !rawValue.isEmpty else {
            return nil
        }
        return rawValue.uppercased()
    }

    private func nextDanmakuLane(for time: TimeInterval, laneBusyUntil: inout [TimeInterval]) -> Int {
        if let lane = laneBusyUntil.firstIndex(where: { time >= $0 }) {
            laneBusyUntil[lane] = time + 0.9
            return lane
        }

        let fallbackLane = laneBusyUntil.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
        laneBusyUntil[fallbackLane] = time + 0.9
        return fallbackLane
    }

    private func resolveInitialQuality(from playable: NativePlayableSource) async throws -> PlaybackQualityOption? {
        guard let preferredOption = playable.defaultQuality else {
            return nil
        }

        let candidates = [preferredOption] + playable.qualityOptions.filter { $0 != preferredOption }
        var lastError: Error?

        for option in candidates {
            do {
                try await applyQuality(option, preserveTime: false, autoplay: true)
                return option
            } catch {
                lastError = error
            }
        }

        if let lastError {
            throw lastError
        }
        return nil
    }

    private func makeSource(from playable: NativePlayableSource, selectedOption: PlaybackQualityOption) -> NativePlayableSource {
        NativePlayableSource(
            title: playable.title,
            mode: selectedOption.mode == .direct ? .direct : .composite,
            fallbackWebURL: playable.fallbackWebURL,
            note: note(for: selectedOption),
            qualityOptions: playable.qualityOptions,
            defaultQuality: selectedOption,
            currentQualityLabel: selectedOption.label
        )
    }

    private func makePlayerItem(for option: PlaybackQualityOption) async throws -> AVPlayerItem {
        switch option.mode {
        case .direct:
            let asset = makeMediaAsset(url: option.videoURL)
            guard try await asset.load(.isPlayable) else {
                throw APIError.server(L10n.nativeStreamUnavailable)
            }
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 1.5
            return item
        case .composite:
            if let item = try await makeCompositeItem(videoURL: option.videoURL, audioURL: option.audioURL) {
                item.preferredForwardBufferDuration = 1.5
                return item
            }
            let fallbackItem = AVPlayerItem(asset: makeMediaAsset(url: option.videoURL))
            fallbackItem.preferredForwardBufferDuration = 1.5
            return fallbackItem
        }
    }

    private func makeMediaAsset(url: URL) -> AVURLAsset {
        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? HTTPCookieStorage.shared.cookies ?? []
        let headers = [
            "User-Agent": BiliAPIClient.userAgent,
            "Referer": "\(BiliBaseURL.web)/",
            "Origin": BiliBaseURL.web,
            "Accept": "*/*"
        ]
        let options: [String: Any] = [
            "AVURLAssetHTTPUserAgentKey": BiliAPIClient.userAgent,
            "AVURLAssetHTTPHeaderFieldsKey": headers,
            "AVURLAssetHTTPCookiesKey": cookies
        ]
        return AVURLAsset(url: url, options: options)
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        clearPlayerItemObservers()

        playerItemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] observedItem, _ in
            guard let self else { return }

            Task { @MainActor in
                switch observedItem.status {
                case .readyToPlay:
                    self.errorMessage = nil
                case .failed:
                    self.errorMessage = observedItem.error?.localizedDescription ?? L10n.nativePlaybackFailed
                    self.isPlaying = false
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        playerFailureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
            self.errorMessage = error?.localizedDescription ?? L10n.nativePlaybackFailed
            self.isPlaying = false
        }

        playerStallObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.errorMessage == nil {
                self.errorMessage = L10n.nativePlaybackStalled
            }
        }
    }

    private func clearPlayerItemObservers() {
        playerItemStatusObservation?.invalidate()
        playerItemStatusObservation = nil

        if let playerFailureObserver {
            NotificationCenter.default.removeObserver(playerFailureObserver)
            self.playerFailureObserver = nil
        }

        if let playerStallObserver {
            NotificationCenter.default.removeObserver(playerStallObserver)
            self.playerStallObserver = nil
        }
    }

    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            if errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
    }
}
