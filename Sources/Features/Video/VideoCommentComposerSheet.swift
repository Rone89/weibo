import SwiftUI

struct VideoCommentComposerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let placeholder: String
    let submitTitle: String
    let onSubmit: (String) async -> Bool

    @State private var draft = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $draft)
                    .font(.body)
                    .frame(minHeight: 220)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                HStack {
                    Text(L10n.videoCommentsDraftCount(draft.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isSubmitting {
                        ProgressView()
                    }
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(submitTitle) {
                        Task {
                            await submit()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSubmitting || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let succeeded = await onSubmit(draft)
        if succeeded {
            dismiss()
        }
    }
}
