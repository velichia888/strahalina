import SwiftUI

struct InquiriesInboxView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var state: LoadState<[Inquiry]> = .loading

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .loading:
                    LoadingStateView(label: "Loading inquiries…")
                case .failed(let error):
                    ErrorStateView(error: error) { Task { await load() } }
                case .loaded(let inquiries):
                    if inquiries.isEmpty {
                        EmptyStateView(title: "No inquiries yet", systemImage: "tray")
                    } else {
                        List(inquiries) { inquiry in
                            row(for: inquiry)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Inquiries")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func row(for inquiry: Inquiry) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(inquiry.listing?.title ?? "Listing")
                    .font(Theme.Font.body(13).weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                if inquiry.respondedAt != nil {
                    Text("Responded").font(Theme.Font.body(11)).foregroundStyle(Color(hex: "#2E7D32"))
                }
            }
            Text("\(inquiry.buyer.displayName) · \(inquiry.buyer.email)")
                .font(Theme.Font.body(12))
                .foregroundStyle(Theme.inkSoft)
            Text(inquiry.message)
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.ink)

            if inquiry.respondedAt == nil {
                Button("Mark Responded") {
                    Task { await respond(inquiry) }
                }
                .font(Theme.Font.body(12))
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func load() async {
        state = .loading
        do {
            let inquiries = try await session.apiClient.fetchInquiries()
            state = .loaded(inquiries)
        } catch {
            state = .failed(error)
        }
    }

    private func respond(_ inquiry: Inquiry) async {
        _ = try? await session.apiClient.respondToInquiry(id: inquiry.id)
        await load()
    }
}
