import Foundation
import TitanCore
import UserNotifications

/// Reminders the device shows by itself at a set time, with no server, such as "time to study".
///
///     guard await reminders.requestAuthorization() else { showSettingsHint(); return }
///     try await reminders.scheduleDaily(id: "study", hour: 20, minute: 0,
///                                       title: "Dolingo", body: "5 phút học tiếng Anh nhé!")
public protocol ReminderScheduler: Sendable {
    /// Asks to show alerts and play sounds. False when the user refused.
    func requestAuthorization() async -> Bool
    /// Replaces any reminder with the same id.
    func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String) async throws(TitanError)
    func cancel(id: String) async
}

/// ReminderScheduler on UNUserNotificationCenter.
public struct UserNotificationReminderScheduler: ReminderScheduler {
    public init() {}

    public func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String) async throws(TitanError) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: hour, minute: minute),
            repeats: true
        )
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        do {
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } catch {
            throw .unknown("reminder: \(error.localizedDescription)")
        }
    }

    public func cancel(id: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

/// ReminderScheduler for tests and previews; keeps the reminders in memory.
public final class MockReminderScheduler: ReminderScheduler, @unchecked Sendable {
    // @unchecked: all state is guarded by `lock`.
    public struct Reminder: Equatable, Sendable {
        public let hour: Int
        public let minute: Int
        public let title: String
        public let body: String
    }

    private let lock = NSLock()
    private var authorized: Bool
    private var stored: [String: Reminder] = [:]

    public init(isAuthorized: Bool = true) {
        authorized = isAuthorized
    }

    public func requestAuthorization() async -> Bool {
        lock.withLock { authorized }
    }

    public func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String) async throws(TitanError) {
        let allowed = lock.withLock { authorized }
        guard allowed else { throw .unauthorized }
        lock.withLock { stored[id] = Reminder(hour: hour, minute: minute, title: title, body: body) }
    }

    public func cancel(id: String) async {
        _ = lock.withLock { stored.removeValue(forKey: id) }
    }

    /// What is scheduled now, by id.
    public var reminders: [String: Reminder] {
        lock.withLock { stored }
    }
}
