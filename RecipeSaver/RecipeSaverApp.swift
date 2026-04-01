//
//  RecipeSaverApp.swift
//  RecipeSaver
//
//  Created by John Zaw on 4/1/26.
//

import SwiftUI
import CoreData

@main
struct RecipeSaverApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
