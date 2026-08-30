import SwiftUI

struct UpdatesFeedView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var state: LoadState<[Update]> = .loading
    @State private var showingCompose = false

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .loading:
                    LoadingStateView(label: "Loading updates…")
                case .failed(let error):
                    ErrorStateView(error: error) { Task { await load() } }
                case .loaded(let updates):
                    if updates.isEmpty {
                        EmptyStateView(title: "No updates yet", systemImage: "megaphone")
                    } else {
                        List(updates) { update in
                            UpdateRow(update: update)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Updates")
            .toolbar {
                if session.currentUser?.isAdmin == true {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCompose = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showingCompose) {
                ComposeUpdateView(onPosted: { Task { await load() } }).environmentObject(session)
            }
        }
    }

    private func load() async {
        state = .loading
        do {
            let updates = try await session.apiClient.fetchUpdates()
            state = .loaded(updates)
        } catch {
            state = .failed(error)
        }
    }
}

private struct UpdateRow: View {
    let update: Update

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(update.author.displayName)
                .font(Theme.Font.body(12).weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text(update.body)
                .font(Theme.Font.body(15))
                .foregroundStyle(Theme.ink)
            if let urlString = update.photoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color.clear
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
                .clipped()
            }
            Text(update.createdAt, style: .relative)
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    UpdatesFeedView().environmentObject(SessionStore())
}
