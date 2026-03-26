//
//  NetworkService.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import Foundation
import Network

enum NetworkServiceError: LocalizedError {
    case adminCommandFailed(String)
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .adminCommandFailed(let msg):
            return "Admin command failed: \(msg)"
        case .commandFailed(let msg):
            return "Command failed: \(msg)"
        }
    }
}

@MainActor
@Observable
class NetworkService {

    var interfaces: [NetworkInterface] = []
    var hasPermanentAuth: Bool = false
    var networkPathStatus: NWPath.Status = .satisfied

    private let sudoersPath = "/etc/sudoers.d/ip-switch"
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.ip-switch.network-monitor")

    /// Callback invoked when network path changes
    var onNetworkChange: (() -> Void)?

    func startMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.networkPathStatus = path.status
                self.onNetworkChange?()
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    func stopMonitoring() {
        pathMonitor.cancel()
    }

    // MARK: - Authorization

    func checkAuthorization() {
        // Check if sudoers file exists
        hasPermanentAuth = FileManager.default.fileExists(atPath: sudoersPath)
    }

    /// Install sudoers rule for passwordless networksetup. Requires one-time admin password.
    func installPermanentAuth() async throws {
        let username = NSUserName()
        let rule = "\(username) ALL=(root) NOPASSWD: /usr/sbin/networksetup"
        // Write the sudoers rule via AppleScript (one-time admin prompt)
        let cmd = "echo '\(rule)' > \(sudoersPath) && chmod 0440 \(sudoersPath) && chown root:wheel \(sudoersPath)"
        _ = try await runWithAppleScriptAdmin(cmd)
        checkAuthorization()
    }

    /// Remove the sudoers rule.
    func removePermanentAuth() async throws {
        let cmd = "rm -f \(sudoersPath)"
        _ = try await runWithAppleScriptAdmin(cmd)
        checkAuthorization()
    }

    // MARK: - Public

    func loadInterfaces() async {
        checkAuthorization()
        let output = (try? await runCommand("/usr/sbin/networksetup", arguments: ["-listallhardwareports"])) ?? ""
        interfaces = parseHardwarePorts(output)
        await refreshAll()
    }

    func getInterfaceInfo(_ iface: NetworkInterface) async -> NetworkInterface {
        var updated = iface

        if let output = try? await runCommand("/usr/sbin/networksetup", arguments: ["-getinfo", iface.name]) {
            updated = parseInterfaceInfo(output, for: updated)
        }

        if let dnsOutput = try? await runCommand("/usr/sbin/networksetup", arguments: ["-getdnsservers", iface.name]) {
            updated.currentDNS = parseDNSServers(dnsOutput)
        }

        updated.isActive = updated.currentIP != nil && updated.currentIP != ""

        return updated
    }

    func refreshAll() async {
        var refreshed: [NetworkInterface] = []
        for iface in interfaces {
            let updated = await getInterfaceInfo(iface)
            refreshed.append(updated)
        }
        interfaces = refreshed
    }

    func setDHCP(for serviceName: String) async throws {
        try await runPrivileged("/usr/sbin/networksetup", arguments: ["-setdhcp", serviceName])
    }

    func setManualIP(for serviceName: String, ip: String, subnet: String, router: String) async throws {
        try await runPrivileged("/usr/sbin/networksetup", arguments: ["-setmanual", serviceName, ip, subnet, router])
    }

    func setDNS(for serviceName: String, servers: [String]) async throws {
        let args = ["-setdnsservers", serviceName] + (servers.isEmpty ? ["empty"] : servers)
        try await runPrivileged("/usr/sbin/networksetup", arguments: args)
    }

    func applyProfile(_ profile: IPProfile) async throws {
        if profile.isDHCP {
            try await setDHCP(for: profile.interfaceName)
        } else {
            try await setManualIP(
                for: profile.interfaceName,
                ip: profile.ipAddress,
                subnet: profile.subnetMask,
                router: profile.router
            )
        }

        if !profile.dns.isEmpty {
            try await setDNS(for: profile.interfaceName, servers: profile.dns)
        }

        await refreshAll()
    }

    // MARK: - Privileged Execution

    /// Run a privileged command. Uses sudo if permanent auth is installed, otherwise falls back to AppleScript.
    @discardableResult
    private func runPrivileged(_ path: String, arguments: [String]) async throws -> String {
        if hasPermanentAuth {
            return try await runWithSudo(path, arguments: arguments)
        } else {
            // Fallback: build the full command string for AppleScript
            let escaped = ([path] + arguments).map { arg in
                arg.contains(" ") ? "\"\(arg)\"" : arg
            }.joined(separator: " ")
            return try await runWithAppleScriptAdmin(escaped)
        }
    }

    /// Run command with sudo (no password needed when sudoers is configured).
    private func runWithSudo(_ path: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
                process.arguments = [path] + arguments

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: NetworkServiceError.commandFailed(output))
                }
            }
        }
    }

    // MARK: - Shell Execution (Non-Admin)

    private func runCommand(_ path: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = arguments

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: NetworkServiceError.commandFailed(output))
                }
            }
        }
    }

    // MARK: - AppleScript Admin (fallback / one-time setup)

    private func runWithAppleScriptAdmin(_ command: String) async throws -> String {
        let escapedCommand = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escapedCommand)\" with administrator privileges"

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                let result = appleScript?.executeAndReturnError(&error)

                if let error = error {
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    continuation.resume(throwing: NetworkServiceError.adminCommandFailed(message))
                } else {
                    continuation.resume(returning: result?.stringValue ?? "")
                }
            }
        }
    }

    // MARK: - Parsing

    private func parseHardwarePorts(_ output: String) -> [NetworkInterface] {
        var results: [NetworkInterface] = []
        let blocks = output.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.components(separatedBy: "\n")
            var hardwarePort: String?
            var device: String?

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("Hardware Port:") {
                    hardwarePort = String(trimmed.dropFirst("Hardware Port: ".count))
                } else if trimmed.hasPrefix("Device:") {
                    device = String(trimmed.dropFirst("Device: ".count))
                }
            }

            if let port = hardwarePort, let dev = device {
                results.append(NetworkInterface(
                    id: dev,
                    name: port,
                    hardwarePort: port,
                    isActive: false,
                    isDHCP: true
                ))
            }
        }

        return results
    }

    private func parseInterfaceInfo(_ output: String, for iface: NetworkInterface) -> NetworkInterface {
        var updated = iface
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.contains("DHCP Configuration") {
                updated.isDHCP = true
            } else if trimmed.contains("Manual Configuration") {
                updated.isDHCP = false
            } else if trimmed.hasPrefix("IP address:") {
                let val = String(trimmed.dropFirst("IP address: ".count)).trimmingCharacters(in: .whitespaces)
                updated.currentIP = Self.parseValue(val)
            } else if trimmed.hasPrefix("Subnet mask:") {
                let val = String(trimmed.dropFirst("Subnet mask: ".count)).trimmingCharacters(in: .whitespaces)
                updated.currentSubnetMask = Self.parseValue(val)
            } else if trimmed.hasPrefix("Router:") {
                let val = String(trimmed.dropFirst("Router: ".count)).trimmingCharacters(in: .whitespaces)
                updated.currentRouter = Self.parseValue(val)
            }
        }

        return updated
    }

    private static func parseValue(_ val: String) -> String? {
        let invalid = ["none", "(null)", "null", ""]
        if invalid.contains(val.lowercased()) { return nil }
        return val
    }

    private func parseDNSServers(_ output: String) -> [String] {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("aren't any DNS") || trimmed.isEmpty {
            return []
        }
        return trimmed.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
