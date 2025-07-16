import SwiftUI

struct TimerDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var timerManager = TimerManager.shared
    @State private var showingEndConfirmation = false
    
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
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Started")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(timeFormatter.string(from: session.startTime))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Ends")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(timeFormatter.string(from: endTime))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
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
            .safeAreaInset(edge: .bottom) {
                // Fixed End Timer button at bottom
                Button(action: {
                    showingEndConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Timer")
                    }
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .confirmationDialog("End Timer", isPresented: $showingEndConfirmation) {
            Button("End Timer", role: .destructive) {
                timerManager.abortTimer()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Ending the timer will create a new session. You can create a new timer later.")
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
    
    // MARK: - Computed Properties
    
    private var endTime: Date {
        guard let session = timerManager.currentTimerSession else { return Date() }
        return session.startTime.addingTimeInterval(session.duration)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    // Create a mock timer session for preview
    let mockTimerManager = TimerManager.shared
    let mockTag = Tag(context: PersistenceController.preview.container.viewContext)
    mockTag.name = "Work"
    mockTag.color = "#007AFF"
    mockTag.note = "Focus session"
    
    // Start a mock timer
    mockTimerManager.startTimer(
        duration: 25 * 60, // 25 minutes
        tag: mockTag,
        context: PersistenceController.preview.container.viewContext
    )
    
    return TimerDisplayView()
}
