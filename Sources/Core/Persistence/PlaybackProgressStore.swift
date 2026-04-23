import Foundation

struct PlaybackProgressRecord: Identifiable, Codable, Hashable {
    let aid: Int?
    let bvid: String
    let cid: Int?
    let page: Int?
    let title: String
    let partTitle: String?
    let subtitle: String?
    let coverURL: String?
    let authorName: String?
    let progressSeconds: Double
    let durationSeconds: Double?
    let updatedAt: Date

    var id: String {
        PlaybackProgressStore.makeStorageKey(bvid: bvid, cid: cid)
    }

    var videoSummary: VideoSummary {
        VideoSummary(
            aid: aid,
            bvid: bvid,
            cid: cid,
            title: title,
            subtitle: subtitle ?? partTitle,
            coverURL: coverURL,
            duration: durationSeconds.map { Int($0.rounded()) },
            publishDate: nil,
            authorName: resolvedAuthorName,
            authorID: nil,
            authorAvatarURL: nil,
            viewCount: nil,
            likeCount: nil,
            danmakuCount: nil,
            reason: nil
        )
    }

    var resolvedAuthorName: String {
        guard let authorName, !authorName.isEmpty else { return L10n.unknownUP }
        return authorName
    }

    var resolvedSubtitle: String? {
        if let subtitle, !subtitle.isEmpty {
            return subtitle
        }
        if let partTitle, !partTitle.isEmpty {
            return partTitle
        }
        return nil
    }

    var progressFraction: Double {
        guard let durationSeconds, durationSeconds > 0 else { return 0 }
        return min(max(progressSeconds / durationSeconds, 0), 1)
    }

    var watchedText: String {
        L10n.watchedPrefix(BiliFormatting.duration(Int(progressSeconds.rounded())))
    }

    var progressDetailText: String {
        let progressText = BiliFormatting.duration(Int(progressSeconds.rounded()))
        guard let durationSeconds, durationSeconds > 0 else { return progressText }
        return "\(progressText) / \(BiliFormatting.duration(Int(durationSeconds.rounded())))"
    }
}

@MainActor
final class PlaybackProgressStore: ObservableObject {
    static let shared = PlaybackProgressStore()

    private enum Keys {
        static let records = "playback.progress.records.v1"
    }

    @Published private(set) var records: [String: PlaybackProgressRecord]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.records = Self.loadRecords(from: defaults)
    }

    var recentRecords: [PlaybackProgressRecord] {
        records.values.sorted { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.progressSeconds > rhs.progressSeconds
        }
    }

    func recentRecords(limit: Int) -> [PlaybackProgressRecord] {
        Array(recentRecords.prefix(max(0, limit)))
    }

    func progress(for video: VideoSummary, page: VideoDetailPage?) -> PlaybackProgressRecord? {
        let bvid = video.bvid
        guard !bvid.isEmpty else { return nil }

        let cid = page?.cid ?? video.cid
        if let cid {
            return records[Self.makeStorageKey(bvid: bvid, cid: cid)]
        }

        return records.values
            .filter { $0.bvid == bvid }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    func bestProgress(bvid: String, pages: [VideoDetailPage]) -> PlaybackProgressRecord? {
        guard !bvid.isEmpty else { return nil }

        let pageCids = Set(pages.map(\.cid))
        return records.values
            .filter { record in
                record.bvid == bvid && (record.cid == nil || pageCids.isEmpty || pageCids.contains(record.cid ?? -1))
            }
            .sorted { lhs, rhs in
                if lhs.updatedAt != rhs.updatedAt {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return lhs.progressSeconds > rhs.progressSeconds
            }
            .first
    }

    func saveProgress(
        video: VideoSummary,
        page: VideoDetailPage?,
        progressSeconds: TimeInterval,
        durationSeconds: TimeInterval,
        title: String? = nil,
        updatedAt: Date? = nil
    ) {
        guard !video.bvid.isEmpty else { return }

        let normalizedProgress = max(0, progressSeconds)
        let normalizedDuration = max(0, durationSeconds)
        let storageKey = Self.makeStorageKey(bvid: video.bvid, cid: page?.cid ?? video.cid)

        guard shouldKeepProgress(progressSeconds: normalizedProgress, durationSeconds: normalizedDuration) else {
            removeRecord(forKey: storageKey)
            return
        }

        records[storageKey] = PlaybackProgressRecord(
            aid: video.aid,
            bvid: video.bvid,
            cid: page?.cid ?? video.cid,
            page: page?.page,
            title: title ?? video.title,
            partTitle: page?.part,
            subtitle: video.subtitle,
            coverURL: video.coverURL,
            authorName: video.authorName,
            progressSeconds: normalizedProgress,
            durationSeconds: normalizedDuration > 0 ? normalizedDuration : nil,
            updatedAt: updatedAt ?? Date()
        )
        persist()
    }

    func clearProgress(for video: VideoSummary, page: VideoDetailPage?) {
        guard !video.bvid.isEmpty else { return }
        let storageKey = Self.makeStorageKey(bvid: video.bvid, cid: page?.cid ?? video.cid)
        removeRecord(forKey: storageKey)
    }

    func clearProgress(_ record: PlaybackProgressRecord) {
        removeRecord(forKey: record.id)
    }

    func clearAllProgress() {
        guard !records.isEmpty else { return }
        records.removeAll()
        persist()
    }

    nonisolated static func makeStorageKey(bvid: String, cid: Int?) -> String {
        "\(bvid)#\(cid ?? 0)"
    }

    private let defaults: UserDefaults

    private func shouldKeepProgress(progressSeconds: TimeInterval, durationSeconds: TimeInterval) -> Bool {
        guard progressSeconds >= 5 else { return false }
        guard durationSeconds > 0 else { return true }

        let remaining = max(0, durationSeconds - progressSeconds)
        let ratio = progressSeconds / durationSeconds
        return ratio < 0.97 && remaining > 8
    }

    private func removeRecord(forKey key: String) {
        guard records.removeValue(forKey: key) != nil else { return }
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let payload = records.values.sorted { $0.updatedAt > $1.updatedAt }
        if payload.isEmpty {
            defaults.removeObject(forKey: Keys.records)
            return
        }
        guard let data = try? encoder.encode(payload) else { return }
        defaults.set(data, forKey: Keys.records)
    }

    private static func loadRecords(from defaults: UserDefaults) -> [String: PlaybackProgressRecord] {
        guard let data = defaults.data(forKey: Keys.records) else { return [:] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode([PlaybackProgressRecord].self, from: data) else {
            return [:]
        }

        return payload.reduce(into: [:]) { partialResult, record in
            partialResult[record.id] = record
        }
    }
}
