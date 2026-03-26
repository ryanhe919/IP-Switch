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
    var isFavorite: Bool = false
    var sortOrder: Int = 0

    // Custom CodingKeys for backward compatibility with existing data
    enum CodingKeys: String, CodingKey {
        case id, name, interfaceId, interfaceName, isDHCP
        case ipAddress, subnetMask, router, dns, iconName
        case isFavorite, sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        interfaceId = try container.decode(String.self, forKey: .interfaceId)
        interfaceName = try container.decode(String.self, forKey: .interfaceName)
        isDHCP = try container.decode(Bool.self, forKey: .isDHCP)
        ipAddress = try container.decode(String.self, forKey: .ipAddress)
        subnetMask = try container.decode(String.self, forKey: .subnetMask)
        router = try container.decode(String.self, forKey: .router)
        dns = try container.decode([String].self, forKey: .dns)
        iconName = try container.decode(String.self, forKey: .iconName)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }

    init(
        id: UUID = UUID(),
        name: String,
        interfaceId: String,
        interfaceName: String,
        isDHCP: Bool,
        ipAddress: String,
        subnetMask: String,
        router: String,
        dns: [String],
        iconName: String,
        isFavorite: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.interfaceId = interfaceId
        self.interfaceName = interfaceName
        self.isDHCP = isDHCP
        self.ipAddress = ipAddress
        self.subnetMask = subnetMask
        self.router = router
        self.dns = dns
        self.iconName = iconName
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
    }

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
