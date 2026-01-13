//
//  ViewController.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Phase 2 verification: test CalendarEvent struct
        let mockEvent = CalendarEvent(
            id: "test-123",
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            isAllDay: false,
            location: "Office",
            calendarTitle: "Work",
            calendarColor: .systemBlue
        )
        print("✓ Phase 2: Created event - \(mockEvent.title)")

        // Phase 3 & 4 verification: test CalendarService
        let calendarService = CalendarService()
        print("✓ Phase 3: Authorization status = \(calendarService.authorizationStatus.rawValue)")

        Task {
            let granted = await calendarService.requestAccess()
            print("✓ Phase 3: Calendar access granted = \(granted)")

            if granted {
                // Phase 4: Fetch events for the next 7 days
                let now = Date()
                let weekLater = Calendar.current.date(byAdding: .day, value: 7, to: now)!
                let events = calendarService.fetchEvents(from: now, to: weekLater)
                print("✓ Phase 4: Found \(events.count) events")
                for event in events {
                    print("  - \(event.title) (\(event.calendarTitle))")
                }
            }
        }
    }


}

