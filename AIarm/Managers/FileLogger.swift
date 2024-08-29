import Foundation

class FileLogger {
    static let shared = FileLogger()
    private let fileManager = FileManager.default
    private var logFileURL: URL?

    private init() {
        setupLogFile()
    }

    private func setupLogFile() {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory")
            log("Unable to access documents directory")
            return
        }
        logFileURL = documentsDirectory.appendingPathComponent("AIarm_log.txt")
    }

    func log(_ message: String) {
        guard let logFileURL = logFileURL else { return }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        
        if fileManager.fileExists(atPath: logFileURL.path) {
            do {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logMessage.data(using: .utf8)!)
                fileHandle.closeFile()
            } catch {
                print("Error writing to log file: \(error)")
                log("Error writing to log file: \(error)")
            }
        } else {
            do {
                try logMessage.write(to: logFileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error creating log file: \(error)")
                log("Error creating log file: \(error)")
            }
        }
    }

    func getLogContents() -> String {
        guard let logFileURL = logFileURL,
              let contents = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return "No logs available"
        }
        return contents
    }
    
    func clearLogs() {
        guard let logFileURL = logFileURL else { return }
        do {
            try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            print("Logs cleared successfully")
        } catch {
            print("Error clearing log file: \(error)")
        }
    }
}
