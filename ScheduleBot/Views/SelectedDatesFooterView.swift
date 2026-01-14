//
//  SelectedDatesFooterView.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import SwiftUI

struct SlotChipData: Identifiable {
    let id: String
    let date: Date
    let startTime: Date
    let endTime: Date

    var formattedLabel: String {
        let dateStr = Self.dateFormatter.string(from: date)
        let startStr = Self.timeFormatter.string(from: startTime)

        // Show only start time: "Jan 13 9:00 AM"
        return "\(dateStr) \(startStr)"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

struct SelectedSlotChip: View {
    let slot: SlotChipData
    let color: Color

    var body: some View {
        Text(slot.formattedLabel)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}

struct SelectedSlotsFooterView: View {
    let slots: [SlotChipData]
    let highlightColor: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(slots) { slot in
                    SelectedSlotChip(slot: slot, color: highlightColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    VStack {
        Spacer()
        SelectedSlotsFooterView(
            slots: [
                SlotChipData(id: "1", date: Date(), startTime: Date(), endTime: Date().addingTimeInterval(1800)),
                SlotChipData(id: "2", date: Date(), startTime: Date().addingTimeInterval(1800), endTime: Date().addingTimeInterval(3600)),
                SlotChipData(id: "3", date: Date().addingTimeInterval(86400), startTime: Date().addingTimeInterval(86400), endTime: Date().addingTimeInterval(86400 + 1800))
            ],
            highlightColor: .blue
        )
    }
}
