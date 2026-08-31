import SwiftUI

/// Chat thread for one conversation. Reused both from the Inbox
/// (existing conversation) and from ListingDetailView, where starting
/// the very first message creates the conversation server-side and
/// this view then just loads its (now non-empty) message list.
struct ConversationDetailView: View {
    let conversation: Conversation

    @EnvironmentObject private var session: SessionStore
    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var draft = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingStateView(label: "Loading conversation…")
                    .frame(maxHeight: .infinity)
            } else if let loadError {
                ErrorStateView(error: loadError) { Task { await load() } }
                    .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ForEach(messages) { message in
                                bubble(message).id(message.id)
                            }
                        }
                        .padding(Theme.Spacing.md)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                        }
                    }
                }
            }

            composer
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(conversation.listing?.title ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func bubble(_ message: Message) -> some View {
        let isMine = message.senderId == session.currentUser?.id
        return HStack {
            if isMine { Spacer(minLength: 40) }
            Text(message.body)
                .font(Theme.Font.body(14))
                // Dark text on the gold "mine" bubble — Theme.ink is a
                // light cream in this dark theme, and white would have
                // even less contrast against gold than against surface.
                .foregroundStyle(isMine ? Theme.canvas : Theme.ink)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 8)
                .background(isMine ? Theme.accent : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
            if !isMine { Spacer(minLength: 40) }
        }
    }

    private var composer: some View {
        HStack(spacing: Theme.Spacing.xs) {
            TextField("Message…", text: $draft, axis: .vertical)
                .foregroundStyle(Theme.ink)
                .padding(Theme.Spacing.xs)
                .background(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                        .stroke(Theme.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))

            Button {
                send()
            } label: {
                if isSending {
                    InlineSpinner(tint: Theme.accent)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.inkFaint : Theme.accent)
                }
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.canvas)
    }

    private func load() async {
        isLoading = true
        loadError = nil
        do {
            messages = try await session.apiClient.fetchMessages(conversationId: conversation.id)
            try? await session.apiClient.markConversationRead(conversationId: conversation.id)
        } catch {
            loadError = error
        }
        isLoading = false
    }

    private func send() {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        draft = ""
        isSending = true
        Task {
            defer { isSending = false }
            do {
                let message = try await session.apiClient.sendMessage(conversationId: conversation.id, body: body)
                messages.append(message)
            } catch {
                // Restore the draft so the user doesn't lose their message on failure.
                draft = body
            }
        }
    }
}
