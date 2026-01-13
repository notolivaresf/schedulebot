//
//  CalendarViewModel.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import Foundation

enum LoadingState: CustomStringConvertible, Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    case permissionDenied

    var description: String {
        switch self {
        case .idle: return "idle"
        case .loading: return "loading"
        case .loaded: return "loaded"
        case .error(let message): return "error(\(message))"
        case .permissionDenied: return "permissionDenied"
        }
    }
}

final class CalendarViewModel {

    private let calendarService: CalendarService

    private(set) var events: [CalendarEvent] = []
    private(set) var state: LoadingState = .idle

    var onStateChange: ((LoadingState) -> Void)?

    init(calendarService: CalendarService = CalendarService()) {
        self.calendarService = calendarService
    }

    func loadEvents() {
        state = .loading
        onStateChange?(.loading)

        Task {
            let granted = await calendarService.requestAccess()

            guard granted else {
                await MainActor.run {
                    state = .permissionDenied
                    onStateChange?(.permissionDenied)
                }
                return
            }

            let now = Date()
            let weekLater = Calendar.current.date(byAdding: .day, value: 7, to: now)!
            let fetchedEvents = calendarService.fetchEvents(from: now, to: weekLater)

            await MainActor.run {
                events = fetchedEvents
                state = .loaded
                onStateChange?(.loaded)
            }
        }
    }
}
