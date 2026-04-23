import SwiftUI

struct VideoCommentsSection: View {
    @StateObject private var viewModel: VideoCommentsViewModel
    let oid: Int?

    @State private var composeTarget: CommentComposeTarget?
    @State private var threadTarget: VideoComment?

    init(apiClient: BiliAPIClient, oid: Int?, replyType: Int = 1) {
        _viewModel = StateObject(wrappedValue: VideoCommentsViewModel(apiClient: apiClient, replyType: replyType))
        self.oid = oid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let actionMessage = viewModel.actionMessage {
                Text(actionMessage)
                    .font(.footnote)
                    .foregroundStyle(Color("AccentColor"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color("AccentColor").opacity(0.08))
                    )
            }

            if let inputPlaceholder = viewModel.inputPlaceholder, !inputPlaceholder.isEmpty {
                Button {
                    composeTarget = .newComment(placeholder: inputPlaceholder)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color("AccentColor"))
                        Text(inputPlaceholder)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color("AccentColor").opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .biliCardStyle(cornerRadius: 20, tint: .red.opacity(0.18))
            }

            if oid == nil {
                Text(L10n.videoCommentsPreparing)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if viewModel.isLoading && viewModel.replies.isEmpty && viewModel.topReplies.isEmpty {
                ProgressView(L10n.videoCommentsLoading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else if viewModel.replies.isEmpty && viewModel.topReplies.isEmpty {
                EmptyStateView(
                    title: L10n.videoCommentsEmptyTitle,
                    subtitle: L10n.videoCommentsEmptySubtitle,
                    systemImage: "text.bubble",
                    actionTitle: L10n.videoCommentsReloadAction,
                    action: {
                        Task { await viewModel.reload() }
                    }
                )
            } else {
                if !viewModel.topReplies.isEmpty {
                    pinnedSection
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.replies) { comment in
                        VideoCommentCard(
                            comment: comment,
                            onReply: {
                                composeTarget = .reply(
                                    comment: comment,
                                    placeholder: viewModel.childInputPlaceholder ?? L10n.videoCommentsReplyPlaceholder
                                )
                            },
                            onOpenThread: comment.replyCount > 0 ? {
                                threadTarget = comment
                            } : nil
                        )
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView(L10n.loadingMore)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                } else if viewModel.canLoadMore {
                    Button(L10n.loadMore) {
                        Task { await viewModel.loadMore() }
                    }
                    .buttonStyle(.plain)
                    .biliPrimaryActionButton(fillWidth: false)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .task(id: oid ?? -1) {
            await viewModel.loadIfNeeded(oid: oid)
        }
        .sheet(item: $composeTarget) { target in
            VideoCommentComposerSheet(
                title: target.title,
                placeholder: target.placeholder,
                submitTitle: target.submitTitle,
                onSubmit: { message in
                    switch target {
                    case .newComment:
                        return await viewModel.postComment(message: message, replyingTo: nil)
                    case .reply(let comment, _):
                        return await viewModel.postComment(message: message, replyingTo: comment)
                    }
                }
            )
        }
        .sheet(item: $threadTarget) { comment in
            if let oid = oid, let rootID = comment.rootNumericID {
                VideoCommentRepliesSheet(
                    apiClient: viewModel.apiClient,
                    oid: oid,
                    replyType: viewModel.replyTypeValue,
                    rootID: rootID,
                    rootComment: comment
                )
            } else {
                EmptyView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            BiliSectionHeader(
                title: L10n.videoCommentsTitle,
                subtitle: L10n.videoCommentsCount(viewModel.totalCount)
            )

            Spacer()

            Menu {
                ForEach(VideoCommentsViewModel.SortMode.allCases) { mode in
                    Button(mode.title) {
                        Task { await viewModel.setSortMode(mode) }
                    }
                }
            } label: {
                Label(viewModel.sortMode.title, systemImage: "arrow.up.arrow.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
            }
        }
    }

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(
                title: L10n.videoCommentsPinnedTitle,
                subtitle: L10n.videoCommentsPinnedSubtitle(viewModel.topReplies.count)
            )

            VStack(spacing: 12) {
                ForEach(viewModel.topReplies) { comment in
                    VideoCommentCard(
                        comment: comment,
                        isPinned: true,
                        onReply: {
                            composeTarget = .reply(
                                comment: comment,
                                placeholder: viewModel.childInputPlaceholder ?? L10n.videoCommentsReplyPlaceholder
                            )
                        },
                        onOpenThread: comment.replyCount > 0 ? {
                            threadTarget = comment
                        } : nil
                    )
                }
            }
        }
    }
}

private enum CommentComposeTarget: Identifiable {
    case newComment(placeholder: String)
    case reply(comment: VideoComment, placeholder: String)

    var id: String {
        switch self {
        case .newComment:
            return "new-comment"
        case .reply(let comment, _):
            return "reply-\(comment.id)"
        }
    }

    var title: String {
        switch self {
        case .newComment:
            return L10n.videoCommentsComposerTitle
        case .reply(let comment, _):
            return L10n.videoCommentsReplyComposerTitle(comment.author.name)
        }
    }

    var placeholder: String {
        switch self {
        case .newComment(let placeholder):
            return placeholder
        case .reply(_, let placeholder):
            return placeholder
        }
    }

    var submitTitle: String {
        switch self {
        case .newComment:
            return L10n.videoCommentsSendAction
        case .reply:
            return L10n.videoCommentsReplyAction
        }
    }
}

private struct VideoCommentCard: View {
    let comment: VideoComment
    var isPinned = false
    var showsPreviewReplies = true
    let onReply: () -> Void
    let onOpenThread: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AsyncPosterImage(urlString: comment.author.avatarURL, width: 42, height: 42)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(comment.author.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        if let level = comment.author.level {
                            commentBadge(L10n.level(level), tint: Color("AccentColor"))
                        }

                        if comment.author.isVIP {
                            commentBadge(L10n.vip, tint: .orange)
                        }

                        if isPinned {
                            commentBadge(L10n.videoCommentsPinnedTag, tint: .pink)
                        }
                    }

                    Text(comment.message)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                Text(comment.timeLabel ?? BiliFormatting.relativeDate(comment.publishedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(BiliFormatting.compactCount(comment.likeCount), systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if comment.replyCount > 0 {
                    Label(BiliFormatting.compactCount(comment.replyCount), systemImage: "bubble.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button(L10n.videoCommentsReplyAction, action: onReply)
                    .buttonStyle(.plain)
                    .biliSecondaryActionButton(fillWidth: false)

                if let onOpenThread {
                    Button(
                        comment.replySummaryLabel ?? L10n.videoCommentsOpenThread(comment.replyCount),
                        action: onOpenThread
                    )
                    .buttonStyle(.plain)
                    .biliPrimaryActionButton(fillWidth: false)
                }
            }

            if showsPreviewReplies && !comment.previewReplies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(comment.previewReplies.prefix(2))) { reply in
                        VideoCommentReplyPreview(reply: reply)
                    }

                    if let summary = comment.replySummaryLabel, !summary.isEmpty {
                        Text(summary)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AccentColor"))
                    }
                }
                .padding(12)
                .biliCardStyle(cornerRadius: 20, tint: .blue.opacity(0.14), shadowOpacity: 0.02)
            }
        }
        .padding(16)
        .biliCardStyle(cornerRadius: 24, tint: isPinned ? .pink.opacity(0.18) : .white, interactive: false, shadowOpacity: 0.03)
    }

    private func commentBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct VideoCommentReplyPreview: View {
    let reply: VideoComment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(reply.author.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)

                if let parentReplyUserName = reply.parentReplyUserName, !parentReplyUserName.isEmpty {
                    Text(L10n.videoCommentsReplyTo(parentReplyUserName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(reply.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VideoCommentRepliesSheet: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: VideoCommentRepliesViewModel
    @State private var composeTarget: ThreadComposeTarget?

    init(apiClient: BiliAPIClient, oid: Int, replyType: Int, rootID: Int, rootComment: VideoComment) {
        _viewModel = StateObject(
            wrappedValue: VideoCommentRepliesViewModel(
                apiClient: apiClient,
                oid: oid,
                replyType: replyType,
                rootID: rootID,
                seedRootComment: rootComment
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let actionMessage = viewModel.actionMessage {
                        Text(actionMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("AccentColor"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color("AccentColor").opacity(0.08))
                            )
                    }

                    if let rootComment = viewModel.rootComment {
                        VideoCommentCard(
                            comment: rootComment,
                            isPinned: true,
                            showsPreviewReplies: false,
                            onReply: {
                                composeTarget = .reply(
                                    comment: rootComment,
                                    placeholder: viewModel.inputPlaceholder ?? L10n.videoCommentsReplyPlaceholder
                                )
                            },
                            onOpenThread: nil
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .biliCardStyle(cornerRadius: 20, tint: .red.opacity(0.18))
                    }

                    if let placeholder = viewModel.inputPlaceholder, !placeholder.isEmpty {
                        Button {
                            composeTarget = .root(placeholder: placeholder)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(Color("AccentColor"))
                                Text(placeholder)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 8)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color("AccentColor").opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.isLoading && viewModel.replies.isEmpty {
                        ProgressView(L10n.videoCommentsLoading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    } else if viewModel.replies.isEmpty {
                        EmptyStateView(
                            title: L10n.videoCommentsThreadEmptyTitle,
                            subtitle: L10n.videoCommentsThreadEmptySubtitle,
                            systemImage: "bubble.left.and.bubble.right",
                            actionTitle: L10n.videoCommentsReloadAction,
                            action: {
                                Task { await viewModel.reload() }
                            }
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.replies) { reply in
                                VideoCommentCard(
                                    comment: reply,
                                    showsPreviewReplies: false,
                                    onReply: {
                                        composeTarget = .reply(
                                            comment: reply,
                                            placeholder: viewModel.inputPlaceholder ?? L10n.videoCommentsReplyPlaceholder
                                        )
                                    },
                                    onOpenThread: nil
                                )
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView(L10n.loadingMore)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                        } else if viewModel.canLoadMore {
                            Button(L10n.loadMore) {
                                Task { await viewModel.loadMore() }
                            }
                            .buttonStyle(.plain)
                            .biliPrimaryActionButton(fillWidth: false)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .padding(16)
            }
            .background {
                BiliBackground {
                    Color.clear
                }
            }
            .navigationTitle(L10n.videoCommentsThreadTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadIfNeeded()
            }
        }
        .sheet(item: $composeTarget) { target in
            VideoCommentComposerSheet(
                title: target.title,
                placeholder: target.placeholder,
                submitTitle: target.submitTitle,
                onSubmit: { message in
                    switch target {
                    case .root:
                        return await viewModel.postComment(message: message, replyingTo: nil)
                    case .reply(let comment, _):
                        return await viewModel.postComment(message: message, replyingTo: comment)
                    }
                }
            )
        }
    }
}

private enum ThreadComposeTarget: Identifiable {
    case root(placeholder: String)
    case reply(comment: VideoComment, placeholder: String)

    var id: String {
        switch self {
        case .root:
            return "thread-root"
        case .reply(let comment, _):
            return "thread-reply-\(comment.id)"
        }
    }

    var title: String {
        switch self {
        case .root:
            return L10n.videoCommentsComposerTitle
        case .reply(let comment, _):
            return L10n.videoCommentsReplyComposerTitle(comment.author.name)
        }
    }

    var placeholder: String {
        switch self {
        case .root(let placeholder):
            return placeholder
        case .reply(_, let placeholder):
            return placeholder
        }
    }

    var submitTitle: String {
        switch self {
        case .root:
            return L10n.videoCommentsReplyAction
        case .reply:
            return L10n.videoCommentsReplyAction
        }
    }
}
