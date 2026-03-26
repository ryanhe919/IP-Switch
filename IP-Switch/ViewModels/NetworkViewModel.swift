//
//  NetworkViewModel.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import Foundation

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
    var appliedProfileId: UUID? {
        didSet {
            if let id = appliedProfileId {
                UserDefaults.standard.set(id.uuidString, forKey: "appliedProfileId")
            } else {
                UserDefaults.standard.removeObject(forKey: "appliedProfileId")
            }
        }
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

    // MARK: - Authorization

    var hasPermanentAuth: Bool {
        networkService.hasPermanentAuth
    }

    func installPermanentAuth() async {
        do {
            try await networkService.installPermanentAuth()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    func removePermanentAuth() async {
        do {
            try await networkService.removePermanentAuth()
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
