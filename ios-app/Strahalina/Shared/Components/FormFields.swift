import SwiftUI

/// Shared styled text field for the structured forms (Consultation,
/// Investor Inquiry) — matches the mockups' dark bordered input style.
struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.words)
            .foregroundStyle(Theme.ink)
            .padding(Theme.Spacing.sm)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                    .stroke(Theme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }
}

struct FormTextEditor: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(Theme.Font.body(15))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.horizontal, Theme.Spacing.sm + 4)
                    .padding(.vertical, Theme.Spacing.sm + 8)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Theme.ink)
                .frame(minHeight: 100)
                .padding(Theme.Spacing.xs)
        }
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }
}

/// Simple labeled picker styled to match the form fields, used for
/// "Investment Range" / "Preferred Strategy" dropdowns.
struct FormPickerField: View {
    let placeholder: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { selection = option }
            }
        } label: {
            HStack {
                Text(selection.isEmpty ? placeholder : selection)
                    .foregroundStyle(selection.isEmpty ? Theme.inkFaint : Theme.ink)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                    .stroke(Theme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
        }
    }
}
