import Foundation

enum HTMLSanitizer {
    static func plainText(_ html: String?) -> String {
        guard let html, !html.isEmpty else {
            return ""
        }

        return html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum BiliFormatting {
    static func compactCount(_ value: Int?) -> String {
        guard let value else { return "--" }
        switch value {
        case 100_000_000...:
            return String(format: "%.1f", Double(value) / 100_000_000) + "\u{4ebf}"
        case 10_000...:
            return String(format: "%.1f", Double(value) / 10_000) + "\u{4e07}"
        default:
            return "\(value)"
        }
    }

    static func duration(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else {
            return "--:--"
        }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainSeconds)
    }

    static func playbackRate(_ rate: Float) -> String {
        let scaled = Int((rate * 100).rounded())
        if scaled.isMultiple(of: 100) {
            return "\(scaled / 100)x"
        }
        if scaled.isMultiple(of: 10) {
            return String(format: "%.1fx", rate)
        }
        return String(format: "%.2fx", rate)
    }

    static func relativeDate(_ date: Date?) -> String {
        guard let date else { return L10n.unknownTime }

        let interval = Date().timeIntervalSince(date)
        if interval < 60 * 60 {
            return L10n.minutesAgo(max(1, Int(interval / 60)))
        }
        if interval < 60 * 60 * 24 {
            return L10n.hoursAgo(max(1, Int(interval / 3600)))
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func parseDuration(_ rawValue: Any?) -> Int? {
        if let value = JSONValue.int(rawValue) {
            return value
        }
        guard let stringValue = JSONValue.string(rawValue), !stringValue.isEmpty else {
            return nil
        }

        let pieces = stringValue.split(separator: ":").compactMap { Int($0) }
        guard !pieces.isEmpty else {
            return nil
        }

        switch pieces.count {
        case 3:
            return pieces[0] * 3600 + pieces[1] * 60 + pieces[2]
        case 2:
            return pieces[0] * 60 + pieces[1]
        default:
            return pieces[0]
        }
    }
}

extension String {
    var normalizedBiliURLString: String {
        var candidate = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else {
            return candidate
        }

        if candidate.hasPrefix("//") {
            candidate = "https:\(candidate)"
        } else if candidate.lowercased().hasPrefix("http://") {
            candidate = "https://" + candidate.dropFirst("http://".count)
        }

        if let components = URLComponents(string: candidate),
           let normalized = components.string,
           !normalized.isEmpty {
            return normalized
        }

        return candidate.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? candidate
    }
}
