//
//  ViewController.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import UIKit

class ViewController: UIViewController {

    private let viewModel = CalendarViewModel()
    private let highlightColor: UIColor
    private var selectedSlotIndices: Set<Int> = []
    private var shareButton: UIBarButtonItem!

    init(highlightColor: UIColor = .systemBlue) {
        self.highlightColor = highlightColor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.highlightColor = .systemBlue
        super.init(coder: coder)
    }

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = 44
        return table
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        bindViewModel()
        viewModel.loadDay(Date())
    }

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

    @objc private func previousDayTapped() {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.currentDate)!
        viewModel.loadDay(previousDay)
    }

    @objc private func nextDayTapped() {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.currentDate)!
        viewModel.loadDay(nextDay)
    }

    @objc private func shareTapped() {
        let selectedSlots = selectedSlotIndices.sorted().compactMap { index -> TimeSlot? in
            guard index < viewModel.timeSlots.count else { return nil }
            return viewModel.timeSlots[index]
        }

        print("Selected slots:")
        for slot in selectedSlots {
            print("  \(slot.timeString) - \(slot.startTime) to \(slot.endTime)")
        }
    }

    private func updateShareButtonState() {
        shareButton.isEnabled = !selectedSlotIndices.isEmpty
    }

    private func setupTableView() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.register(TimeSlotCell.self, forCellReuseIdentifier: TimeSlotCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.title = self.dateFormatter.string(from: self.viewModel.currentDate)
            self.selectedSlotIndices.removeAll()
            self.tableView.reloadData()
            self.updateShareButtonState()
        }
    }
}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.timeSlots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TimeSlotCell.reuseIdentifier, for: indexPath) as? TimeSlotCell else {
            return UITableViewCell()
        }

        let slot = viewModel.timeSlots[indexPath.row]
        let isSelected = selectedSlotIndices.contains(indexPath.row)
        cell.configure(with: slot, isSelected: isSelected, highlightColor: highlightColor)
        return cell
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let slot = viewModel.timeSlots[indexPath.row]

        // Only allow selection of available slots
        guard case .available = slot.content else { return }

        // Toggle selection
        if selectedSlotIndices.contains(indexPath.row) {
            selectedSlotIndices.remove(indexPath.row)
        } else {
            selectedSlotIndices.insert(indexPath.row)
        }

        // Reload the cell to update its appearance
        tableView.reloadRows(at: [indexPath], with: .none)
        updateShareButtonState()
    }
}
