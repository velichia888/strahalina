import SwiftUI
import PhotosUI

struct ComposeUpdateView: View {
    var onPosted: () -> Void

    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var body_ = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isSubmitting = false
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                TextEditor(text: $body_)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Theme.ink)
                    .frame(minHeight: 120)
                    .padding(Theme.Spacing.xs)
                    .background(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                            .stroke(Theme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(imageData == nil ? "Add Photo (optional)" : "Photo Selected", systemImage: "photo")
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        imageData = try? await newItem?.loadTransferable(type: Data.self)
                    }
                }

                if let error {
                    InlineErrorText(error: error)
                }

                Button {
                    submit()
                } label: {
                    if isSubmitting { InlineSpinner(tint: Theme.canvas) } else { Text("Post Update") }
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: body_.isEmpty))
                .disabled(body_.isEmpty || isSubmitting)

                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("New Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                _ = try await session.apiClient.createUpdate(
                    body: body_,
                    listingId: nil,
                    imageData: imageData,
                    filename: imageData != nil ? "update.jpg" : nil,
                    mimeType: imageData != nil ? "image/jpeg" : nil
                )
                onPosted()
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
