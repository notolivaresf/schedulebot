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
        view.backgroundColor = .systemBackground

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
        print("✓ Created event: \(mockEvent.title)")
    }
}

