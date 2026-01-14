//
//  MyInvitationsViewController.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 14/01/26.
//

import UIKit

final class MyInvitationsViewController: UIViewController {

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(InvitationCell.self, forCellReuseIdentifier: InvitationCell.reuseIdentifier)
        return table
    }()

    private let scheduleService = ScheduleService()
    private var invitations: [Schedule] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Invitations"
        view.backgroundColor = .systemBackground

        setupTableView()
        loadInvitations()
    }

    private func loadInvitations() {
        // Get stored schedule IDs
        let storedIDs = UserDefaults.standard.array(forKey: "scheduleIDs") as? [Int] ?? []

        Task {
            var fetchedInvitations: [Schedule] = []

            for id in storedIDs {
                do {
                    let schedule = try await scheduleService.fetchSchedule(id: id)
                    fetchedInvitations.append(schedule)
                } catch {
                    print("Failed to fetch schedule \(id): \(error)")
                }
            }

            await MainActor.run {
                invitations = fetchedInvitations.sorted { $0.id > $1.id } // Newest first
                tableView.reloadData()
            }
        }
    }

    private func setupTableView() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: - UITableViewDataSource

extension MyInvitationsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invitations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InvitationCell.reuseIdentifier, for: indexPath) as? InvitationCell else {
            return UITableViewCell()
        }

        let invitation = invitations[indexPath.row]
        cell.configure(with: invitation)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MyInvitationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Show invitation details
    }
}

// MARK: - InvitationCell

final class InvitationCell: UITableViewCell {

    static let reuseIdentifier = "InvitationCell"

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(dateLabel)
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),

            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with schedule: Schedule) {
        // Show first slot date
        if let firstSlot = schedule.slots.first {
            dateLabel.text = "Invitation #\(schedule.id)"
        } else {
            dateLabel.text = "Invitation #\(schedule.id)"
        }

        // Show status with color
        statusLabel.text = schedule.status.capitalized

        switch schedule.status {
        case "pending":
            statusLabel.textColor = .systemOrange
        case "confirmed":
            statusLabel.textColor = .systemGreen
        case "rejected":
            statusLabel.textColor = .systemRed
        default:
            statusLabel.textColor = .secondaryLabel
        }
    }
}
