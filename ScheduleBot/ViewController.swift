//
//  ViewController.swift
//  ScheduleBot
//
//  Created by Fernando Olivares on 13/01/26.
//

import UIKit

class ViewController: UIViewController {

    private let viewModel = CalendarViewModel()

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
        navigationItem.rightBarButtonItems = [nextButton, previousButton]
    }

    @objc private func previousDayTapped() {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.currentDate)!
        viewModel.loadDay(previousDay)
    }

    @objc private func nextDayTapped() {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.currentDate)!
        viewModel.loadDay(nextDay)
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
    }

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.title = self.dateFormatter.string(from: self.viewModel.currentDate)
            self.tableView.reloadData()
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
        cell.configure(with: slot)
        return cell
    }
}
