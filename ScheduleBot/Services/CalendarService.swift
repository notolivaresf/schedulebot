//
//  CalendarService.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import EventKit
import UIKit

final class CalendarService {

    private let eventStore = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            print("Calendar access request failed: \(error)")
            return false
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        return ekEvents.map { makeCalendarEvent(from: $0) }
    }

    private func makeCalendarEvent(from ekEvent: EKEvent) -> CalendarEvent {
        CalendarEvent(
            id: ekEvent.eventIdentifier,
            title: ekEvent.title ?? "No Title",
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isAllDay: ekEvent.isAllDay,
            location: ekEvent.location,
            calendarTitle: ekEvent.calendar.title,
            calendarColor: UIColor(cgColor: ekEvent.calendar.cgColor)
        )
    }
}
