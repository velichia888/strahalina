import SwiftUI
import PhotosUI

/// Admin-only (gated by MainTabView showing this tab at all — the
/// backend enforces it independently via requireAdmin regardless).
struct CreateListingView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var type: ListingType = .property
    @State private var priceText = ""
    @State private var location = ""
    @State private var keyFacts: [KeyFact] = []
    @State private var newFactLabel = ""
    @State private var newFactValue = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isSubmitting = false
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                    Picker("Type", selection: $type) {
                        ForEach(ListingType.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    TextField("Price (USD)", text: $priceText)
                        .keyboardType(.numberPad)
                    TextField("Location", text: $location)
                }

                Section("Key Facts") {
                    ForEach(Array(keyFacts.enumerated()), id: \.offset) { index, fact in
                        HStack {
                            Text(fact.label).foregroundStyle(Theme.inkSoft)
                            Spacer()
                            Text(fact.value)
                        }
                    }
                    .onDelete { indices in
                        keyFacts.remove(atOffsets: indices)
                    }

                    HStack {
                        TextField("Label", text: $newFactLabel)
                        TextField("Value", text: $newFactValue)
                        Button("Add") {
                            guard !newFactLabel.isEmpty, !newFactValue.isEmpty else { return }
                            keyFacts.append(KeyFact(label: newFactLabel, value: newFactValue))
                            newFactLabel = ""
                            newFactValue = ""
                        }
                    }
                }

                Section("Photos") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: AppConfig.Limits.maxPhotosPerListing, matching: .images) {
                        Label("Select Photos (\(selectedPhotos.count))", systemImage: "photo.on.rectangle")
                    }
                }

                if let error {
                    InlineErrorText(error: error)
                }
            }
            .navigationTitle("New Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        InlineSpinner()
                    } else {
                        Button("Publish") { submit() }
                            .disabled(!canSubmit)
                    }
                }
            }
        }
    }

    private var canSubmit: Bool {
        !title.isEmpty && !description.isEmpty && !location.isEmpty && Int(priceText) != nil
    }

    private func submit() {
        guard let dollars = Int(priceText) else { return }
        error = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let listing = try await session.apiClient.createListing(CreateListingBody(
                    title: title,
                    description: description,
                    type: type,
                    priceCents: dollars * 100,
                    location: location,
                    keyFacts: keyFacts
                ))

                for item in selectedPhotos {
                    guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                    _ = try? await session.apiClient.uploadListingPhoto(
                        listingId: listing.id, imageData: data, filename: "photo.jpg", mimeType: "image/jpeg"
                    )
                }

                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
