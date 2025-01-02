import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var settings = try? DataManager.shared.loadSettings()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current speed display
                Text(settings?.formatSpeed(locationManager.speed) ?? "0 km/h")
                    .font(.system(size: 64, weight: .bold))
                
                // Recording controls
                if locationManager.isRecording {
                    Button(action: {
                        locationManager.stopRecording()
                    }) {
                        Label("Stop Recording", systemImage: "stop.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: {
                        guard let settings = settings else { return }
                        locationManager.startRecording(
                            driverName: settings.driverName,
                            tyreType: settings.tyreType
                        )
                    }) {
                        Label("Start Recording", systemImage: "record.circle")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Transporter Telemetry")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: $settings)
        }
    }
} 