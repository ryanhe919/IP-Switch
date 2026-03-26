//
//  NetworkViewModel.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
@Observable
class NetworkViewModel {

    let networkService = NetworkService()

    var interfaces: [NetworkInterface] = []
    var profiles: [IPProfile] = []
    var selectedInterface: NetworkInterface?
    var isLoading = false
    var errorMessage: String?
    var showingError = false

    // Toast notification state
    var toastMessage: String?
    var showingToast = false

    // Auto-refresh
    private var refreshTimer: Timer?
    var autoRefreshInterval: TimeInterval = 30

    /// Dynamic menu bar icon based on network state
    var menuBarIcon: String {
        if isLoading {
            return "arrow.triangle.2.circlepath"
        }
        let hasActive = interfaces.contains { $0.isActive }
        if !hasActive {
            return "network.slash"
        }
        if appliedProfileId != nil {
            return "network.badge.shield.half.filled"
        }
        return "network"
    }
    var appliedProfileId: UUID? {
        didSet {
            if let id = appliedProfileId {
                UserDefaults.standard.set(id.uuidString, forKey: "appliedProfileId")
            } else {
                UserDefaults.standard.removeObject(forKey: "appliedProfileId")
            }
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        showingToast = true
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            showingToast = false
        }
    }

    private func sendNotification(title: String, body: String) {
        NotificationService.shared.send(title: title, body: body)
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.silentRefresh()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Refresh without loading indicator (background refresh)
    private func silentRefresh() async {
        await networkService.refreshAll()
        interfaces = networkService.interfaces
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        await networkService.loadInterfaces()
        interfaces = networkService.interfaces
        loadProfiles()
        if let savedId = UserDefaults.standard.string(forKey: "appliedProfileId") {
            appliedProfileId = UUID(uuidString: savedId)
        }
        isLoading = false
        startAutoRefresh()
        startNetworkMonitor()
    }

    private func startNetworkMonitor() {
        networkService.onNetworkChange = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.silentRefresh()
            }
        }
        networkService.startMonitoring()
    }

    func refreshInterfaces() async {
        isLoading = true
        await networkService.loadInterfaces()
        interfaces = networkService.interfaces
        isLoading = false
    }

    // MARK: - Profile Persistence

    func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: "savedProfiles"),
              let decoded = try? JSONDecoder().decode([IPProfile].self, from: data) else {
            return
        }
        profiles = decoded
    }

    func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: "savedProfiles")
        }
    }

    // MARK: - Profile CRUD

    func addProfile(_ profile: IPProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    func deleteProfile(_ profile: IPProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
    }

    func updateProfile(_ profile: IPProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }

    func toggleFavorite(_ profile: IPProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index].isFavorite.toggle()
            saveProfiles()
        }
    }

    func moveProfile(from source: IndexSet, to destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
        // Update sort order
        for i in profiles.indices {
            profiles[i].sortOrder = i
        }
        saveProfiles()
    }

    /// Profiles sorted: favorites first, then by sortOrder
    var sortedProfiles: [IPProfile] {
        profiles.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite }
            return a.sortOrder < b.sortOrder
        }
    }

    // MARK: - Profile Import / Export

    /// Export profiles to a JSON file via save panel
    func exportProfiles() {
        guard !profiles.isEmpty else { return }
        let panel = NSSavePanel()
        panel.title = "Export Profiles"
        panel.nameFieldStringValue = "ip-switch-profiles.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(profiles)
            try data.write(to: url)
            showToast("export.success")
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    /// Import profiles from a JSON file via open panel
    func importProfiles() {
        let panel = NSOpenPanel()
        panel.title = "Import Profiles"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode([IPProfile].self, from: data)
            var addedCount = 0
            for var profile in imported {
                // Assign new IDs to avoid conflicts
                profile.id = UUID()
                profiles.append(profile)
                addedCount += 1
            }
            saveProfiles()
            showToast("\(addedCount) profiles imported")
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Authorization

    var hasPermanentAuth: Bool {
        networkService.hasPermanentAuth
    }

    func installPermanentAuth() async {
        do {
            try await networkService.installPermanentAuth()
            showToast("notify.authGranted")
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    func removePermanentAuth() async {
        do {
            try await networkService.removePermanentAuth()
            showToast("notify.authRevoked")
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Actions

    func applyProfile(_ profile: IPProfile) async {
        isLoading = true
        do {
            try await networkService.applyProfile(profile)
            interfaces = networkService.interfaces
            appliedProfileId = profile.id
            showToast(profile.name)
            sendNotification(
                title: "notify.profileApplied",
                body: profile.name
            )
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        isLoading = false
    }

    func setDHCP(for iface: NetworkInterface) async {
        isLoading = true
        do {
            try await networkService.setDHCP(for: iface.name)
            await networkService.refreshAll()
            interfaces = networkService.interfaces
            showToast(iface.name + " → DHCP")
            sendNotification(
                title: "notify.dhcpSet",
                body: iface.name
            )
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        isLoading = false
    }

    func setManualIP(for iface: NetworkInterface, ip: String, subnet: String, router: String, dns: [String]) async {
        isLoading = true
        do {
            try await networkService.setManualIP(for: iface.name, ip: ip, subnet: subnet, router: router)
            if !dns.isEmpty {
                try await networkService.setDNS(for: iface.name, servers: dns)
            }
            await networkService.refreshAll()
            interfaces = networkService.interfaces
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        isLoading = false
    }
}
