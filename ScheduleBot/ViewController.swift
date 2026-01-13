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

        // Phase 3 verification: test CalendarService permission request
        let calendarService = CalendarService()
        print("Current authorization status: \(calendarService.authorizationStatus.rawValue)")

        Task {
            let granted = await calendarService.requestAccess()
            print("✓ Calendar access granted: \(granted)")
        }
    }
}

