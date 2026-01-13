//
//  DayBuilder.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import Foundation

struct DayBuilder {

    private let calendar = Calendar.current
    private let slotDuration: TimeInterval = 30 * 60 // 30 minutes

    func buildSlots(for date: Date, with events: [CalendarEvent]) -> [TimeSlot] {
        let dayStart = calendar.startOfDay(for: date)
        var slots = createEmptySlots(startingFrom: dayStart)

        // Group events by which slots they occupy
        var slotEventMap: [Int: [CalendarEvent]] = [:]

        for event in events {
            let eventSlots = slotsOccupied(by: event, dayStart: dayStart)
            for slotIndex in eventSlots {
                if slotIndex >= 0 && slotIndex < 48 {
                    slotEventMap[slotIndex, default: []].append(event)
                }
            }
        }

        // Process each slot
        var processedEventIds: Set<String> = []

        for slotIndex in 0..<48 {
            guard let eventsInSlot = slotEventMap[slotIndex], !eventsInSlot.isEmpty else {
                continue // Slot remains available
            }

            if eventsInSlot.count == 1 {
                let event = eventsInSlot[0]

                if processedEventIds.contains(event.id) {
                    // This is a continuation of an already-started event
                    slots[slotIndex] = TimeSlot(
                        startTime: slots[slotIndex].startTime,
                        endTime: slots[slotIndex].endTime,
                        content: .eventContinuation
                    )
                } else {
                    // This is the start of an event
                    let span = calculateSpan(for: event, startingAt: slotIndex, dayStart: dayStart)
                    slots[slotIndex] = TimeSlot(
                        startTime: slots[slotIndex].startTime,
                        endTime: slots[slotIndex].endTime,
                        content: .event(event, span: span)
                    )
                    processedEventIds.insert(event.id)
                }
            } else {
                // Multiple events overlap in this slot
                let newEventIds = eventsInSlot.filter { !processedEventIds.contains($0.id) }

                if !newEventIds.isEmpty {
                    // Start of bundled events
                    let span = calculateBundledSpan(for: eventsInSlot, startingAt: slotIndex, dayStart: dayStart)
                    slots[slotIndex] = TimeSlot(
                        startTime: slots[slotIndex].startTime,
                        endTime: slots[slotIndex].endTime,
                        content: .bundled(count: eventsInSlot.count, span: span)
                    )
                    for event in eventsInSlot {
                        processedEventIds.insert(event.id)
                    }
                } else {
                    // Continuation of bundled events
                    slots[slotIndex] = TimeSlot(
                        startTime: slots[slotIndex].startTime,
                        endTime: slots[slotIndex].endTime,
                        content: .bundledContinuation
                    )
                }
            }
        }

        return slots
    }

    private func createEmptySlots(startingFrom dayStart: Date) -> [TimeSlot] {
        (0..<48).map { index in
            let startTime = dayStart.addingTimeInterval(Double(index) * slotDuration)
            let endTime = startTime.addingTimeInterval(slotDuration)
            return TimeSlot(startTime: startTime, endTime: endTime, content: .available)
        }
    }

    private func slotsOccupied(by event: CalendarEvent, dayStart: Date) -> [Int] {
        let dayEnd = dayStart.addingTimeInterval(24 * 60 * 60)

        // Clamp event to this day
        let effectiveStart = max(event.startDate, dayStart)
        let effectiveEnd = min(event.endDate, dayEnd)

        guard effectiveStart < effectiveEnd else { return [] }

        let startSlot = Int(effectiveStart.timeIntervalSince(dayStart) / slotDuration)
        let endSlot = Int(ceil(effectiveEnd.timeIntervalSince(dayStart) / slotDuration))

        return Array(startSlot..<endSlot)
    }

    private func calculateSpan(for event: CalendarEvent, startingAt slotIndex: Int, dayStart: Date) -> Int {
        let slots = slotsOccupied(by: event, dayStart: dayStart)
        guard let firstSlot = slots.first, firstSlot == slotIndex else { return 1 }
        return slots.count
    }

    private func calculateBundledSpan(for events: [CalendarEvent], startingAt slotIndex: Int, dayStart: Date) -> Int {
        // Find the maximum extent of all overlapping events
        var maxEndSlot = slotIndex
        for event in events {
            let slots = slotsOccupied(by: event, dayStart: dayStart)
            if let lastSlot = slots.last {
                maxEndSlot = max(maxEndSlot, lastSlot)
            }
        }
        return maxEndSlot - slotIndex + 1
    }
}
