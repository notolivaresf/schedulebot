//
//  TimeSlot.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import Foundation

enum SlotContent: Equatable {
    case available
    case event(CalendarEvent, span: Int)
    case eventContinuation
    case bundled(count: Int, span: Int)
    case bundledContinuation

    static func == (lhs: SlotContent, rhs: SlotContent) -> Bool {
        switch (lhs, rhs) {
        case (.available, .available):
            return true
        case (.eventContinuation, .eventContinuation):
            return true
        case (.bundledContinuation, .bundledContinuation):
            return true
        case let (.event(e1, s1), .event(e2, s2)):
            return e1.id == e2.id && s1 == s2
        case let (.bundled(c1, s1), .bundled(c2, s2)):
            return c1 == c2 && s1 == s2
        default:
            return false
        }
    }
}

struct TimeSlot: Equatable {
    let startTime: Date
    let endTime: Date
    let content: SlotContent

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
}
