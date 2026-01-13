//
//  SelectedDatesFooterView.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import SwiftUI

struct DateSelection: Identifiable {
    let id: Date
    let date: Date
    let slotCount: Int

    var formattedDate: String {
        Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

struct SelectedDateChip: View {
    let selection: DateSelection
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(selection.formattedDate)
                .font(.subheadline)
                .fontWeight(.medium)
            Text("(\(selection.slotCount))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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

struct SelectedDatesFooterView: View {
    let selections: [DateSelection]
    let highlightColor: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selections) { selection in
                    SelectedDateChip(selection: selection, color: highlightColor)
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
        SelectedDatesFooterView(
            selections: [
                DateSelection(id: Date(), date: Date(), slotCount: 3),
                DateSelection(id: Date().addingTimeInterval(86400), date: Date().addingTimeInterval(86400), slotCount: 2),
                DateSelection(id: Date().addingTimeInterval(172800), date: Date().addingTimeInterval(172800), slotCount: 5)
            ],
            highlightColor: .blue
        )
    }
}
