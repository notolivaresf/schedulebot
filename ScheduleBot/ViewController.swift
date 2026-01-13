//
//  ViewController.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import UIKit

class ViewController: UIViewController {

    private let viewModel = CalendarViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Phase 5: Use ViewModel to manage state
        viewModel.onStateChange = { [weak self] state in
            print("✓ Phase 5: State changed to \(state)")

            if state == .loaded {
                guard let self = self else { return }
                print("✓ Phase 5: Loaded \(self.viewModel.events.count) events")
                for event in self.viewModel.events {
                    print("  - \(event.title) (\(event.calendarTitle))")
                }
            }
        }

        viewModel.loadEvents()
    }


}

