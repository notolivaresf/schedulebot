//
//  DayScheduleViewController.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import UIKit
import SwiftUI

class DayScheduleViewController: UIViewController {

    private let viewModel = DayScheduleViewModel()
    private let highlightColor: UIColor
    private var shareButton: UIBarButtonItem!

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = 44
        return table
    }()

    private var footerHostingController: UIHostingController<SelectedSlotsFooterView>?
    private var footerHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    init(highlightColor: UIColor = .systemBlue) {
        self.highlightColor = highlightColor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.highlightColor = .systemBlue
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        setupFooter()
        bindViewModel()
        viewModel.loadDay(Date())
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        let previousButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(previousDayTapped)
        )
        let nextButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(nextDayTapped)
        )
        navigationItem.leftBarButtonItems = [previousButton, nextButton]

        shareButton = UIBarButtonItem(
            title: "Share",
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        shareButton.isEnabled = false
        navigationItem.rightBarButtonItem = shareButton
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.register(TimeSlotCell.self, forCellReuseIdentifier: TimeSlotCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupFooter() {
        let footerView = SelectedSlotsFooterView(
            slots: [],
            highlightColor: Color(highlightColor)
        )
        let hostingController = UIHostingController(rootView: footerView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .systemBackground

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        let heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: hostingController.view.topAnchor),

            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            heightConstraint,
        ])

        footerHostingController = hostingController
        footerHeightConstraint = heightConstraint
    }

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            guard let self else { return }
            title = viewModel.formattedTitle
            shareButton.isEnabled = viewModel.hasAnySelection
            tableView.reloadData()
            updateFooter()
            scrollToDefaultTime()
        }
    }

    private func updateFooter() {
        let slots = viewModel.slotChipData()
        let hasSelections = !slots.isEmpty

        footerHostingController?.rootView = SelectedSlotsFooterView(
            slots: slots,
            highlightColor: Color(highlightColor)
        )

        let newHeight: CGFloat = hasSelections ? 56 : 0

        guard footerHeightConstraint?.constant != newHeight else { return }

        UIView.animate(withDuration: 0.25) {
            self.footerHeightConstraint?.constant = newHeight
            self.view.layoutIfNeeded()
        }
    }

    private func scrollToDefaultTime() {
        let eightAMSlotIndex = 16
        guard eightAMSlotIndex < viewModel.timeSlots.count else { return }
        tableView.scrollToRow(at: IndexPath(row: eightAMSlotIndex, section: 0), at: .top, animated: false)
    }

    // MARK: - Actions

    @objc private func previousDayTapped() {
        viewModel.goToPreviousDay()
    }

    @objc private func nextDayTapped() {
        viewModel.goToNextDay()
    }

    @objc private func shareTapped() {
        let selectedSlots = viewModel.allSelectedSlots()
        printSelectedSlots(selectedSlots)
    }

    private func printSelectedSlots(_ slots: [SelectedSlot]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        print("Selected slots:")
        var currentDate: Date?
        for slot in slots {
            if slot.date != currentDate {
                currentDate = slot.date
                print("  \(dateFormatter.string(from: slot.date)):")
            }
            print("    \(timeFormatter.string(from: slot.startTime)) - \(timeFormatter.string(from: slot.endTime))")
        }
    }
}

// MARK: - UITableViewDataSource

extension DayScheduleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.timeSlots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TimeSlotCell.reuseIdentifier, for: indexPath) as? TimeSlotCell else {
            return UITableViewCell()
        }

        let slot = viewModel.timeSlots[indexPath.row]
        let isSelected = viewModel.isSlotSelected(at: indexPath.row)
        cell.configure(with: slot, isSelected: isSelected, highlightColor: highlightColor)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension DayScheduleViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.toggleSelection(at: indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .none)
        shareButton.isEnabled = viewModel.hasAnySelection
        updateFooter()
    }
}
