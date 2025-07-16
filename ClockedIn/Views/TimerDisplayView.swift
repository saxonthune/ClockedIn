import SwiftUI

struct TimerDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timerManager) private var timerManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Timer Session Info
                if let session = timerManager.currentTimerSession {
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color(hex: session.tag.color ?? "#007AFF"))
                                .frame(width: 20, height: 20)
                            Text(session.tag.name ?? "Unknown")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Duration: \(session.formattedDuration)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Timer Display
                VStack(spacing: 20) {
                    Text(timerManager.timeString)
                        .font(.system(size: 64, weight: .light, design: .monospaced))
                        .foregroundColor(timerManager.isTimerRunning ? .primary : .secondary)
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 12)
                            .frame(width: 280, height: 280)
                        
                        Circle()
                            .trim(from: 0, to: timerManager.progress)
                            .stroke(
                                timerManager.isTimerRunning ? Color.blue : Color.secondary.opacity(0.5),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: timerManager.progress)
                    }
                }
                
                // Timer Controls
                HStack(spacing: 30) {
                    Button(action: {
                        timerManager.abortTimer()
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                            Text("Abort")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // If no active timer, dismiss this view
            if timerManager.currentTimerSession == nil {
                dismiss()
            }
        }
        .onReceive(timerManager.timerDidCompletePublisher) { completedSession in
            // Auto-dismiss when timer completes
            if completedSession != nil {
                dismiss()
            }
        }
    }
}

#Preview {
    TimerDisplayView()
}
