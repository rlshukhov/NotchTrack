//
//  TimeEntry.swift
//  NotchTrack
//
//  Created by Lane Shukhov on 2024/10/21.
//

import Foundation

struct TimeEntry: Codable, Identifiable {
    let id: UUID
    var startTime: Date
    var description: String
    
    init(id: UUID = UUID(), startTime: Date = Date(), description: String = "") {
        self.id = id
        self.startTime = startTime
        self.description = description
    }
}
