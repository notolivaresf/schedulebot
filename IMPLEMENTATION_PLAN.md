# ScheduleBot Implementation Plan

Calendar access and event display feature using UIKit and EventKit.

## Architecture Overview

```
ScheduleBot/
├── Models/
│   └── CalendarEvent.swift
├── Services/
│   └── CalendarService.swift
├── ViewModels/
│   └── CalendarViewModel.swift
├── Views/
│   └── EventTableViewCell.swift
├── Controllers/
│   └── EventsViewController.swift
└── AppDelegate.swift / SceneDelegate.swift
```

### Layer Responsibilities

| Layer | Knows About | Never Imports |
|-------|-------------|---------------|
| Models | Foundation, UIKit (for UIColor) | EventKit |
| Services | EventKit, Models | UIKit views |
| ViewModels | Models, Services | UIKit views |
| Views/Controllers | Models, ViewModels | EventKit |

---

## EKEvent to CalendarEvent Mapping

| CalendarEvent | Source from EKEvent | Purpose |
|---------------|---------------------|---------|
| `id: String` | `eventIdentifier` | Unique identifier |
| `title: String` | `title ?? ""` | Display text |
| `startDate: Date` | `startDate` | When it starts |
| `endDate: Date` | `endDate` | When it ends |
| `isAllDay: Bool` | `isAllDay` | Time formatting |
| `location: String?` | `location` | Optional venue |
| `calendarTitle: String` | `calendar.title` | Calendar name |
| `calendarColor: UIColor` | `calendar.cgColor` | Visual indicator |

---

## Phase 1: Project Setup

### Tasks
1. Create iOS target: File → New → Target → iOS App (UIKit, Storyboard)
2. Add to Info.plist:
   ```
   NSCalendarsFullAccessUsageDescription = "ScheduleBot needs calendar access to display your events"
   ```

### Verification
- Build with `Cmd+B` — should succeed with no errors
- Run on simulator — blank white screen appears
- Check console for no crashes

---

## Phase 2: Model Layer

### Tasks
Create `Models/CalendarEvent.swift`:
```swift
struct CalendarEvent {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let calendarTitle: String
    let calendarColor: UIColor
}
```

### Verification
In `ViewController.viewDidLoad()`:
```swift
let mock = CalendarEvent(
    id: "test-123",
    title: "Test Event",
    startDate: Date(),
    endDate: Date().addingTimeInterval(3600),
    isAllDay: false,
    location: "Office",
    calendarTitle: "Work",
    calendarColor: .systemBlue
)
print("✓ Created event: \(mock.title)")
```
Run app — console should print the message.

---

## Phase 3: Permission Handling

### Tasks
Create `Services/CalendarService.swift`:
```swift
import EventKit

final class CalendarService {
    private let eventStore = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        // iOS 17+ uses requestFullAccessToEvents
        // iOS 14-16 uses requestAccess(to:)
    }
}
```

### Verification
In `ViewController.viewDidLoad()`:
```swift
let service = CalendarService()
print("Current status: \(service.authorizationStatus.rawValue)")

Task {
    let granted = await service.requestAccess()
    print("Access granted: \(granted)")
}
```
Run on **device or simulator with calendar** — permission dialog should appear.

**Test cases:**
- Tap "Allow Full Access" → prints `true`
- Reset simulator (Device → Erase All Content), deny → prints `false`

---

## Phase 4: Event Fetching

### Tasks
Add to `CalendarService`:
```swift
func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
    let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
    let ekEvents = eventStore.events(matching: predicate)
    return ekEvents.map { makeCalendarEvent(from: $0) }
}

private func makeCalendarEvent(from ekEvent: EKEvent) -> CalendarEvent {
    CalendarEvent(
        id: ekEvent.eventIdentifier,
        title: ekEvent.title ?? "No Title",
        startDate: ekEvent.startDate,
        endDate: ekEvent.endDate,
        isAllDay: ekEvent.isAllDay,
        location: ekEvent.location,
        calendarTitle: ekEvent.calendar.title,
        calendarColor: UIColor(cgColor: ekEvent.calendar.cgColor)
    )
}
```

### Verification
```swift
Task {
    let granted = await service.requestAccess()
    if granted {
        let now = Date()
        let weekLater = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let events = service.fetchEvents(from: now, to: weekLater)
        print("Found \(events.count) events:")
        events.forEach { print("  - \($0.title) at \($0.startDate)") }
    }
}
```

