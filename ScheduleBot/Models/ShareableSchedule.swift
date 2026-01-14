//
//  ShareableSchedule.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import Foundation

struct ShareableSchedule: Codable {
    let slots: [ShareableSlot]
    let timezone: String
}

struct ShareableSlot: Codable {
    let date: String
    let startTime: String
    let endTime: String

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    init(date: Date, startTime: Date, endTime: Date) {
        self.date = Self.dateFormatter.string(from: date)
        self.startTime = Self.timeFormatter.string(from: startTime)
        self.endTime = Self.timeFormatter.string(from: endTime)
    }
}
