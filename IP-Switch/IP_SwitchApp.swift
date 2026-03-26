//
//  IP_SwitchApp.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import SwiftUI

@main
struct IP_SwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = NetworkViewModel()
    @State private var l10n = LocalizationManager()

    var body: some Scene {
        // Main settings window
        Window("IP Switch", id: "main") {
            ContentView()
                .environment(viewModel)
                .environment(l10n)
                .task {
                    await viewModel.loadData()
                }
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                }
                .onDisappear {
                    // Delay slightly so the window fully closes before hiding from Dock
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if !NSApp.windows.contains(where: { $0.isVisible && $0.canBecomeMain }) {
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
                }
        }
        .defaultSize(width: 800, height: 540)

        // Menu bar native dropdown menu
        MenuBarExtra("IP Switch", systemImage: "network.badge.shield.half.filled") {
            MenuBarView()
                .environment(viewModel)
                .environment(l10n)
                .task {
                    await viewModel.loadData()
                }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as accessory (no Dock icon), menu bar only
        NSApp.setActivationPolicy(.accessory)
    }
}
