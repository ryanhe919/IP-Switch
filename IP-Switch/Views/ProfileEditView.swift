//
//  ProfileEditView.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var l10n

    let interfaces: [NetworkInterface]
    let existingProfile: IPProfile?
    let onSave: (IPProfile) -> Void

    @State private var name: String = ""
    @State private var selectedInterfaceId: String = "en0"
    @State private var isDHCP: Bool = true
    @State private var ipAddress: String = ""
    @State private var subnetMask: String = "255.255.255.0"
    @State private var router: String = ""
    @State private var dnsString: String = ""
    @State private var iconName: String = "network"
    @State private var validation = ValidationService.ProfileValidation()
    @State private var hasAttemptedSave = false

    private let availableIcons = [
        "network", "building.2", "house", "briefcase", "wifi",
        "desktopcomputer", "server.rack", "globe", "lock.shield",
        "antenna.radiowaves.left.and.right"
    ]

    private let iconColumns = Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8)

    init(interfaces: [NetworkInterface], existingProfile: IPProfile? = nil, onSave: @escaping (IPProfile) -> Void) {
        self.interfaces = interfaces
        self.existingProfile = existingProfile
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(existingProfile == nil ? l10n.t("profile.new") : l10n.t("profile.edit"))
                    .font(.headline)
                Spacer()
                Button(l10n.t("action.cancel")) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(l10n.t("section.basicInfo").uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.t("label.profileName"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextField(l10n.t("profile.placeholder"), text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Icon picker - grid layout
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.t("label.icon"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: iconColumns, spacing: 8) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button {
                                        iconName = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 16))
                                            .frame(width: 36, height: 36)
                                            .background {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(iconName == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                            }
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(iconName == icon ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Interface picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.t("label.networkInterface"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)

                            Picker("", selection: $selectedInterfaceId) {
                                ForEach(interfaces) { iface in
                                    Text("\(iface.name) (\(iface.id))")
                                        .tag(iface.id)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }

                    // Network Config
                    VStack(alignment: .leading, spacing: 12) {
                        Text(l10n.t("section.networkConfig").uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)

                        Toggle(l10n.t("label.useDHCP"), isOn: $isDHCP)
                            .toggleStyle(.switch)

                        if !isDHCP {
                            VStack(spacing: 10) {
                                validatedFieldRow(l10n.t("label.ipAddress"), placeholder: "192.168.1.100", text: $ipAddress, error: validation.ipError)
                                validatedFieldRow(l10n.t("label.subnetMask"), placeholder: "255.255.255.0", text: $subnetMask, error: validation.subnetError)
                                validatedFieldRow(l10n.t("label.router"), placeholder: "192.168.1.1", text: $router, error: validation.routerError)
                                validatedFieldRow(l10n.t("label.dnsComma"), placeholder: "8.8.8.8, 8.8.4.4", text: $dnsString, error: validation.dnsError)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                    .animation(.easeInOut(duration: 0.2), value: isDHCP)
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button(l10n.t("action.save")) {
                    hasAttemptedSave = true
                    runValidation()
                    if validation.isValid {
                        saveProfile()
                    }
                }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear {
            if let profile = existingProfile {
                name = profile.name
                selectedInterfaceId = profile.interfaceId
                isDHCP = profile.isDHCP
                ipAddress = profile.ipAddress
                subnetMask = profile.subnetMask
                router = profile.router
                dnsString = profile.dns.joined(separator: ", ")
                iconName = profile.iconName
            }
        }
    }

    private func validatedFieldRow(_ label: String, placeholder: String, text: Binding<String>, error: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(hasAttemptedSave && error != nil ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1)
                )
                .onChange(of: text.wrappedValue) {
                    if hasAttemptedSave { runValidation() }
                }
            if hasAttemptedSave, let errorKey = error {
                Text(l10n.t(errorKey))
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
    }

    private func runValidation() {
        validation = ValidationService.validateProfile(
            name: name,
            isDHCP: isDHCP,
            ipAddress: ipAddress,
            subnetMask: subnetMask,
            router: router,
            dnsString: dnsString
        )
    }

    private func saveProfile() {
        let selectedInterface = interfaces.first { $0.id == selectedInterfaceId }
        let dns = dnsString.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var profile = existingProfile ?? IPProfile.defaultProfile
        profile.name = name
        profile.interfaceId = selectedInterfaceId
        profile.interfaceName = selectedInterface?.name ?? selectedInterfaceId
        profile.isDHCP = isDHCP
        profile.ipAddress = ipAddress
        profile.subnetMask = subnetMask
        profile.router = router
        profile.dns = dns
        profile.iconName = iconName

        onSave(profile)
        dismiss()
    }
}
