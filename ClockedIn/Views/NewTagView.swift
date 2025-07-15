import SwiftUI
import CoreData

struct NewTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newTagName: String
    @Binding var newTagNote: String
    @Binding var newTagColor: String
    let onSave: () -> Void
    
    private let colorOptions = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#32ADE6", "#5856D6",
        "#AF52DE", "#FF2D92", "#8E8E93", "#000000"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tag Details") {
                    TextField("Tag Name", text: $newTagName)
                    TextField("Note (optional)", text: $newTagNote, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(colorOptions, id: \.self) { colorHex in
                            Button(action: {
                                newTagColor = colorHex
                            }) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: colorHex))
                                    .frame(height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                newTagColor == colorHex ? Color.primary : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(newTagName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NewTagView(
        newTagName: .constant("Sample Tag"),
        newTagNote: .constant("Sample note"),
        newTagColor: .constant("#007AFF"),
        onSave: {}
    )
}
