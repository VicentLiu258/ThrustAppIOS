import SwiftUI

struct CustomSpecSheet: View {
    var onSave: (String, String, Double, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themed) private var themed

    @State private var symbol = ""
    @State private var name = ""
    @State private var contract = "1"
    @State private var pip = "1.0"

    var body: some View {
        NavigationStack {
            Form {
                Section("Instrument") {
                    TextField("Symbol (e.g. BTCUSD)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                    TextField("Display Name", text: $name)
                }
                Section("Contract Specs") {
                    TextField("Contract Size", text: $contract)
                        .keyboardType(.decimalPad)
                    TextField("Pip Size", text: $pip)
                        .keyboardType(.decimalPad)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themed.bgApp)
            .navigationTitle("Create Custom Instrument")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !symbol.isEmpty, !name.isEmpty,
                              let c = Double(contract), let p = Double(pip), c > 0, p > 0 else { return }
                        onSave(symbol, name, c, p)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(symbol.isEmpty || name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .thrustTheme()
    }
}
