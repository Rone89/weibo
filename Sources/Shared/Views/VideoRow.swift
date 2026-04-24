import SwiftUI

struct VideoRow: View {
    let video: VideoSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncPosterImage(urlString: video.coverURL, width: 140, height: 88)
                .overlay(alignment: .bottomTrailing) {
                    Text(BiliFormatting.duration(video.duration))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.72), in: Capsule())
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    miniStat(text: BiliFormatting.compactCount(video.viewCount), icon: "play.fill")
                    miniStat(text: BiliFormatting.compactCount(video.danmakuCount), icon: "text.bubble.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color("AccentColor"))
                    Text(video.authorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let reason = video.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(Color("AccentColor"))
                        .lineLimit(1)
                } else if let subtitle = video.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .biliListCardStyle(interactive: true)
    }

    private func miniStat(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.systemBackground).opacity(0.72))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
    }

}
