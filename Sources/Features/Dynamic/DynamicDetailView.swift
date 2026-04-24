import SwiftUI

struct DynamicDetailView: View {
    @StateObject var viewModel: DynamicDetailViewModel
    @State private var isExpandedText = false

    init(viewModel: DynamicDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let item = currentItem {
                    heroPanel(item)
                    readingSection(item)

                    if !item.images.isEmpty {
                        detailSection(
                            title: L10n.dynamicMediaTitle,
                            subtitle: L10n.dynamicMediaSubtitle(item.images.count)
                        ) {
                            DynamicImageGrid(images: item.images)
                        }
                    }

                    if let video = item.video {
                        detailSection(
                            title: L10n.dynamicAttachedVideoTitle,
                            subtitle: L10n.dynamicAttachedVideoSubtitle
                        ) {
                            NavigationLink(value: video) {
                                DynamicEmbeddedVideoCard(video: video)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let quoted = item.quoted, quoted.hasDisplayContent {
                        detailSection(
                            title: L10n.dynamicQuotedTitle,
                            subtitle: L10n.dynamicQuotedSubtitle(quoted.authorName)
                        ) {
                            DynamicQuotedCard(quoted: quoted)
                        }
                    }

                    if let commentOID = item.commentOID,
                       commentOID > 0,
                       let commentType = item.commentType,
                       commentType > 0 {
                        VideoCommentsSection(
                            apiClient: viewModel.apiClient,
                            oid: commentOID,
                            replyType: commentType
                        )
                        .padding(18)
                        .biliListCardStyle()
                    }
                } else if viewModel.isLoading {
                    ProgressView(L10n.dynamicDetailLoading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
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
        .navigationTitle(L10n.dynamicDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: currentItem?.id) { _ in
            isExpandedText = false
        }
        .refreshable {
            await viewModel.reload()
        }
        .navigationDestination(for: VideoSummary.self) { video in
            VideoDetailView(
                viewModel: VideoDetailViewModel(apiClient: viewModel.apiClient, seedVideo: video)
            )
        }
        .navigationDestination(for: UserReference.self) { reference in
            UserProfileView(apiClient: viewModel.apiClient, reference: reference)
        }
    }

    private var currentItem: DynamicFeedItem? {
        viewModel.detailItem ?? viewModel.seedItem
    }

    private func heroPanel(_ item: DynamicFeedItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                authorHeader(item)

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                DynamicStatPill(
                    text: BiliFormatting.compactCount(item.stats.likeCount),
                    systemImage: item.stats.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
                    tint: item.stats.isLiked ? .pink : Color("AccentColor")
                )
                DynamicStatPill(
                    text: BiliFormatting.compactCount(item.stats.commentCount),
                    systemImage: "ellipsis.bubble",
                    tint: .blue
                )
                DynamicStatPill(
                    text: BiliFormatting.compactCount(item.stats.shareCount),
                    systemImage: "arrowshape.turn.up.right",
                    tint: .orange
                )
            }
        }
        .padding(20)
        .biliListCardStyle(tint: .pink, interactive: true)
    }

    @ViewBuilder
    private func authorHeader(_ item: DynamicFeedItem) -> some View {
        if let reference = authorReference(item) {
            NavigationLink(value: reference) {
                authorHeaderContent(item)
            }
            .buttonStyle(.plain)
        } else {
            authorHeaderContent(item)
        }
    }

    private func authorHeaderContent(_ item: DynamicFeedItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            AsyncPosterImage(urlString: item.author.avatarURL, width: 58, height: 58)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.author.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let badge = item.author.badgeText, !badge.isEmpty {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color("AccentColor"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AccentColor").opacity(0.12), in: Capsule())
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 8) {
                    if let actionLabel = item.actionLabel, !actionLabel.isEmpty {
                        heroMetaChip(actionLabel)
                    }
                    if let publishLabel = item.publishLabel, !publishLabel.isEmpty {
                        heroMetaChip(publishLabel)
                    } else {
                        heroMetaChip(BiliFormatting.relativeDate(item.publishedAt))
                    }
                }

                if let topic = item.topic, !topic.isEmpty {
                    Text("#\(topic)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AccentColor"))
                        .lineLimit(1)
                }
            }
        }
    }

    private func readingSection(_ item: DynamicFeedItem) -> some View {
        detailSection(
            title: L10n.dynamicReadingTitle,
            subtitle: L10n.dynamicDetailSubtitle
        ) {
            if !item.text.isEmpty {
                Text(displayedReadingText(for: item.text))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                if needsTextExpansion(item.text) {
                    Button(isExpandedText ? L10n.dynamicCollapseText : L10n.dynamicExpandText) {
                        withAnimation(.linear(duration: 0.12)) {
                            isExpandedText.toggle()
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color("AccentColor"))
                    .font(.subheadline.weight(.semibold))
                }
            } else {
                Text(L10n.dynamicReadingEmpty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func detailSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BiliSectionHeader(title: title, subtitle: subtitle)
            content()
        }
        .padding(18)
        .biliListCardStyle()
    }

    private func heroMetaChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground).opacity(0.92), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
    }

    private func displayedReadingText(for text: String) -> String {
        guard needsTextExpansion(text), !isExpandedText else { return text }
        return String(text.prefix(220)) + "..."
    }

    private func needsTextExpansion(_ text: String) -> Bool {
        text.count > 220
    }

    private func authorReference(_ item: DynamicFeedItem) -> UserReference? {
        guard let mid = item.author.mid, mid > 0 else { return nil }
        return UserReference(mid: mid, name: item.author.name, avatarURL: item.author.avatarURL)
    }
}
