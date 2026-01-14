//
//  Schedule.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 14/01/26.
//

import Foundation

struct Schedule: Codable {
    let id: Int
    let slots: [ShareableSlot]
    let timezone: String
    let status: String
    let selectedSlots: [ShareableSlot]?

    enum CodingKeys: String, CodingKey {
        case id, slots, timezone, status
        case selectedSlots = "selected_slots"
    }
}
