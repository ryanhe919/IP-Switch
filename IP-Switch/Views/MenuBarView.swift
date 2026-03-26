//
//  MenuBarView.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import SwiftUI

struct MenuBarView: View {
    @Environment(NetworkViewModel.self) private var viewModel
    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        // Current interfaces status
        ForEach(viewModel.interfaces) { iface in
            let statusIcon = iface.isActive ? "\u{25CF}" : "\u{25CB}"
            let ipText = iface.currentIP ?? l10n.t("interface.notConnected")
            let modeText = iface.isDHCP ? "DHCP" : l10n.t("interface.manual")
            Button("\(statusIcon) \(iface.name)  \(ipText)  [\(modeText)]") {}
                .disabled(true)
        }

        Divider()

        // Quick switch profiles (⌘1-9 for first 9)
        if !viewModel.profiles.isEmpty {
            let sorted = viewModel.sortedProfiles
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, profile in
                let isApplied = viewModel.appliedProfileId == profile.id
                let prefix = isApplied ? "\u{2713} " : "    "
                let star = profile.isFavorite ? "\u{2605} " : ""
                let detail = profile.isDHCP ? "DHCP" : profile.ipAddress
                profileButton(
                    title: "\(prefix)\(star)\(profile.name)  (\(detail) - \(profile.interfaceName))",
                    profile: profile,
                    shortcutIndex: index
                )
            }

            Divider()
        }

        // Actions
        Button(l10n.t("action.refresh")) {
            Task { await viewModel.refreshInterfaces() }
        }
        .keyboardShortcut("r")

        Button(l10n.t("action.settings")) {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        }
        .keyboardShortcut(",")

        Divider()

        // Auth status
        let authIcon = viewModel.hasPermanentAuth ? "\u{1F513}" : "\u{1F512}"
        let authText = viewModel.hasPermanentAuth ? l10n.t("auth.granted") : l10n.t("auth.notGranted")
        Button("\(authIcon) \(authText)") {
            if !viewModel.hasPermanentAuth {
                Task { await viewModel.installPermanentAuth() }
            }
        }
        .disabled(viewModel.hasPermanentAuth)

        // Language submenu
        Menu(l10n.t("language")) {
            ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                Button {
                    l10n.language = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                        if l10n.language == lang {
                            Text("\u{2713}")
                        }
                    }
                }
            }
        }

        Button(l10n.t("action.quit")) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private func profileButton(title: String, profile: IPProfile, shortcutIndex: Int) -> some View {
        if shortcutIndex < 9 {
            Button(title) {
                Task { await viewModel.applyProfile(profile) }
            }
            .keyboardShortcut(KeyEquivalent(Character("\(shortcutIndex + 1)")))
        } else {
            Button(title) {
                Task { await viewModel.applyProfile(profile) }
            }
        }
    }
}
