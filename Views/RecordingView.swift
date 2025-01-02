import SwiftUI
import UIKit

struct RecordingView: View {
    @Binding var driverName: String
    @Binding var selectedTyreType: TyreType
    let isRecording: Bool
    let currentSpeed: Double
    let totalDistance: Double  // This is in meters
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var speedPoints: [SpeedDataPoint] = []
    @State private var previousSpeed: Double = 0
    @State private var hasRecordedData: Bool = false
    
    @EnvironmentObject var locationManager: LocationManager
    
    private var speedColor: Color {
        if currentSpeed < previousSpeed {
            return .red
        } else {
            return .green
        }
    }
    
    private var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) / 60 % 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var distanceInKm: Double {
        totalDistance / 1000.0  // Convert meters to kilometers
    }
    
    private func updateIdleTimer() {
        if isRecording {
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Speed Display
                VStack(spacing: 0) {
                    Text("\(Int(currentSpeed))")
                        .font(.system(size: 96, weight: .bold))
                        .foregroundColor(speedColor)
                        .onChange(of: currentSpeed) { _ in
                            previousSpeed = currentSpeed
                        }
                    Text("km/h")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                
                // Distance
                VStack(spacing: 0) {
                    Text(String(format: "%.2f", distanceInKm))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("kilometers")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Timer Display
                if isRecording || hasRecordedData {
                    VStack(spacing: 0) {
                        Text(formattedElapsedTime)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                        Text("duration")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 40)  // Add space after duration
                }
                
                // Speed Graph
                if !speedPoints.isEmpty {
                    SpeedGraphView(
                        dataPoints: speedPoints,
                        maxSpeed: speedPoints.map(\.speed).max() ?? 120
                    )
                    .frame(height: 200)
                }
                
                // Recording Controls
                if locationManager.isRecording {
                    Button(action: {
                        locationManager.stopRecording()
                    }) {
                        Label("Stop Recording", systemImage: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                } else if locationManager.isWaitingForLocation {
                    Label("Getting Location...", systemImage: "location.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay {
                            ProgressView()
                                .tint(.blue)
                        }
                } else {
                    Button(action: {
                        locationManager.startRecording(driverName: driverName, tyreType: selectedTyreType)
                    }) {
                        Label("Start Recording", systemImage: "record.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Recording")
        .onAppear {
            updateIdleTimer()
        }
        .onDisappear {
            // Only re-enable idle timer if we're not recording
            if !isRecording {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .onChange(of: isRecording) { _ in
            updateIdleTimer()
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onChange(of: currentSpeed) { newSpeed in
            if isRecording {
                updateSpeedGraph(newSpeed)
            }
        }
    }
    
    private func startTimer() {
        elapsedTime = 0
        speedPoints.removeAll()
        hasRecordedData = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        hasRecordedData = true
    }
    
    private func updateSpeedGraph(_ speed: Double) {
        let now = Date()
        speedPoints.append(SpeedDataPoint(timestamp: now, speed: speed))
        
        // Keep only last 60 seconds of data
        let cutoffDate = now.addingTimeInterval(-60)
        speedPoints.removeAll { $0.timestamp < cutoffDate }
    }
}

#Preview {
    NavigationStack {
        RecordingView(
            driverName: Binding.constant("John Doe"),
            selectedTyreType: Binding.constant(.summer),
            isRecording: true,
            currentSpeed: 65.5,
            totalDistance: 1234.5,  // This is in meters
            onStartRecording: {},
            onStopRecording: {}
        )
        .environmentObject(LocationManager())
    }
}