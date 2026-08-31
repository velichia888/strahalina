import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var showingAuth = false
    @State private var showingChangePassword = false

    var body: some View {
        NavigationStack {
            List {
                if let user = session.currentUser {
                    Section("Account") {
                        LabeledContent("Name", value: user.displayName)
                        LabeledContent("Email", value: user.email)
                        if user.isAdmin {
                            LabeledContent("Role", value: "Admin")
                        }
                    }
                    Section("Security") {
                        Button("Change Password") { showingChangePassword = true }
                    }
                    Section {
                        Button(role: .destructive) { session.logout() } label: { Text("Sign Out") }
                    }
                } else {
                    Section {
                        Text("Sign in to message about listings.")
                            .font(Theme.Font.body(13))
                            .foregroundStyle(Theme.inkSoft)
                        Button("Sign In / Create Account") { showingAuth = true }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingAuth) {
                AuthFlowView().environmentObject(session)
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordSheet().environmentObject(session)
            }
        }
    }
}

private struct ChangePasswordSheet: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var isSubmitting = false
    @State private var error: Error?
    @State private var didSucceed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                if didSucceed {
                    Text("Password updated").font(Theme.Font.headline(18)).foregroundStyle(Theme.ink)
                } else {
                    SecureField("Current password", text: $currentPassword)
                        .textContentType(.password)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))

                    SecureField("New password (min 8 characters)", text: $newPassword)
                        .textContentType(.newPassword)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))

                    if let error {
                        InlineErrorText(error: error)
                    }

                    Button {
                        submit()
                    } label: {
                        if isSubmitting { InlineSpinner(tint: .white) } else { Text("Update Password") }
                    }
                    .buttonStyle(PrimaryButtonStyle(isDisabled: newPassword.count < 8))
                    .disabled(newPassword.count < 8 || isSubmitting)
                }
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Change Password")
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
                try await session.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                didSucceed = true
            } catch {
                self.error = error
            }
        }
    }
}
