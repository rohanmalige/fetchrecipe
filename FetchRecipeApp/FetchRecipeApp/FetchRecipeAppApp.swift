//
//  FetchRecipeApp.swift
//  FetchRecipe
//
//  Created by Rohan Malige on 5/28/25.
//

import SwiftUI
import SwiftData

@main
struct FetchRecipeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RecipeListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
