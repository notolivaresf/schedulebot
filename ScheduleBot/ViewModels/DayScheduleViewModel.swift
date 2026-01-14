//
//  DayScheduleViewModel.swift
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

struct SelectedSlot {
    let date: Date
    let slotIndex: Int
    let startTime: Date
    let endTime: Date
}

final class DayScheduleViewModel {

    private let calendarService: CalendarService
    private let dayBuilder = DayBuilder()
    private let calendar = Calendar.current

    private(set) var timeSlots: [TimeSlot] = []
    private(set) var state: LoadingState = .idle
    private(set) var currentDate: Date = Date()
    private var selectedSlotsByDate: [Date: Set<Int>] = [:]

    var onUpdate: (() -> Void)?

    private static let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var formattedTitle: String {
        Self.titleFormatter.string(from: currentDate)
    }

    var hasAnySelection: Bool {
        selectedSlotsByDate.values.contains { !$0.isEmpty }
    }

    private var currentDayKey: Date {
        calendar.startOfDay(for: currentDate)
    }

    init(calendarService: CalendarService = CalendarService()) {
        self.calendarService = calendarService
    }

    // MARK: - Selection

    func isSlotSelected(at index: Int) -> Bool {
        selectedSlotsByDate[currentDayKey]?.contains(index) ?? false
    }

    func toggleSelection(at index: Int) {
        guard index < timeSlots.count,
              case .available = timeSlots[index].content else { return }

        var selections = selectedSlotsByDate[currentDayKey] ?? []
        if selections.contains(index) {
            selections.remove(index)
        } else {
            selections.insert(index)
        }
        selectedSlotsByDate[currentDayKey] = selections
    }

    func allSelectedSlots() -> [SelectedSlot] {
        var result: [SelectedSlot] = []
        for (date, indices) in selectedSlotsByDate.sorted(by: { $0.key < $1.key }) {
            for index in indices.sorted() {
                let startTime = date.addingTimeInterval(Double(index) * 30 * 60)
                let endTime = startTime.addingTimeInterval(30 * 60)
                result.append(SelectedSlot(date: date, slotIndex: index, startTime: startTime, endTime: endTime))
            }
        }
        return result
    }

    func slotChipData() -> [SlotChipData] {
        var result: [SlotChipData] = []

        for (date, indices) in selectedSlotsByDate.sorted(by: { $0.key < $1.key }) {
            let sortedIndices = indices.sorted()
            guard !sortedIndices.isEmpty else { continue }

            var rangeStart = sortedIndices[0]
            var rangeEnd = sortedIndices[0]

            for i in 1..<sortedIndices.count {
                let current = sortedIndices[i]
                if current == rangeEnd + 1 {
                    // Contiguous, extend the range
                    rangeEnd = current
                } else {
                    // Gap found, emit current range and start new one
                    result.append(makeChipData(date: date, startIndex: rangeStart, endIndex: rangeEnd))
                    rangeStart = current
                    rangeEnd = current
                }
            }

            // Emit final range
            result.append(makeChipData(date: date, startIndex: rangeStart, endIndex: rangeEnd))
        }

        return result
    }

    private func makeChipData(date: Date, startIndex: Int, endIndex: Int) -> SlotChipData {
        let startTime = date.addingTimeInterval(Double(startIndex) * 30 * 60)
        let endTime = date.addingTimeInterval(Double(endIndex + 1) * 30 * 60)
        return SlotChipData(
            id: "\(date.timeIntervalSince1970)-\(startIndex)-\(endIndex)",
            date: date,
            startTime: startTime,
            endTime: endTime
        )
    }

    // MARK: - Sharing

    func shareableSchedule() -> ShareableSchedule {
        let chips = slotChipData()
        let slots = chips.map { chip in
            ShareableSlot(date: chip.date, startTime: chip.startTime, endTime: chip.endTime)
        }
        let timezone = TimeZone.current.identifier
        return ShareableSchedule(slots: slots, timezone: timezone)
    }

    // MARK: - Navigation

    func goToPreviousDay() {
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { return }
        loadDay(previousDay)
    }

    func goToNextDay() {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { return }
        loadDay(nextDay)
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
