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
    private let dayBuilder = DayBuilder()

    private(set) var timeSlots: [TimeSlot] = []
    private(set) var state: LoadingState = .idle
    private(set) var currentDate: Date = Date()

    var onUpdate: (() -> Void)?

    init(calendarService: CalendarService = CalendarService()) {
        self.calendarService = calendarService
    }

    func loadDay(_ date: Date) {
        currentDate = date
        state = .loading
        onUpdate?()

        Task {
            let granted = await calendarService.requestAccess()

            guard granted else {
                await MainActor.run {
                    state = .permissionDenied
                    onUpdate?()
                }
                return
            }

            let dayStart = Calendar.current.startOfDay(for: date)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            let events = calendarService.fetchEvents(from: dayStart, to: dayEnd)
            let slots = dayBuilder.buildSlots(for: date, with: events)

            await MainActor.run {
                timeSlots = slots
                state = .loaded
                onUpdate?()
            }
        }
    }
}
