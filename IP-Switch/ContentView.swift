//
//  ContentView.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(NetworkViewModel.self) private var viewModel
    @Environment(LocalizationManager.self) private var l10n
    @State private var selectedInterfaceId: String?
    @State private var showingAddProfile = false
    @State private var editingProfile: IPProfile?
    @State private var savingFromInterface: IPProfile?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 700, minHeight: 480)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingAddProfile) {
            ProfileEditView(interfaces: viewModel.interfaces) { profile in
                viewModel.addProfile(profile)
            }
        }
        .sheet(item: $editingProfile) { profile in
            ProfileEditView(interfaces: viewModel.interfaces, existingProfile: profile) { updated in
                viewModel.updateProfile(updated)
            }
        }
        .sheet(item: $savingFromInterface) { prefilled in
            ProfileEditView(interfaces: viewModel.interfaces, existingProfile: prefilled) { profile in
                viewModel.addProfile(profile)
            }
        }
        .alert(l10n.t("error.title"), isPresented: Binding(
            get: { viewModel.showingError },
            set: { viewModel.showingError = $0 }
        )) {
            Button(l10n.t("error.ok")) { viewModel.showingError = false }
        } message: {
            Text(viewModel.errorMessage ?? l10n.t("error.unknown"))
        }
    }

    // MARK: - Sidebar
    private var sidebar: some View {
        List(selection: $selectedInterfaceId) {
            Section {
                ForEach(viewModel.interfaces) { iface in
                    interfaceRow(iface)
                        .tag(iface.id)
                }
            } header: {
                SectionHeader(l10n.t("section.interfaces"), icon: "network")
            }

            Section {
                ForEach(viewModel.profiles) { profile in
                    profileRow(profile)
                        .tag("profile-\(profile.id.uuidString)")
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteProfile(viewModel.profiles[index])
                    }
                }
            } header: {
                HStack {
                    SectionHeader(l10n.t("section.profiles"), icon: "list.bullet.rectangle")
                    Spacer()
                    Button {
                        showingAddProfile = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            // Authorization section
            Section {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.hasPermanentAuth ? "lock.open.fill" : "lock.fill")
                        .foregroundStyle(viewModel.hasPermanentAuth ? .green : .orange)
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.t("auth.status"))
                            .font(.system(size: 12, weight: .medium))
                        Text(viewModel.hasPermanentAuth ? l10n.t("auth.granted") : l10n.t("auth.notGranted"))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.hasPermanentAuth {
                        Button {
                            Task { await viewModel.removePermanentAuth() }
                        } label: {
                            Text(l10n.t("auth.revoke"))
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    } else {
                        Button {
                            Task { await viewModel.installPermanentAuth() }
                        } label: {
                            Text(l10n.t("auth.grant"))
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                SectionHeader(l10n.t("auth.title"), icon: "lock.shield")
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 240)
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await viewModel.refreshInterfaces() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
            ToolbarItem {
                Menu {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                        Button {
                            l10n.language = lang
                        } label: {
                            HStack {
                                Text(lang.displayName)
                                if l10n.language == lang {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(l10n.language == .chinese ? "\u{4E2D}" : "EN")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(width: 26, height: 26)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.quaternary)
                        }
                }
            }
        }
    }

    // MARK: - Interface Row
    private func interfaceRow(_ iface: NetworkInterface) -> some View {
        HStack(spacing: 10) {
            StatusDot(isActive: iface.isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(iface.name)
                    .font(.system(size: 13, weight: .medium))
                Text(iface.currentIP ?? l10n.t("interface.notConnected"))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Profile Row
    private func profileRow(_ profile: IPProfile) -> some View {
        HStack(spacing: 10) {
            ProfileBadge(iconName: profile.iconName, color: viewModel.appliedProfileId == profile.id ? .green : .blue)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 13, weight: .medium))
                    if viewModel.appliedProfileId == profile.id {
                        Text(l10n.t("status.applied"))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.green))
                    }
                }
                Text(profile.isDHCP ? "DHCP" : profile.ipAddress)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(l10n.t("action.apply")) {
                Task { await viewModel.applyProfile(profile) }
            }
            Button(l10n.t("action.edit")) {
                editingProfile = profile
            }
            Divider()
            Button(l10n.t("action.delete"), role: .destructive) {
                viewModel.deleteProfile(profile)
            }
        }
    }

    // MARK: - Detail View
    @ViewBuilder
    private var detailView: some View {
        if let id = selectedInterfaceId {
            if id.hasPrefix("profile-"),
               let profileId = UUID(uuidString: String(id.dropFirst(8))),
               let profile = viewModel.profiles.first(where: { $0.id == profileId }) {
                profileDetailView(profile)
            } else if let iface = viewModel.interfaces.first(where: { $0.id == id }) {
                interfaceDetailView(iface)
            } else {
                emptyState
            }
        } else {
            emptyState
        }
    }

    // MARK: - Interface Detail
    private func interfaceDetailView(_ iface: NetworkInterface) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: iface.hardwarePort.lowercased().contains("wi-fi") ? "wifi" : "cable.connector.horizontal")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                        .frame(width: 60, height: 60)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.blue.opacity(0.1))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(iface.name)
                            .font(.title2.bold())
                        HStack(spacing: 8) {
                            StatusDot(isActive: iface.isActive)
                            Text(iface.isActive ? l10n.t("interface.active") : l10n.t("interface.inactive"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\u{2022}")
                                .foregroundStyle(.tertiary)
                            Text(iface.id)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(l10n.t("section.networkInfo"), icon: "info.circle")

                        infoRow(label: l10n.t("label.configuration"), value: iface.isDHCP ? l10n.t("interface.dhcpAuto") : l10n.t("interface.manual"))
                        infoRow(label: l10n.t("label.ipAddress"), value: iface.currentIP ?? "", monospaced: true)
                        infoRow(label: l10n.t("label.subnetMask"), value: iface.currentSubnetMask ?? "", monospaced: true)
                        infoRow(label: l10n.t("label.router"), value: iface.currentRouter ?? "", monospaced: true)
                        infoRow(label: l10n.t("label.dns"), value: (iface.currentDNS ?? []).joined(separator: ", "), monospaced: true)
                    }
                }
                .padding(.horizontal)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(l10n.t("section.quickActions"), icon: "bolt.fill")

                        HStack(spacing: 12) {
                            Button {
                                Task { await viewModel.setDHCP(for: iface) }
                            } label: {
                                Label(l10n.t("action.setDHCP"), systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(iface.isDHCP)

                            Button {
                                savingFromInterface = IPProfile(
                                    id: UUID(),
                                    name: iface.name,
                                    interfaceId: iface.id,
                                    interfaceName: iface.name,
                                    isDHCP: iface.isDHCP,
                                    ipAddress: iface.currentIP ?? "",
                                    subnetMask: iface.currentSubnetMask ?? "255.255.255.0",
                                    router: iface.currentRouter ?? "",
                                    dns: iface.currentDNS ?? [],
                                    iconName: "network"
                                )
                            } label: {
                                Label(l10n.t("action.saveAsProfile"), systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    // MARK: - Profile Detail
    private func profileDetailView(_ profile: IPProfile) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: profile.iconName)
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                        .frame(width: 60, height: 60)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.blue.opacity(0.1))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.title2.bold())
                        Text("\(l10n.t("profile.for")) \(profile.interfaceName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.appliedProfileId == profile.id {
                        Label(l10n.t("status.applied"), systemImage: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                Capsule().fill(.green.opacity(0.12))
                            }
                    }

                    Button {
                        Task { await viewModel.applyProfile(profile) }
                    } label: {
                        Label(l10n.t("action.apply"), systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(l10n.t("section.configuration"), icon: "slider.horizontal.3")

                        infoRow(label: l10n.t("label.interface"), value: "\(profile.interfaceName) (\(profile.interfaceId))")
                        infoRow(label: l10n.t("label.mode"), value: profile.isDHCP ? l10n.t("interface.dhcpAuto") : l10n.t("interface.manual"))

                        if !profile.isDHCP {
                            infoRow(label: l10n.t("label.ipAddress"), value: profile.ipAddress, monospaced: true)
                            infoRow(label: l10n.t("label.subnetMask"), value: profile.subnetMask, monospaced: true)
                            infoRow(label: l10n.t("label.router"), value: profile.router, monospaced: true)
                        }

                        if !profile.dns.isEmpty {
                            infoRow(label: l10n.t("label.dns"), value: profile.dns.joined(separator: ", "), monospaced: true)
                        }
                    }
                }
                .padding(.horizontal)

                GlassCard {
                    HStack(spacing: 12) {
                        Button {
                            editingProfile = profile
                        } label: {
                            Label(l10n.t("action.editProfile"), systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            viewModel.deleteProfile(profile)
                            selectedInterfaceId = nil
                        } label: {
                            Label(l10n.t("action.delete"), systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    // MARK: - Helpers
    private func infoRow(label: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)

            if monospaced {
                Text(value)
                    .font(.system(size: 13, design: .monospaced))
            } else {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "network.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(l10n.t("empty.title"))
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(l10n.t("empty.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}
