import SwiftUI

/// "Investor Inquiry" — same real Conversation/Message system as
/// Consultation, different structured fields (see
/// APIClient.startInvestorInquiry). The investment range / strategy
/// options below are just form choices, not real market data.
struct InvestorInquiryFormView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var showingAuth = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var investmentRange = ""
    @State private var preferredStrategy = ""
    @State private var additionalInfo = ""
    @State private var isSubmitting = false
    @State private var error: Error?
    @State private var startedConversation: Conversation?

    private let investmentRangeOptions = ["Under $250k", "$250k–$500k", "$500k–$1M", "$1M–$5M", "$5M+"]
    private let strategyOptions = ["Single-Family", "Multifamily", "Mixed-Use", "Land/Development", "Not Sure Yet"]

    private var canSubmit: Bool {
        !fullName.isEmpty && !email.isEmpty && !phone.isEmpty && !investmentRange.isEmpty && !preferredStrategy.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                form

                if let error {
                    InlineErrorText(error: error)
                }

                Button {
                    submit()
                } label: {
                    if isSubmitting { InlineSpinner(tint: Theme.canvas) } else { Text("Submit Inquiry") }
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: !canSubmit))
                .disabled(!canSubmit || isSubmitting)
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Investor Inquiry")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prefillFromSession)
        .sheet(isPresented: $showingAuth) {
            AuthFlowView().environmentObject(session)
        }
        .background(conversationNavigationLink)
    }

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
            Text("TELL US ABOUT YOUR INVESTMENT CRITERIA")
                .font(Theme.Font.eyebrow(11))
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
            Text("Opportunities. Due diligence. Maximum returns.")
                .font(Theme.Font.headline(18))
                .foregroundStyle(Theme.ink)
        }
    }

    private var form: some View {
        VStack(spacing: Theme.Spacing.sm) {
            FormTextField(placeholder: "Full Name", text: $fullName)
            FormTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress)
            FormTextField(placeholder: "Phone Number", text: $phone, keyboardType: .phonePad)
            FormPickerField(placeholder: "Investment Range", options: investmentRangeOptions, selection: $investmentRange)
            FormPickerField(placeholder: "Preferred Strategy", options: strategyOptions, selection: $preferredStrategy)
            FormTextEditor(placeholder: "Additional Information (optional)", text: $additionalInfo)
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
                let response = try await session.apiClient.startInvestorInquiry(
                    fullName: fullName,
                    email: email,
                    phone: phone,
                    investmentRange: investmentRange,
                    preferredStrategy: preferredStrategy,
                    additionalInfo: additionalInfo
                )
                startedConversation = response.conversation
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    NavigationStack { InvestorInquiryFormView() }.environmentObject(SessionStore())
}
