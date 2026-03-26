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

        // Quick switch profiles
        if !viewModel.profiles.isEmpty {
            ForEach(viewModel.profiles) { profile in
                let isApplied = viewModel.appliedProfileId == profile.id
                let prefix = isApplied ? "\u{2713} " : "    "
                let detail = profile.isDHCP ? "DHCP" : profile.ipAddress
                Button("\(prefix)\(profile.name)  (\(detail) - \(profile.interfaceName))") {
                    Task {
                        await viewModel.applyProfile(profile)
                    }
                }
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
}
