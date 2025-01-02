import SwiftUI

struct SessionsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var sessions: [DrivingSession] = []
    @State private var selectedSessions: Set<UUID> = []
    @State private var editMode: EditMode = .inactive
    @Environment(\.displayScale) private var displayScale
    
    var body: some View {
        List(selection: $selectedSessions) {
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
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                editMode = .active
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteSessions([session.id])
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    shareSessions([session.id])
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                            if editMode == .inactive {
                                selectedSessions.removeAll()
                            }
                        }
                    } label: {
                        Label(editMode == .active ? "Done" : "Select Items", 
                              systemImage: editMode == .active ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                    
                    if !selectedSessions.isEmpty {
                        Button(role: .destructive) {
                            deleteSessions(selectedSessions)
                        } label: {
                            Label("Delete Selected", systemImage: "trash")
                        }
                        
                        Button {
                            shareSessions(selectedSessions)
                        } label: {
                            Label("Share Selected", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
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
            // Load and sort sessions from newest to oldest
            sessions = try DataManager.shared.loadSessions()
                .sorted { $0.session_start > $1.session_start }
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
    
    private func deleteSessions(_ sessionIds: Set<UUID>) {
        do {
            for id in sessionIds {
                try DataManager.shared.deleteSession(id: id)
            }
            selectedSessions.removeAll()
            loadSessions()
        } catch {
            print("Error deleting sessions: \(error)")
        }
    }
    
    private func shareSessions(_ sessionIds: Set<UUID>) {
        do {
            let selectedSessions = sessions.filter { sessionIds.contains($0.id) }
            let jsonData = try JSONEncoder().encode(selectedSessions)
            
            // Create a temporary file with all selected sessions
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sessions_export.json")
            try jsonData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                if let presentedVC = rootViewController.presentedViewController {
                    presentedVC.present(activityVC, animated: true)
                } else {
                    rootViewController.present(activityVC, animated: true)
                }
            }
        } catch {
            print("Error sharing sessions: \(error)")
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
    
    private var locationDescription: String {
        let start = session.startLocation?.district ?? "Unknown"
        let end = session.endLocation?.district ?? "Unknown"
        return "\(start) → \(end)"
    }
    
    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: session.session_start)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formattedDate)
                    .font(.headline)
                Spacer()
                Text(session.driverName ?? "Unknown Driver")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(locationDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "ruler")
                    Text(String(format: "%.1f km", session.totalDistance / 1000))
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "speedometer")
                    Text(String(format: "%.0f km/h", session.maxSpeed))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SessionsView()
            .environmentObject(LocationManager())
    }
}