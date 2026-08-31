import SwiftUI

/// "Book a Consultation" — a real structured entry point into the same
/// Conversation/Message system as everything else. The four fields
/// below become the first message's body (see
/// APIClient.startConsultation); there's no separate "inquiries" data
/// model.
struct ConsultationFormView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var showingAuth = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var error: Error?
    @State private var startedConversation: Conversation?

    private var canSubmit: Bool {
        !fullName.isEmpty && !email.isEmpty && !phone.isEmpty && !message.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                reassurance
                form

                if let error {
                    InlineErrorText(error: error)
                }

                Button {
                    submit()
                } label: {
                    if isSubmitting { InlineSpinner(tint: Theme.canvas) } else { Text("Schedule My Consultation") }
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: !canSubmit))
                .disabled(!canSubmit || isSubmitting)
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Book a Consultation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prefillFromSession)
        .sheet(isPresented: $showingAuth) {
            AuthFlowView().environmentObject(session)
        }
        .background(conversationNavigationLink)
    }

    // isActive-driven NavigationLink, not `navigationDestination(item:)`
    // (iOS 17+ only) — this app's deployment target is 16.0.
    private var conversationNavigationLink: some View {
        NavigationLink(
            destination: Group {
                if let startedConversation {
                    ConversationDetailView(conversation: startedConversation).environmentObject(session)
                }
            },
            isActive: Binding(
                get: { startedConversation != nil },
                set: { isActive in if !isActive { startedConversation = nil } }
            )
        ) { EmptyView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LET'S BUILD SOMETHING LEGENDARY")
                .font(Theme.Font.eyebrow(11))
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
            Text("Let's discuss your goals and create a strategy that delivers results.")
                .font(Theme.Font.headline(18))
                .foregroundStyle(Theme.ink)
        }
    }

    private var reassurance: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            reassuranceRow(icon: "target", title: "Personalized Strategy", subtitle: "Tailored to your goals")
            reassuranceRow(icon: "person.badge.shield.checkmark", title: "Expert Guidance", subtitle: "Decades of experience")
            reassuranceRow(icon: "key", title: "Exclusive Opportunities", subtitle: "Off-market access")
            reassuranceRow(icon: "lock.shield", title: "Confidential & Trusted", subtitle: "Your success is our priority")
        }
        .padding(Theme.Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private func reassuranceRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.Font.body(13).weight(.semibold)).foregroundStyle(Theme.ink)
                Text(subtitle).font(Theme.Font.body(11)).foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var form: some View {
        VStack(spacing: Theme.Spacing.sm) {
            FormTextField(placeholder: "Full Name", text: $fullName)
            FormTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress)
            FormTextField(placeholder: "Phone Number", text: $phone, keyboardType: .phonePad)
            FormTextEditor(placeholder: "How can we help?", text: $message)
        }
    }

    private func prefillFromSession() {
        if let user = session.currentUser {
            if fullName.isEmpty { fullName = user.displayName }
            if email.isEmpty { email = user.email }
        }
    }

    private func submit() {
        guard session.status == .authenticated else {
            showingAuth = true
            return
        }
        error = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let response = try await session.apiClient.startConsultation(
                    fullName: fullName, email: email, phone: phone, message: message
                )
                startedConversation = response.conversation
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    NavigationStack { ConsultationFormView() }.environmentObject(SessionStore())
}
