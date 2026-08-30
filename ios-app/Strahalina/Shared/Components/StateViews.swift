import SwiftUI

/// Every real API-backed screen in this app renders one of these three
/// states explicitly — nothing is silently swallowed.

struct LoadingStateView: View {
    var label: String = "Loading…"
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ProgressView()
            Text(label)
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }
}

struct EmptyStateView: View {
    let title: String
    var message: String? = nil
    var systemImage: String = "house"

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Theme.inkFaint)
            Text(title)
                .font(Theme.Font.body(16).weight(.semibold))
                .foregroundStyle(Theme.ink)
            if let message {
                Text(message)
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 160)
    }
}

struct ErrorStateView: View {
    let error: Error
    var onRetry: (() -> Void)? = nil

    private var message: String {
        (error as? APIError)?.userMessage ?? error.localizedDescription
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(Theme.danger)
            Text(message)
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if let onRetry {
                Button("Try again", action: onRetry)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 160)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Theme.dangerSoft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

struct InlineErrorText: View {
    let error: Error

    private var message: String {
        (error as? APIError)?.userMessage ?? error.localizedDescription
    }

    var body: some View {
        Text(message)
            .font(Theme.Font.body(13))
            .foregroundStyle(Theme.danger)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.dangerSoft)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }
}