**Before running**: Add 2-3 test events to Calendar app on simulator. Run — should print those events.

---

## Phase 5: ViewModel

### Tasks
Create `ViewModels/CalendarViewModel.swift`:
```swift
enum LoadingState {
    case idle
    case loading
    case loaded
    case error(String)
    case permissionDenied
}

final class CalendarViewModel {
    private let calendarService: CalendarService

    private(set) var events: [CalendarEvent] = []
    private(set) var state: LoadingState = .idle

    var onStateChange: ((LoadingState) -> Void)?

    init(calendarService: CalendarService) {
        self.calendarService = calendarService
    }

    func loadEvents() {
        state = .loading
        onStateChange?(.loading)

        Task {
            let granted = await calendarService.requestAccess()
            guard granted else {
                await MainActor.run {
                    state = .permissionDenied
                    onStateChange?(.permissionDenied)
                }
                return
            }

            let now = Date()
            let weekLater = Calendar.current.date(byAdding: .day, value: 7, to: now)!
            let fetchedEvents = calendarService.fetchEvents(from: now, to: weekLater)

            await MainActor.run {
                events = fetchedEvents
                state = .loaded
                onStateChange?(.loaded)
            }
        }
    }
}
```

### Verification
```swift
let viewModel = CalendarViewModel(calendarService: CalendarService())
viewModel.onStateChange = { state in
    print("State changed to: \(state)")
}
viewModel.loadEvents()
```
Run — should print state transitions: `idle → loading → loaded` (or `permissionDenied`).

---

## Phase 6: Table Cell

### Tasks
Create `Views/EventTableViewCell.swift`:
```swift
final class EventTableViewCell: UITableViewCell {
    static let reuseIdentifier = "EventTableViewCell"

    private let colorIndicator = UIView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Layout colorIndicator, titleLabel, timeLabel
    }

    func configure(with event: CalendarEvent) {
        titleLabel.text = event.title
        colorIndicator.backgroundColor = event.calendarColor
        // Format time based on isAllDay
    }
}
```

### Verification
In ViewController, register cell and return one static cell:
```swift
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1  // temporary
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.reuseIdentifier, for: indexPath) as! EventTableViewCell
    cell.configure(with: mockEvent)  // use a hardcoded mock
    return cell
}
```
Run — one cell should appear with mock data displayed.

---

## Phase 7: Integration

### Tasks
Wire everything together in `EventsViewController`:
- Create `UITableView` (programmatically or storyboard)
- Hold reference to `CalendarViewModel`
- Reload table when `onStateChange` fires with `.loaded`

```swift
final class EventsViewController: UIViewController {
    private let tableView = UITableView()
    private let viewModel = CalendarViewModel(calendarService: CalendarService())

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        bindViewModel()
        viewModel.loadEvents()
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .loaded:
                self?.tableView.reloadData()
            case .permissionDenied:
                self?.showPermissionDeniedView()
            // handle other states
            }
        }
    }
}
```

### Verification
1. Add 3+ events in Calendar app on simulator
2. Run app
3. Permission dialog appears → Allow
4. Events from your calendar appear in the table
5. Verify: titles match, times are formatted, calendar colors show

---

## Phase 8: Polish

### Tasks
- Add `UIRefreshControl` — pull down to reload
- Create empty state label: "No events this week"
- Create permission denied view with "Open Settings" button

```swift
// Pull to refresh
let refreshControl = UIRefreshControl()
refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
tableView.refreshControl = refreshControl

@objc private func refresh() {
    viewModel.loadEvents()
}

// Open Settings
if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(settingsURL)
}
```

### Verification Checklist

| State | How to trigger | Expected result |
|-------|---------------|-----------------|
| Loading | App launch | Brief spinner or no flash |
| Populated | Have events in calendar | Events listed |
| Empty | Delete all events | "No events" message |
| Denied | Deny permission, relaunch | "Open Settings" button |
| Refresh | Pull down | Events reload |

---

## Notes

- **iOS Version**: Use `requestFullAccessToEvents()` for iOS 17+, fall back to `requestAccess(to:)` for iOS 14-16
- **Thread Safety**: EventKit calls should happen off main thread; UI updates on main thread
- **Testing**: Use simulator's Calendar app to create test events before running
