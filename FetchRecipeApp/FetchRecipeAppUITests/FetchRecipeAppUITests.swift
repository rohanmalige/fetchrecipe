//
//  FetchRecipeUITests.swift
//  FetchRecipeUITests
//
//  Created by Rohan Malige on 5/28/25.
//

import XCTest

final class FetchRecipeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(
            firstCell.waitForExistence(timeout: 10),
            "At least one recipe cell should load"
        )

        let nameLabel = firstCell.staticTexts.element(boundBy: 0)
        XCTAssertTrue(
            nameLabel.exists && !nameLabel.label.isEmpty,
            "The first recipe cell should display a non-empty name"
        )
        // Use XCTAssert and related functions to verify your tests produce the correct results.

    }

    @MainActor
     func testSearchSuggestionsAndFiltering() throws {
         let app = XCUIApplication()
         app.launch()
         
         // Make sure the search field exists
         let searchField = app.textFields["Search cuisine"]
         XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field should be present at the top")

         // Type a partial cuisine name, e.g., "Brit"
         searchField.tap()
         searchField.typeText("Brit")
         
         // If suggestions appear, pick the first one
         let suggestion = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Brit")).firstMatch
         if suggestion.waitForExistence(timeout: 2) {
             suggestion.tap()
             // Now the list should filter to only British recipes
             let filteredCell = app.tables.cells.element(boundBy: 0)
             XCTAssertTrue(filteredCell.waitForExistence(timeout: 5), "Filtered list should show at least one British recipe")
             let cuisineLabel = filteredCell.staticTexts.element(boundBy: 1).label
             XCTAssertTrue(cuisineLabel.lowercased().contains("brit"), "Filtered cell's cuisine should contain 'Brit'")
         } else {
             // If no suggestion, verify “No cuisines found” message appears
             let noFound = app.staticTexts["No cuisines found"]
             XCTAssertTrue(noFound.exists, "No suggestions should show 'No cuisines found'")
         }
         
         // Clear the search text
         searchField.buttons["Clear text"].tap()
         XCTAssertTrue(searchField.value as? String == "", "Search field should be cleared")
     }

     @MainActor
     func testFavoritesNavigationAndPersistenceDuringSession() throws {
         let app = XCUIApplication()
         app.launch()
         
         // Wait for list to load and tap the first recipe's star button to favorite it
         let firstCell = app.tables.cells.element(boundBy: 0)
         XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "At least one recipe cell should load")
         
         // Find the star button inside the first cell
         let starButton = firstCell.buttons.element(matching: NSPredicate(format: "label == %@", "star"))
         if !starButton.exists {
             // Fallback: match any button with star image
             let fallback = firstCell.buttons.element(boundBy: 1)
             XCTAssertTrue(fallback.exists, "There should be a star button to favorite")
             fallback.tap()
         } else {
             starButton.tap()
         }

         // Tap the "Favorites" footer button to navigate
         let favoritesButton = app.buttons["Favorites"]
         XCTAssertTrue(favoritesButton.waitForExistence(timeout: 5), "Favorites button should exist in footer")
         favoritesButton.tap()
         
         // Verify the Favorites screen displays at least one entry
         let favNavBar = app.navigationBars["My Favorites"]
         XCTAssertTrue(favNavBar.waitForExistence(timeout: 5), "Should see 'My Favorites' screen")
         
         let favCell = app.tables.cells.element(boundBy: 0)
         XCTAssertTrue(favCell.exists, "At least one favorited recipe cell should show up")
         
         // Tap the favorited recipe to ensure it navigates to detail
         let favRecipeName = favCell.staticTexts.element(boundBy: 0).label
         favCell.tap()
         
         let detailNavBar = app.navigationBars["Details"]
         XCTAssertTrue(detailNavBar.waitForExistence(timeout: 5), "Detail page should appear for favorited recipe '\(favRecipeName)'")
         
         // Navigate back to favorites
         detailNavBar.buttons.element(boundBy: 0).tap()
         XCTAssertTrue(favNavBar.exists, "Should return to My Favorites after tapping back")
     }
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
