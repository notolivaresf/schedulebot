//
//  CalendarService.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import EventKit

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
}
