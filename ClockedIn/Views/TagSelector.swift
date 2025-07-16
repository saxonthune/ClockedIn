import SwiftUI
import CoreData

struct TagSelector: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    @Binding var selectedTag: Tag?
    @State private var showingNewTagSheet = false
    
    // For creating new tag
    @State private var newTagName = ""
    @State private var newTagNote = ""
    @State private var newTagColor = "#007AFF"
    
    var body: some View {
        HStack {
            Menu {
                Button("Select a tag") {
                    selectedTag = nil
                }
                ForEach(tags, id: \.self) { tag in
                    Button(action: {
                        selectedTag = tag
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.color ?? "#999999"))
                                .frame(width: 12, height: 12)
                            Text(tag.name ?? "")
                        }
                    }
                }
            } label: {
                HStack {
                    if let selectedTag = selectedTag {
                        Circle()
                            .fill(Color(hex: selectedTag.color ?? "#999999"))
                            .frame(width: 16, height: 16)
                        Text(selectedTag.name ?? "")
                            .foregroundColor(.primary)
                    } else {
                        Text("Select a tag")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            Button("New Tag") {
                showingNewTagSheet = true
            }
            .buttonStyle(.borderless)
        }
        .sheet(isPresented: $showingNewTagSheet) {
            NewTagView(
                newTagName: $newTagName,
                newTagNote: $newTagNote,
                newTagColor: $newTagColor,
                onSave: createNewTag
            )
        }
    }
    
    private func createNewTag() {
        withAnimation {
            let newTag = Tag(context: viewContext)
            newTag.id = UUID()
            newTag.name = newTagName
            newTag.note = newTagNote
            newTag.color = newTagColor
            
            do {
                try viewContext.save()
                selectedTag = newTag
                newTagName = ""
                newTagNote = ""
                newTagColor = "#007AFF"
                showingNewTagSheet = false
            } catch {
                let nsError = error as NSError
                print("Error creating new tag: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    TagSelector(selectedTag: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
