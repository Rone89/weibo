import Foundation

struct PlaybackQualityOption: Identifiable, Hashable {
    enum StreamMode: Hashable {
        case direct
        case composite
    }

    let qn: Int
    let label: String
    let detail: String?
    let mode: StreamMode
    let resolution: String?
    let bitrate: String?
    let codecs: String?
    let frameRate: String?
    let dynamicRange: String?
    let videoURL: URL
    let audioURL: URL?

    var id: String { "\(mode)-\(qn)-\(videoURL.absoluteString)" }

    var streamBadge: String {
        mode == .direct ? L10n.qualityStreamDirect : L10n.qualityStreamDash
    }

    var audioDetail: String? {
        audioURL == nil ? nil : L10n.qualityAudio(L10n.qualityAudioMuxed)
    }
}

struct DanmakuItem: Identifiable, Hashable {
    let id: String
    let time: TimeInterval
    let text: String
    let colorHex: String
    let mode: Int
    let fontSize: Int
}

struct DanmakuOverlayItem: Identifiable, Hashable {
    let item: DanmakuItem
    let laneIndex: Int
    let progress: Double

    var id: String { item.id }
}

struct NativePlayableSource: Hashable {
    enum Mode: Hashable {
        case direct
        case composite
        case webFallback
    }

    let title: String
    let mode: Mode
    let fallbackWebURL: URL
    let note: String?
    let qualityOptions: [PlaybackQualityOption]
    let defaultQuality: PlaybackQualityOption?
    let currentQualityLabel: String?
}
