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
    private var selectedSlotsByDate: [Date: Set<Int>] = [:]
    private var shareButton: UIBarButtonItem!

    private var currentDayKey: Date {
        Calendar.current.startOfDay(for: viewModel.currentDate)
    }

    private var currentDaySelections: Set<Int> {
        get { selectedSlotsByDate[currentDayKey] ?? [] }
        set { selectedSlotsByDate[currentDayKey] = newValue }
    }

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
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        print("Selected slots:")
        for (date, slotIndices) in selectedSlotsByDate.sorted(by: { $0.key < $1.key }) {
            guard !slotIndices.isEmpty else { continue }
            print("  \(dateFormatter.string(from: date)):")
            for index in slotIndices.sorted() {
                let slotStart = date.addingTimeInterval(Double(index) * 30 * 60)
                let slotEnd = slotStart.addingTimeInterval(30 * 60)
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                print("    \(timeFormatter.string(from: slotStart)) - \(timeFormatter.string(from: slotEnd))")
            }
        }
    }

    private func updateShareButtonState() {
        let hasAnySelection = selectedSlotsByDate.values.contains { !$0.isEmpty }
        shareButton.isEnabled = hasAnySelection
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
            self.tableView.reloadData()
            self.updateShareButtonState()
            self.scrollToDefaultTime()
        }
    }

    private func scrollToDefaultTime() {
        let eightAMSlotIndex = 16 // 8 hours × 2 slots per hour
        guard eightAMSlotIndex < viewModel.timeSlots.count else { return }
        let indexPath = IndexPath(row: eightAMSlotIndex, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
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
        let isSelected = currentDaySelections.contains(indexPath.row)
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
        var selections = currentDaySelections
        if selections.contains(indexPath.row) {
            selections.remove(indexPath.row)
        } else {
            selections.insert(indexPath.row)
        }
        currentDaySelections = selections

        // Reload the cell to update its appearance
        tableView.reloadRows(at: [indexPath], with: .none)
        updateShareButtonState()
    }
}
