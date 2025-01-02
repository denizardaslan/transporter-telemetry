import SwiftUI
import Charts

struct SpeedDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let speed: Double
}

struct SpeedGraphView: View {
    let dataPoints: [SpeedDataPoint]
    let maxSpeed: Double
    
    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Speed", point.speed)
            )
            .foregroundStyle(Color.green.opacity(0.8))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartYScale(domain: 0...max(maxSpeed, 120))
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(height: 200)
        .padding()
    }
}

#Preview {
    let now = Date()
    let points = (0..<60).map { i in
        SpeedDataPoint(
            timestamp: now.addingTimeInterval(TimeInterval(-i)),
            speed: Double.random(in: 0...100)
        )
    }
    return SpeedGraphView(dataPoints: points, maxSpeed: 100)
}
