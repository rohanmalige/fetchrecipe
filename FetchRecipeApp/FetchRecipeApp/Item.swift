//
//  Item.swift
//  FetchRecipe
//
//  Created by Rohan Malige on 5/28/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
