//
//  LocalizationManager.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import SwiftUI

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "\u{4E2D}\u{6587}"
        }
    }
}

@MainActor
@Observable
class LocalizationManager {
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.language = AppLanguage(rawValue: saved) ?? .english
    }

    func t(_ key: String) -> String {
        return Self.strings[language]?[key] ?? key
    }

    // MARK: - String Tables

    private static let strings: [AppLanguage: [String: String]] = [
        .english: [
            // App
            "app.name": "IP Switch",
            "app.ready": "Ready",
            "app.refreshing": "Refreshing...",

            // Sections
            "section.interfaces": "Interfaces",
            "section.profiles": "Profiles",
            "section.quickSwitch": "Quick Switch",
            "section.basicInfo": "Basic Info",
            "section.networkConfig": "Network Config",
            "section.networkInfo": "Network Information",
            "section.quickActions": "Quick Actions",
            "section.configuration": "Configuration",

            // Interface
            "interface.notConnected": "Not Connected",
            "interface.active": "Active",
            "interface.inactive": "Inactive",
            "interface.dhcp": "DHCP",
            "interface.manual": "Manual",
            "interface.dhcpAuto": "DHCP (Automatic)",

            // Labels
            "label.configuration": "Configuration",
            "label.ipAddress": "IP Address",
            "label.subnetMask": "Subnet Mask",
            "label.router": "Router",
            "label.dns": "DNS",
            "label.dnsComma": "DNS (comma separated)",
            "label.interface": "Interface",
            "label.mode": "Mode",
            "label.profileName": "Profile Name",
            "label.icon": "Icon",
            "label.networkInterface": "Network Interface",
            "label.useDHCP": "Use DHCP",

            // Actions
            "action.settings": "Settings",
            "action.refresh": "Refresh",
            "action.quit": "Quit",
            "action.save": "Save",
            "action.cancel": "Cancel",
            "action.apply": "Apply",
            "action.edit": "Edit",
            "action.delete": "Delete",
            "action.setDHCP": "Set DHCP",
            "action.saveAsProfile": "Save as Profile",
            "action.editProfile": "Edit Profile",
            "action.import": "Import Profiles",
            "action.export": "Export Profiles",
            "action.favorite": "Add to Favorites",
            "action.unfavorite": "Remove from Favorites",

            // Profile
            "profile.new": "New Profile",
            "profile.edit": "Edit Profile",
            "profile.for": "Profile for",
            "profile.placeholder": "e.g. Office, Home",

            // Placeholders
            "placeholder.ip": "192.168.1.100",
            "placeholder.subnet": "255.255.255.0",
            "placeholder.router": "192.168.1.1",
            "placeholder.dns": "8.8.8.8, 8.8.4.4",

            // Empty State
            "empty.title": "Select an Interface or Profile",
            "empty.subtitle": "Choose from the sidebar to view details",

            // Error
            "error.title": "Error",
            "error.unknown": "Unknown error",
            "error.ok": "OK",

            // Status
            "status.applied": "Applied",
            "status.applying": "Applying...",

            // Authorization
            "auth.title": "Authorization",
            "auth.granted": "Permanent access granted",
            "auth.notGranted": "Requires password each time",
            "auth.grant": "Grant Permanent Access",
            "auth.grantDesc": "Allow IP switching without entering password each time. You will be asked for your admin password once.",
            "auth.revoke": "Revoke Access",
            "auth.revokeDesc": "Remove permanent access. You will need to enter admin password for each switch.",
            "auth.status": "Authorization Status",

            // Launch at Login
            "launch.section": "Startup",
            "launch.title": "Launch at Login",
            "launch.enabled": "App starts when you log in",
            "launch.disabled": "App does not start automatically",

            // Language
            "language": "Language",

            // Validation
            "validation.nameRequired": "Profile name is required",
            "validation.ipRequired": "IP address is required",
            "validation.ipInvalid": "Invalid IP address format (e.g. 192.168.1.100)",
            "validation.subnetInvalid": "Invalid subnet mask format (e.g. 255.255.255.0)",
            "validation.routerInvalid": "Invalid router address format (e.g. 192.168.1.1)",
            "validation.dnsInvalid": "Invalid DNS address format (e.g. 8.8.8.8)",

            // Notifications
            "notify.profileApplied": "Profile Applied",
            "notify.profileAppliedBody": "Successfully applied profile \"%@\"",
            "notify.dhcpSet": "DHCP Enabled",
            "notify.dhcpSetBody": "Set %@ to DHCP mode",
            "notify.operationFailed": "Operation Failed",
            "notify.authGranted": "Authorization Granted",
            "notify.authGrantedBody": "Permanent access has been granted",
            "notify.authRevoked": "Authorization Revoked",
            "notify.authRevokedBody": "Permanent access has been revoked",

            // Success toast
            "toast.success": "Success",
        ],
        .chinese: [
            // App
            "app.name": "IP Switch",
            "app.ready": "\u{5C31}\u{7EEA}",
            "app.refreshing": "\u{5237}\u{65B0}\u{4E2D}...",

            // Sections
            "section.interfaces": "\u{7F51}\u{7EDC}\u{63A5}\u{53E3}",
            "section.profiles": "\u{914D}\u{7F6E}\u{65B9}\u{6848}",
            "section.quickSwitch": "\u{5FEB}\u{901F}\u{5207}\u{6362}",
            "section.basicInfo": "\u{57FA}\u{672C}\u{4FE1}\u{606F}",
            "section.networkConfig": "\u{7F51}\u{7EDC}\u{914D}\u{7F6E}",
            "section.networkInfo": "\u{7F51}\u{7EDC}\u{4FE1}\u{606F}",
            "section.quickActions": "\u{5FEB}\u{6377}\u{64CD}\u{4F5C}",
            "section.configuration": "\u{914D}\u{7F6E}\u{8BE6}\u{60C5}",

            // Interface
            "interface.notConnected": "\u{672A}\u{8FDE}\u{63A5}",
            "interface.active": "\u{5DF2}\u{6FC0}\u{6D3B}",
            "interface.inactive": "\u{672A}\u{6FC0}\u{6D3B}",
            "interface.dhcp": "DHCP",
            "interface.manual": "\u{624B}\u{52A8}",
            "interface.dhcpAuto": "DHCP (\u{81EA}\u{52A8})",

            // Labels
            "label.configuration": "\u{914D}\u{7F6E}\u{65B9}\u{5F0F}",
            "label.ipAddress": "IP \u{5730}\u{5740}",
            "label.subnetMask": "\u{5B50}\u{7F51}\u{63A9}\u{7801}",
            "label.router": "\u{8DEF}\u{7531}\u{5668}",
            "label.dns": "DNS",
            "label.dnsComma": "DNS (\u{9017}\u{53F7}\u{5206}\u{9694})",
            "label.interface": "\u{63A5}\u{53E3}",
            "label.mode": "\u{6A21}\u{5F0F}",
            "label.profileName": "\u{65B9}\u{6848}\u{540D}\u{79F0}",
            "label.icon": "\u{56FE}\u{6807}",
            "label.networkInterface": "\u{7F51}\u{7EDC}\u{63A5}\u{53E3}",
            "label.useDHCP": "\u{4F7F}\u{7528} DHCP",

            // Actions
            "action.settings": "\u{8BBE}\u{7F6E}",
            "action.refresh": "\u{5237}\u{65B0}",
            "action.quit": "\u{9000}\u{51FA}",
            "action.save": "\u{4FDD}\u{5B58}",
            "action.cancel": "\u{53D6}\u{6D88}",
            "action.apply": "\u{5E94}\u{7528}",
            "action.edit": "\u{7F16}\u{8F91}",
            "action.delete": "\u{5220}\u{9664}",
            "action.setDHCP": "\u{8BBE}\u{4E3A} DHCP",
            "action.saveAsProfile": "\u{4FDD}\u{5B58}\u{4E3A}\u{65B9}\u{6848}",
            "action.editProfile": "\u{7F16}\u{8F91}\u{65B9}\u{6848}",
            "action.import": "\u{5BFC}\u{5165}\u{65B9}\u{6848}",
            "action.export": "\u{5BFC}\u{51FA}\u{65B9}\u{6848}",
            "action.favorite": "\u{6DFB}\u{52A0}\u{5230}\u{6536}\u{85CF}",
            "action.unfavorite": "\u{53D6}\u{6D88}\u{6536}\u{85CF}",

            // Profile
            "profile.new": "\u{65B0}\u{5EFA}\u{65B9}\u{6848}",
            "profile.edit": "\u{7F16}\u{8F91}\u{65B9}\u{6848}",
            "profile.for": "\u{9002}\u{7528}\u{4E8E}",
            "profile.placeholder": "\u{4F8B}\u{5982}: \u{529E}\u{516C}\u{5BA4}, \u{5BB6}\u{5EAD}",

            // Placeholders
            "placeholder.ip": "192.168.1.100",
            "placeholder.subnet": "255.255.255.0",
            "placeholder.router": "192.168.1.1",
            "placeholder.dns": "8.8.8.8, 8.8.4.4",

            // Empty State
            "empty.title": "\u{9009}\u{62E9}\u{4E00}\u{4E2A}\u{63A5}\u{53E3}\u{6216}\u{65B9}\u{6848}",
            "empty.subtitle": "\u{4ECE}\u{4FA7}\u{8FB9}\u{680F}\u{9009}\u{62E9}\u{4EE5}\u{67E5}\u{770B}\u{8BE6}\u{60C5}",

            // Error
            "error.title": "\u{9519}\u{8BEF}",
            "error.unknown": "\u{672A}\u{77E5}\u{9519}\u{8BEF}",
            "error.ok": "\u{786E}\u{5B9A}",

            // Status
            "status.applied": "\u{5DF2}\u{5E94}\u{7528}",
            "status.applying": "\u{5E94}\u{7528}\u{4E2D}...",

            // Authorization
            "auth.title": "\u{6743}\u{9650}\u{7BA1}\u{7406}",
            "auth.granted": "\u{5DF2}\u{6388}\u{4E88}\u{6C38}\u{4E45}\u{6743}\u{9650}",
            "auth.notGranted": "\u{6BCF}\u{6B21}\u{5207}\u{6362}\u{9700}\u{8F93}\u{5165}\u{5BC6}\u{7801}",
            "auth.grant": "\u{6388}\u{4E88}\u{6C38}\u{4E45}\u{6743}\u{9650}",
            "auth.grantDesc": "\u{5141}\u{8BB8}\u{5207}\u{6362} IP \u{65F6}\u{65E0}\u{9700}\u{6BCF}\u{6B21}\u{8F93}\u{5165}\u{5BC6}\u{7801}\u{3002}\u{4EC5}\u{9700}\u{8F93}\u{5165}\u{4E00}\u{6B21}\u{7BA1}\u{7406}\u{5458}\u{5BC6}\u{7801}\u{3002}",
            "auth.revoke": "\u{64A4}\u{9500}\u{6743}\u{9650}",
            "auth.revokeDesc": "\u{79FB}\u{9664}\u{6C38}\u{4E45}\u{6743}\u{9650}\u{3002}\u{6BCF}\u{6B21}\u{5207}\u{6362}\u{5C06}\u{9700}\u{8981}\u{8F93}\u{5165}\u{7BA1}\u{7406}\u{5458}\u{5BC6}\u{7801}\u{3002}",
            "auth.status": "\u{6388}\u{6743}\u{72B6}\u{6001}",

            // Launch at Login
            "launch.section": "\u{542F}\u{52A8}",
            "launch.title": "\u{5F00}\u{673A}\u{81EA}\u{542F}",
            "launch.enabled": "\u{767B}\u{5F55}\u{65F6}\u{81EA}\u{52A8}\u{542F}\u{52A8}\u{5E94}\u{7528}",
            "launch.disabled": "\u{5E94}\u{7528}\u{4E0D}\u{4F1A}\u{81EA}\u{52A8}\u{542F}\u{52A8}",

            // Language
            "language": "\u{8BED}\u{8A00}",

            // Validation
            "validation.nameRequired": "\u{65B9}\u{6848}\u{540D}\u{79F0}\u{4E0D}\u{80FD}\u{4E3A}\u{7A7A}",
            "validation.ipRequired": "IP \u{5730}\u{5740}\u{4E0D}\u{80FD}\u{4E3A}\u{7A7A}",
            "validation.ipInvalid": "IP \u{5730}\u{5740}\u{683C}\u{5F0F}\u{65E0}\u{6548}\u{FF08}\u{4F8B}\u{5982} 192.168.1.100\u{FF09}",
            "validation.subnetInvalid": "\u{5B50}\u{7F51}\u{63A9}\u{7801}\u{683C}\u{5F0F}\u{65E0}\u{6548}\u{FF08}\u{4F8B}\u{5982} 255.255.255.0\u{FF09}",
            "validation.routerInvalid": "\u{8DEF}\u{7531}\u{5668}\u{5730}\u{5740}\u{683C}\u{5F0F}\u{65E0}\u{6548}\u{FF08}\u{4F8B}\u{5982} 192.168.1.1\u{FF09}",
            "validation.dnsInvalid": "DNS \u{5730}\u{5740}\u{683C}\u{5F0F}\u{65E0}\u{6548}\u{FF08}\u{4F8B}\u{5982} 8.8.8.8\u{FF09}",

            // Notifications
            "notify.profileApplied": "\u{65B9}\u{6848}\u{5DF2}\u{5E94}\u{7528}",
            "notify.profileAppliedBody": "\u{5DF2}\u{6210}\u{529F}\u{5E94}\u{7528}\u{65B9}\u{6848} \"%@\"",
            "notify.dhcpSet": "DHCP \u{5DF2}\u{542F}\u{7528}",
            "notify.dhcpSetBody": "\u{5DF2}\u{5C06} %@ \u{8BBE}\u{4E3A} DHCP \u{6A21}\u{5F0F}",
            "notify.operationFailed": "\u{64CD}\u{4F5C}\u{5931}\u{8D25}",
            "notify.authGranted": "\u{6743}\u{9650}\u{5DF2}\u{6388}\u{4E88}",
            "notify.authGrantedBody": "\u{5DF2}\u{6388}\u{4E88}\u{6C38}\u{4E45}\u{8BBF}\u{95EE}\u{6743}\u{9650}",
            "notify.authRevoked": "\u{6743}\u{9650}\u{5DF2}\u{64A4}\u{9500}",
            "notify.authRevokedBody": "\u{6C38}\u{4E45}\u{8BBF}\u{95EE}\u{6743}\u{9650}\u{5DF2}\u{79FB}\u{9664}",

            // Success toast
            "toast.success": "\u{6210}\u{529F}",
        ],
    ]
}
