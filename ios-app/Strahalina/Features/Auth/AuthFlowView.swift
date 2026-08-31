import SwiftUI

/// Only reached when a signed-out visitor tries to send a message —
/// public browsing never requires this. Sign in / sign up toggle in one
/// screen, mirroring the other apps' auth flow structure.
struct AuthFlowView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSubmitting = false
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                Picker("Mode", selection: $isSignUp) {
                    Text("Sign In").tag(false)
                    Text("Create Account").tag(true)
                }
                .pickerStyle(.segmented)

                if isSignUp {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                        .foregroundStyle(Theme.ink)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                                .stroke(Theme.borderSubtle, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
                }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .foregroundStyle(Theme.ink)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                            .stroke(Theme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .foregroundStyle(Theme.ink)
                    .padding(Theme.Spacing.sm)
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
                    if isSubmitting { InlineSpinner(tint: Theme.canvas) } else { Text(isSignUp ? "Create Account" : "Sign In") }
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: !canSubmit))
                .disabled(!canSubmit || isSubmitting)

                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 8 && (!isSignUp || !displayName.isEmpty)
    }

    private func submit() {
        error = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                if isSignUp {
                    try await session.signup(email: email, password: password, displayName: displayName)
                } else {
                    try await session.login(email: email, password: password)
                }
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    AuthFlowView().environmentObject(SessionStore())
}
