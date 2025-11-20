import SwiftUI
@main
struct NotesJSONDemoApp: App {
    let persistenceController = PersistenceController.shared
    
        var body: some Scene {
            WindowGroup {
                NotesView_WithExportImport()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
}
