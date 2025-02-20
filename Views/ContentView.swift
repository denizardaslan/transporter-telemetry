import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var driverName: String = UserDefaults.standard.string(forKey: "DriverName") ?? ""
    @State private var selectedTyreType: TyreType = {
        if let savedType = UserDefaults.standard.string(forKey: "TyreType"),
           let tyreType = TyreType(rawValue: savedType) {
            return tyreType
        }
        return .summer
    }()
    @State private var carModel: String = UserDefaults.standard.string(forKey: "CarModel") ?? ""
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                RecordingView(
                    driverName: $driverName,
                    selectedTyreType: $selectedTyreType,
                    isRecording: locationManager.isRecording,
                    currentSpeed: locationManager.speed,
                    totalDistance: locationManager.currentDistance,
                    onStartRecording: {
                        locationManager.startRecording(
                            driverName: driverName,
                            tyreType: selectedTyreType
                        )
                    },
                    onStopRecording: {
                        locationManager.stopRecording()
                    }
                )
                .tabItem {
                    Label("Record", systemImage: "record.circle")
                }
                .tag(0)
                
                SessionsView()
                    .tabItem {
                        Label("Sessions", systemImage: "chart.bar")
                    }
                    .tag(1)
            }
            .environmentObject(locationManager)
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(
                        driverName: $driverName,
                        selectedTyreType: $selectedTyreType,
                        carModel: $carModel
                    )
                    .environmentObject(locationManager)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}