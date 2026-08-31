import SwiftUI

/// One real, admin-authored feed covers the mockup's "Market Insights"
/// and "Content Hub" sections — no separate fabricated content system,
/// just a category filter over real posts (see UpdateCategory).
struct UpdatesFeedView: View {
    /// Presets which tab is selected when pushed from elsewhere (e.g.
    /// Home's "View All Insights" -> Market Insights tab directly).
    var initialCategory: UpdateCategory?

    @EnvironmentObject private var session: SessionStore
    @State private var state: LoadState<[Update]> = .loading
    @State private var category: UpdateCategory?
    @State private var showingCompose = false

    init(initialCategory: UpdateCategory? = nil) {
        self.initialCategory = initialCategory
        _category = State(initialValue: initialCategory)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryTabs

                Group {
                    switch state {
                    case .loading:
                        LoadingStateView(label: "Loading…")
                    case .failed(let error):
                        ErrorStateView(error: error) { Task { await load() } }
                    case .loaded(let updates):
                        if updates.isEmpty {
                            EmptyStateView(
                                title: emptyTitle,
                                message: "Check back soon.",
                                systemImage: "megaphone"
                            )
                        } else {
                            List(updates) { update in
                                UpdateRow(update: update)
                                    .listRowBackground(Theme.canvas)
                                    .listRowSeparator(.hidden)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .background(Theme.canvas)
                        }
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
            .onChange(of: category) { _ in
                Task { await load() }
            }
            .sheet(isPresented: $showingCompose) {
                ComposeUpdateView(defaultCategory: category ?? .general, onPosted: { Task { await load() } })
                    .environmentObject(session)
            }
        }
    }

    private var emptyTitle: String {
        switch category {
        case .marketInsight: return "No market insights yet"
        case .content: return "No content yet"
        case .general, .none: return "No updates yet"
        }
    }

    private var categoryTabs: some View {
        HStack(spacing: Theme.Spacing.sm) {
            tabChip(title: "All", isSelected: category == nil) { category = nil }
            tabChip(title: UpdateCategory.marketInsight.displayName, isSelected: category == .marketInsight) { category = .marketInsight }
            tabChip(title: UpdateCategory.content.displayName, isSelected: category == .content) { category = .content }
        }
        .padding(Theme.Spacing.md)
    }

    private func tabChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.body(13).weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.accent : Theme.surface)
                .foregroundStyle(isSelected ? Theme.canvas : Theme.inkSoft)
                .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.borderSubtle, lineWidth: 1))
                .clipShape(Capsule())
        }
    }

    private func load() async {
        state = .loading
        do {
            let updates = try await session.apiClient.fetchUpdates(category: category)
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
            if update.category != .general {
                Text(update.category.displayName.uppercased())
                    .font(Theme.Font.eyebrow(10))
                    .tracking(1)
                    .foregroundStyle(Theme.accent)
            }
            Text(update.author.displayName)
                .font(Theme.Font.eyebrow(11))
                .tracking(1)
                .foregroundStyle(Theme.inkFaint)
            Text(update.body)
                .font(Theme.Font.body(15))
                .foregroundStyle(Theme.ink)
            if let videoUrlString = update.externalVideoUrl, let videoUrl = URL(string: videoUrlString) {
                Link(destination: videoUrl) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text("Watch")
                    }
                    .font(Theme.Font.body(13).weight(.semibold))
                    .foregroundStyle(Theme.accent)
                }
            }
            Text(update.createdAt, style: .relative)
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

#Preview {
    UpdatesFeedView().environmentObject(SessionStore())
}
