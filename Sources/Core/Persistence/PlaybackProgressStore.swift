import Foundation

struct PlaybackProgressRecord: Identifiable, Codable, Hashable {
    let bvid: String
    let cid: Int?
    let page: Int?
    let title: String
    let partTitle: String?
    let progressSeconds: Double
    let durationSeconds: Double?
    let updatedAt: Date

    var id: String {
        PlaybackProgressStore.makeStorageKey(bvid: bvid, cid: cid)
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
        title: String? = nil
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
            bvid: video.bvid,
            cid: page?.cid ?? video.cid,
            page: page?.page,
            title: title ?? video.title,
            partTitle: page?.part,
            progressSeconds: normalizedProgress,
            durationSeconds: normalizedDuration > 0 ? normalizedDuration : nil,
            updatedAt: Date()
        )
        persist()
    }

    func clearProgress(for video: VideoSummary, page: VideoDetailPage?) {
        guard !video.bvid.isEmpty else { return }
        let storageKey = Self.makeStorageKey(bvid: video.bvid, cid: page?.cid ?? video.cid)
        removeRecord(forKey: storageKey)
    }

    static func makeStorageKey(bvid: String, cid: Int?) -> String {
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
