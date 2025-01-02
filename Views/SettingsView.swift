import SwiftUI

struct SettingsView: View {
    @Binding var driverName: String
    @Binding var selectedTyreType: TyreType
    @Binding var carModel: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Driver Profile") {
                TextField("Driver Name", text: $driverName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: driverName) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "DriverName")
                    }
            }
            
            Section("Vehicle Settings") {
                TextField("Car Model", text: $carModel)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: carModel) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "CarModel")
                    }
                Picker("Tyre Type", selection: $selectedTyreType) {
                    ForEach(TyreType.allCases, id: \.self) { type in
                        Text("\(type.rawValue) \(type.emoji)")
                            .tag(type)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            driverName: Binding.constant("John Doe"),
            selectedTyreType: Binding.constant(.summer),
            carModel: Binding.constant("")
        )
    }
} 