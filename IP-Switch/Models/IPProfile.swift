//
//  IPProfile.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import Foundation

struct IPProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var interfaceId: String
    var interfaceName: String
    var isDHCP: Bool
    var ipAddress: String
    var subnetMask: String
    var router: String
    var dns: [String]
    var iconName: String

    static var defaultProfile: IPProfile {
        IPProfile(
            name: "New Profile",
            interfaceId: "en0",
            interfaceName: "Wi-Fi",
            isDHCP: true,
            ipAddress: "",
            subnetMask: "255.255.255.0",
            router: "",
            dns: [],
            iconName: "network"
        )
    }
}
