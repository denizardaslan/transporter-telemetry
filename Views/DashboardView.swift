import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var sessions: [DrivingSession] = []
    
    var body: some View {
        List {
            Section("Statistics") {
                StatCard(title: "Total Sessions", value: "\(sessions.count)")
                StatCard(title: "Total Distance", value: String(format: "%.1f km", totalDistance))
                StatCard(title: "Max Speed", value: String(format: "%.1f km/h", maxSpeed))
            }
            
            Section("Recent Sessions") {
                if sessions.isEmpty {
                    Text("No recorded sessions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .onAppear {
            loadSessions()
        }
    }
    
    private var totalDistance: Double {
        sessions.reduce(0) { $0 + $1.totalDistance } / 1000.0  // Convert from meters to kilometers
    }
    
    private var maxSpeed: Double {
        sessions.reduce(0) { max($0, $1.maxSpeed) }
    }
    
    private func loadSessions() {
        do {
            sessions = try DataManager.shared.loadSessions()
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(.primary)
        }
    }
}

struct SessionRow: View {
    let session: DrivingSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(timeIntervalSince1970: session.session_start), style: .date)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack {
                    Label(
                        String(format: "%.1f km", session.totalDistance / 1000),
                        systemImage: "speedometer"
                    )
                    
                    Spacer()
                    
                    Label(
                        String(format: "%.1f km/h", session.maxSpeed),
                        systemImage: "gauge.with.dots.needle.bottom.50percent"
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(LocationManager())
    }
}