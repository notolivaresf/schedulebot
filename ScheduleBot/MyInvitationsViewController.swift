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
    private var pollingTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Invitations"
        view.backgroundColor = .systemBackground

        setupTableView()
        loadInvitations()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPolling()
    }

    deinit {
        stopPolling()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        // Listen for app coming to foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        print("App became active - checking for invitation updates")
        loadInvitations()
        startPolling()
    }

    private func startPolling() {
        // Stop existing timer if any
        stopPolling()

        // Start new timer - check every 30 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            print("Polling for invitation updates...")
            self?.loadInvitations()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func loadInvitations() {
        // Get stored schedule IDs
        let storedIDs = UserDefaults.standard.array(forKey: "scheduleIDs") as? [Int] ?? []

        // Keep track of previous statuses
        let previousStatuses = Dictionary(uniqueKeysWithValues: invitations.map { ($0.id, $0.status) })

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
                // Check for newly confirmed invitations
                for schedule in fetchedInvitations {
                    if let previousStatus = previousStatuses[schedule.id],
                       previousStatus == "pending",
                       schedule.status == "confirmed" {
                        showConfirmationAlert(for: schedule)
                    }
                }

                invitations = fetchedInvitations.sorted { $0.id > $1.id } // Newest first
                tableView.reloadData()
            }
        }
    }

    private func showConfirmationAlert(for schedule: Schedule) {
        let slotsText = schedule.selectedSlots?.compactMap { slot in
            "\(slot.date) \(slot.startTime)"
        }.joined(separator: ", ") ?? "Unknown"

        let alert = UIAlertController(
            title: "Time Slot Confirmed!",
            message: "Your invitee selected:\n\(slotsText)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
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
