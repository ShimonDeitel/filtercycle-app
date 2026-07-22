import SwiftUI

struct AddFilterView: View {
    @EnvironmentObject private var store: FilterStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: FilterCategory = .hvac
    @State private var customIntervalDays: String = ""
    @State private var lastChangedDate: Date = Date()

    private var isCustom: Bool { category == .custom }

    private var resolvedIntervalDays: Int? {
        guard isCustom else { return nil }
        return Int(customIntervalDays)
    }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if isCustom {
            return (Int(customIntervalDays) ?? 0) > 0
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Filter") {
                    TextField("Name (e.g. Kitchen HVAC)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(FilterCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section("Replacement interval") {
                    if isCustom {
                        TextField("Days between changes", text: $customIntervalDays)
                            .keyboardType(.numberPad)
                    } else {
                        HStack {
                            Text("Typical interval")
                            Spacer()
                            Text("\(category.defaultIntervalDays) days")
                                .foregroundStyle(FCColor.slate)
                        }
                    }
                }

                Section("Last changed") {
                    DatePicker("Last changed", selection: $lastChangedDate, in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .scrollContentBackground(.hidden)
            .background(FCColor.cream)
            .dismissKeyboardOnTap()
            .navigationTitle("Add Filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addFilter(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category,
                            intervalDays: resolvedIntervalDays,
                            lastChangedDate: lastChangedDate
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
