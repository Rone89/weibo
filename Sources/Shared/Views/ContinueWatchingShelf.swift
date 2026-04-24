import SwiftUI

struct ContinueWatchingShelf: View {
    let title: String
    let subtitle: String
    let records: [PlaybackProgressRecord]
    var tint: Color = Color("AccentColor")

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(
                title: title,
                subtitle: subtitle
            )

            if let featuredRecord = records.first {
                NavigationLink(value: featuredRecord.videoSummary) {
                    ContinueWatchingSpotlightCard(record: featuredRecord, tint: tint)
                }
                .buttonStyle(.plain)
            }

            if records.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(records.dropFirst())) { record in
                            NavigationLink(value: record.videoSummary) {
                                ContinueWatchingCompactCard(record: record, tint: tint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct ContinueWatchingSpotlightCard: View {
    let record: PlaybackProgressRecord
    let tint: Color

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncPosterImage(urlString: record.coverURL, width: nil, height: 220)
                .frame(maxWidth: .infinity)
                .drawingGroup(opaque: true)
                .overlay(alignment: .bottomLeading) {
                    GeometryReader { proxy in
                        VStack {
                            Spacer(minLength: 0)

                            Capsule()
                                .fill(tint)
                                .frame(
                                    width: max(18, proxy.size.width * CGFloat(record.progressFraction)),
                                    height: 4
                                )
                                .padding(.horizontal, 18)
                                .padding(.bottom, 18)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }

            LinearGradient(
                colors: [.clear, .black.opacity(0.74)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    shelfPill(record.resolvedAuthorName, systemImage: "person.fill")
                    if let partTitle = record.partTitle, !partTitle.isEmpty {
                        shelfPill(partTitle, systemImage: "list.number")
                    }
                    shelfPill(BiliFormatting.relativeDate(record.updatedAt), systemImage: "clock.fill")
                }

                Text(record.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let subtitle = record.resolvedSubtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Text(record.watchedText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.96))

                    Text(record.progressDetailText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.84))
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .biliHeroCardStyle(cornerRadius: 28, tint: tint)
    }

    private func shelfPill(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.34), in: Capsule())
    }
}

private struct ContinueWatchingCompactCard: View {
    let record: PlaybackProgressRecord
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncPosterImage(urlString: record.coverURL, width: 208, height: 118)
                .frame(width: 208)
                .overlay(alignment: .bottomLeading) {
                    Capsule()
                        .fill(tint)
                        .frame(width: max(18, 192 * CGFloat(record.progressFraction)), height: 4)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(record.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(record.resolvedSubtitle ?? record.resolvedAuthorName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(record.progressDetailText, systemImage: "play.fill")
                        .lineLimit(1)
                    Label(BiliFormatting.relativeDate(record.updatedAt), systemImage: "clock")
                        .lineLimit(1)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
            }
        }
        .frame(width: 224, alignment: .leading)
        .padding(12)
        .biliListCardStyle(tint: tint, interactive: true)
    }
}
