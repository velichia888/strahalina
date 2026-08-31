import SwiftUI

/// Conversation list — GET /conversations returns role-appropriate
/// results already: buyers get only their own threads, admins get
/// every conversation across every listing (no per-listing "seller",
/// so any admin can see/reply to any thread).
struct InboxView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var state: LoadState<[Conversation]> = .loading

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .loading:
                    LoadingStateView(label: "Loading messages…")
                case .failed(let error):
                    ErrorStateView(error: error) { Task { await load() } }
                case .loaded(let conversations):
                    if conversations.isEmpty {
                        emptyState
                    } else {
                        list(conversations)
                    }
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Messages")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(Theme.inkFaint)
            Text("No conversations yet")
                .font(Theme.Font.headline(16))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func list(_ conversations: [Conversation]) -> some View {
        List(conversations) { conversation in
            NavigationLink {
                ConversationDetailView(conversation: conversation)
                    .environmentObject(session)
            } label: {
                row(conversation)
            }
            .listRowBackground(Theme.surface)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
    }

    private func row(_ conversation: Conversation) -> some View {
        let isUnread = conversation.lastMessage.map { message in
            message.senderId != session.currentUser?.id && message.readAt == nil
        } ?? false

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.listing?.title ?? "Listing")
                    .font(Theme.Font.body(15).weight(isUnread ? .bold : .regular))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if isUnread {
                    Circle().fill(Theme.accent).frame(width: 8, height: 8)
                }
            }
            if session.currentUser?.isAdmin == true, let buyer = conversation.buyer {
                Text(buyer.displayName)
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            if let lastMessage = conversation.lastMessage {
                Text(lastMessage.body)
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func load() async {
        state = .loading
        do {
            let conversations = try await session.apiClient.fetchConversations()
            state = .loaded(conversations)
        } catch {
            state = .failed(error)
        }
    }
}
