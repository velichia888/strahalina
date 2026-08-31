import SwiftUI

/// First-message composer for a listing. On success, hands the created
/// conversation back to the caller (ListingDetailView) so it can push
/// straight into the real chat thread — the first message the buyer
/// types here IS the conversation's opening message, not a separate
/// one-shot "inquiry" concept.
struct MessageComposeView: View {
    let listing: Listing
    var prefill: String = ""
    var onStarted: (Conversation) -> Void

    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var message: String
    @State private var isSubmitting = false
    @State private var error: Error?

    init(listing: Listing, prefill: String = "", onStarted: @escaping (Conversation) -> Void) {
        self.listing = listing
        self.prefill = prefill
        self.onStarted = onStarted
        _message = State(initialValue: prefill)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                Text(listing.title)
                    .font(Theme.Font.body(14).weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)

                TextEditor(text: $message)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Theme.ink)
                    .frame(minHeight: 140)
                    .padding(Theme.Spacing.xs)
                    .background(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                            .stroke(Theme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))

                if let error {
                    InlineErrorText(error: error)
                }

                Button {
                    submit()
                } label: {
                    if isSubmitting { InlineSpinner(tint: Theme.canvas) } else { Text("Send Message") }
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: message.isEmpty))
                .disabled(message.isEmpty || isSubmitting)

                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        error = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let response = try await session.apiClient.startConversation(listingId: listing.id, message: message)
                dismiss()
                onStarted(response.conversation)
            } catch {
                self.error = error
            }
        }
    }
}
