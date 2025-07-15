import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Item
        let item = Item(context: viewContext)
        item.timestamp = Date()
        
        // Create a theme
        let workTheme = Theme(context: viewContext)
        workTheme.id = UUID()
        workTheme.name = "Work"
        
        // Create a tag
        let codingTag = Tag(context: viewContext)
        codingTag.id = UUID()
        codingTag.name = "Coding"
        codingTag.note = "Software development tasks"
        codingTag.theme = workTheme
        
        // Create multiple time entries for the single tag
        let calendar = Calendar.current
        let now = Date()
        
        // Time entry 1: Yesterday 9 AM - 12 PM
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let entry1Start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: yesterday)!
        let entry1Stop = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)!
        
        let timeEntry1 = TimeEntry(context: viewContext)
        timeEntry1.id = UUID()
        timeEntry1.start = entry1Start
        timeEntry1.stop = entry1Stop
        timeEntry1.friction = 2
        timeEntry1.tag = codingTag
        
        // Time entry 2: Yesterday 1 PM - 5 PM
        let entry2Start = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: yesterday)!
        let entry2Stop = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: yesterday)!
        
        let timeEntry2 = TimeEntry(context: viewContext)
        timeEntry2.id = UUID()
        timeEntry2.start = entry2Start
        timeEntry2.stop = entry2Stop
        timeEntry2.friction = 1
        timeEntry2.tag = codingTag
        
        // Time entry 3: Today 10 AM - 11:30 AM
        let entry3Start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
        let entry3Stop = calendar.date(bySettingHour: 11, minute: 30, second: 0, of: now)!
        
        let timeEntry3 = TimeEntry(context: viewContext)
        timeEntry3.id = UUID()
        timeEntry3.start = entry3Start
        timeEntry3.stop = entry3Stop
        timeEntry3.friction = 3
        timeEntry3.tag = codingTag
        
        // Time entry 4: Current ongoing session (started 2 hours ago)
        let entry4Start = calendar.date(byAdding: .hour, value: -2, to: now)!
        
        let timeEntry4 = TimeEntry(context: viewContext)
        timeEntry4.id = UUID()
        timeEntry4.start = entry4Start
        timeEntry4.stop = now
        timeEntry4.friction = 1
        timeEntry4.tag = codingTag
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ClockedIn")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
