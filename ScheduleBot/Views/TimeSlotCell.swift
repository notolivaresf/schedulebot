//
//  TimeSlotCell.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import UIKit

final class TimeSlotCell: UITableViewCell {

    static let reuseIdentifier = "TimeSlotCell"

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let colorIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(timeLabel)
        contentView.addSubview(colorIndicator)
        contentView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 80),

            colorIndicator.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 12),
            colorIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 8),
            colorIndicator.heightAnchor.constraint(equalToConstant: 8),

            contentLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 8),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with slot: TimeSlot) {
        timeLabel.text = slot.timeString

        switch slot.content {
        case .available:
            contentLabel.text = "Available"
            contentLabel.textColor = .tertiaryLabel
            colorIndicator.backgroundColor = .clear
            contentView.backgroundColor = .systemBackground

        case .event(let event, _):
            contentLabel.text = event.title
            contentLabel.textColor = .label
            colorIndicator.backgroundColor = event.calendarColor
            contentView.backgroundColor = .secondarySystemBackground

        case .eventContinuation:
            contentLabel.text = ""
            colorIndicator.backgroundColor = .clear
            contentView.backgroundColor = .secondarySystemBackground

        case .bundled(let count, _):
            contentLabel.text = "(\(count) events)"
            contentLabel.textColor = .label
            colorIndicator.backgroundColor = .systemOrange
            contentView.backgroundColor = .secondarySystemBackground

        case .bundledContinuation:
            contentLabel.text = ""
            colorIndicator.backgroundColor = .clear
            contentView.backgroundColor = .secondarySystemBackground
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        contentLabel.text = nil
        colorIndicator.backgroundColor = .clear
        contentView.backgroundColor = .systemBackground
    }
}
