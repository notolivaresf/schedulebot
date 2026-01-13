//
//  CalendarEvent.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import UIKit

struct CalendarEvent {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let calendarTitle: String
    let calendarColor: UIColor
}
