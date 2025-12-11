import Foundation
import AppKit

// MARK: - Update State

enum UpdateState {
    case idle
    case checking
    case available(UpdateInfo)
    case upToDate
    case downloading(progress: Double)
    case installing
    case error(String)
}

// MARK: - Update Manager

class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()

    @Published var state: UpdateState = .idle
    @Published var lastCheckDate: Date?

    private var downloadTask: URLSessionDownloadTask?
    private var downloadingVersion: String?

    private let autoCheckInterval: TimeInterval = 24 * 60 * 60
    private let autoCheckKey = "gonhanh.update.lastCheck"
    private let skipVersionKey = "gonhanh.update.skipVersion"

    private override init() {
        super.init()
        lastCheckDate = UserDefaults.standard.object(forKey: autoCheckKey) as? Date
    }

    // MARK: - Public API

    func checkForUpdatesManually() {
        checkForUpdates(silent: false)
    }

    func checkForUpdatesSilently() {
        guard let lastCheck = lastCheckDate,
              Date().timeIntervalSince(lastCheck) >= autoCheckInterval else {
            return
        }
        checkForUpdates(silent: true)
    }

    func downloadUpdate(_ info: UpdateInfo) {
        state = .downloading(progress: 0)
        downloadingVersion = info.version

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        downloadTask = session.downloadTask(with: info.downloadURL)
        downloadTask?.resume()
    }

    func skipVersion(_ version: String) {
        UserDefaults.standard.set(version, forKey: skipVersionKey)
        state = .idle
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        state = .idle
    }

    // MARK: - Private Methods

    private func checkForUpdates(silent: Bool) {
        if !silent { state = .checking }

        UpdateChecker.shared.checkForUpdates { [weak self] result in
            guard let self = self else { return }

            self.lastCheckDate = Date()
            UserDefaults.standard.set(self.lastCheckDate, forKey: self.autoCheckKey)

            switch result {
            case .available(let info):
                let skipped = UserDefaults.standard.string(forKey: self.skipVersionKey)
                if silent && skipped == info.version {
                    self.state = .idle
                    return
                }
                self.state = .available(info)
                if silent { self.showUpdateNotification(info) }

            case .upToDate:
                self.state = .upToDate

            case .error(let message):
                self.state = .error(message)
            }
        }
    }

    private func showUpdateNotification(_ info: UpdateInfo) {
        let notification = NSUserNotification()
        notification.title = "GoNhanh - Có phiên bản mới"
        notification.informativeText = "Phiên bản \(info.version) đã sẵn sàng."
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.hasActionButton = true
        notification.actionButtonTitle = "Xem"
        NSUserNotificationCenter.default.deliver(notification)
    }

    // MARK: - Install

    private func install(dmgPath: URL) {
        state = .installing

        DispatchQueue.global(qos: .userInitiated).async {
            let error = self.performInstall(dmgPath: dmgPath)
            if let error = error {
                DispatchQueue.main.async { self.state = .error(error) }
            }
        }
    }

    private func performInstall(dmgPath: URL) -> String? {
        let mountPoint = "/Volumes/GoNhanh"
        let appName = "GoNhanh.app"
        let sourceApp = "\(mountPoint)/\(appName)"
        let destApp = "/Applications/\(appName)"

        // Mount
        guard shell("hdiutil attach '\(dmgPath.path)' -nobrowse -quiet -mountpoint '\(mountPoint)'").ok else {
            return "Không thể mở file cài đặt."
        }

        // Validate
        guard FileManager.default.fileExists(atPath: sourceApp) else {
            shell("hdiutil detach '\(mountPoint)' -quiet -force")
            return "File cài đặt bị lỗi."
        }

        // Copy
        guard shell("rm -rf '\(destApp)' && cp -R '\(sourceApp)' '\(destApp)'").ok else {
            shell("hdiutil detach '\(mountPoint)' -quiet -force")
            return "Không có quyền cài vào Applications."
        }

        // Unmount
        shell("hdiutil detach '\(mountPoint)' -quiet -force")

        // Relaunch: spawn background process that waits for this app to quit, then opens new app
        let pid = ProcessInfo.processInfo.processIdentifier
        shell("(while kill -0 \(pid) 2>/dev/null; do sleep 0.1; done; sleep 0.3; open '\(destApp)') &")

        // Quit
        DispatchQueue.main.async { NSApp.terminate(nil) }

        return nil
    }

    @discardableResult
    private func shell(_ command: String) -> (output: String, ok: Bool) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (output.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus == 0)
    }
}

// MARK: - URLSession Download Delegate

extension UpdateManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let version = downloadingVersion ?? "latest"
        let dmgPath = tempDir.appendingPathComponent("GoNhanh-\(version).dmg")

        do {
            if FileManager.default.fileExists(atPath: dmgPath.path) {
                try FileManager.default.removeItem(at: dmgPath)
            }
            try FileManager.default.copyItem(at: location, to: dmgPath)
            install(dmgPath: dmgPath)
        } catch {
            state = .error("Không thể lưu file: \(error.localizedDescription)")
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        state = .downloading(progress: Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        if (error as NSError).code == NSURLErrorCancelled {
            state = .idle
        } else {
            state = .error("Tải về thất bại: \(error.localizedDescription)")
        }
    }
}
