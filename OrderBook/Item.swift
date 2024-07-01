//
//  Item.swift
//  OrderBook
//
//  Created by Jordan Christensen on 6/30/24.
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
