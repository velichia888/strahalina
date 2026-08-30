import SwiftUI

struct InquiryComposeView: View {
    let listing: Listing

    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var message = ""
    @State private var isSubmitting = false
    @State private var error: Error?
    @State private var didSucceed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                if didSucceed {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: "#2E7D32"))
                        Text("Inquiry sent")
                            .font(Theme.Font.headline(18))
                            .foregroundStyle(Theme.ink)
                        Text("Strahalina will reach out to you directly.")
                            .font(Theme.Font.body(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.top, Theme.Spacing.xl)
                } else {
                    Text(listing.title)
                        .font(Theme.Font.body(14).weight(.semibold))
                        .foregroundStyle(Theme.inkSoft)

                    TextEditor(text: $message)
                        .frame(minHeight: 140)
                        .padding(Theme.Spacing.xs)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))

                    if let error {
                        InlineErrorText(error: error)
                    }

                    Button {
                        submit()
                    } label: {
                        if isSubmitting { InlineSpinner(tint: .white) } else { Text("Send Inquiry") }
                    }
                    .buttonStyle(PrimaryButtonStyle(isDisabled: message.isEmpty))
                    .disabled(message.isEmpty || isSubmitting)
                }
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Send Inquiry")
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
                _ = try await session.apiClient.submitInquiry(listingId: listing.id, message: message)
                didSucceed = true
            } catch {
                self.error = error
            }
        }
    }
}
