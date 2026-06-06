import Foundation

struct PortInfo: Identifiable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
}

enum PortScanner {
    // macOS ephemeral range starts at 49152 — above this are OS-assigned transient sockets
    private static let ephemeralThreshold = 49152

    // Background system/app processes that are never dev servers
    private static let excludedPrefixes: [String] = [
        "rapportd", "ControlCe", "logioptio", "LogiPlugi",
        "AdobeReso", "Spotify", "Google", "language_",
        "Antigravi", "sharingd", "cloudd", "identitys",
        "secd", "trustd", "mDNSRespo", "configd",
        "Code\\x20H",   // VS Code Extension Host internal port
    ]

    static func scan() -> [PortInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // -iTCP: only TCP, -sTCP:LISTEN: only listening sockets, -P: numeric ports, -n: no hostname resolution
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-P", "-n"]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var ports: [PortInfo] = []
        var seenPorts = Set<Int>()

        for line in output.components(separatedBy: "\n").dropFirst() where !line.isEmpty {
            // Fields: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (LISTEN)
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 10 else { continue }

            let processName = String(parts[0])
            guard let pid = Int(parts[1]) else { continue }

            // lsof appends "(LISTEN)" as the last token; the address is one before it
            let name = String(parts[parts.count - 2])
            guard let port = extractPort(from: name) else { continue }

            // Skip ephemeral OS-assigned ports (system background sockets)
            guard port < ephemeralThreshold else { continue }

            // Skip known background system/app processes
            let isExcluded = excludedPrefixes.contains { processName.hasPrefix($0) }
            guard !isExcluded else { continue }

            // Deduplicate (same port on IPv4 + IPv6 shows twice)
            guard !seenPorts.contains(port) else { continue }
            seenPorts.insert(port)

            ports.append(PortInfo(port: port, pid: pid, processName: processName))
        }

        return ports.sorted { $0.port < $1.port }
    }

    private static func extractPort(from name: String) -> Int? {
        // Handle IPv6: [::]:8080 or [::1]:8080
        if name.hasPrefix("[") {
            guard let bracket = name.lastIndex(of: "]"),
                  name.index(after: bracket) < name.endIndex else { return nil }
            let afterBracket = name.index(after: bracket)
            guard name[afterBracket] == ":" else { return nil }
            let portStr = String(name[name.index(after: afterBracket)...])
            return Int(portStr)
        }
        // Handle IPv4: 127.0.0.1:8080 or *:8080
        guard let colon = name.lastIndex(of: ":") else { return nil }
        return Int(name[name.index(after: colon)...])
    }

    static func kill(pid: Int) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/kill")
        process.arguments = ["-9", String(pid)]
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
