import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var sessions: [DrivingSession] = []
    @State private var sessionToRename: DrivingSession?
    @State private var newSessionName: String = ""
    
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    sessionToRename = session
                                    newSessionName = session.name
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.orange)
                                
                                Button {
                                    shareSession(session)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .onAppear {
            loadSessions()
        }
        .sheet(item: $sessionToRename) { session in
            NavigationStack {
                Form {
                    TextField("Session Name", text: $newSessionName)
                }
                .navigationTitle("Rename Session")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        sessionToRename = nil
                    },
                    trailing: Button("Save") {
                        renameSession(session)
                        sessionToRename = nil
                    }
                )
            }
            .presentationDetents([.height(200)])
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
    
    private func shareSession(_ session: DrivingSession) {
        do {
            let jsonData = try JSONEncoder().encode(session)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(session.name).json")
            try jsonData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            print("Error sharing session: \(error)")
        }
    }
    
    private func deleteSession(_ session: DrivingSession) {
        do {
            try DataManager.shared.deleteSession(id: session.id)
            loadSessions()
        } catch {
            print("Error deleting session: \(error)")
        }
    }
    
    private func renameSession(_ session: DrivingSession) {
        do {
            var updatedSession = session
            updatedSession.name = newSessionName
            try DataManager.shared.updateSession(updatedSession)
            loadSessions()
        } catch {
            print("Error renaming session: \(error)")
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