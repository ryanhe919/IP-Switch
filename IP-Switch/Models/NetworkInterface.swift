//
//  NetworkInterface.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import Foundation

struct NetworkInterface: Identifiable, Hashable {
    let id: String          // e.g. "en0"
    let name: String        // e.g. "Wi-Fi", "Ethernet"
    let hardwarePort: String // e.g. "Wi-Fi", "Ethernet"
    var isActive: Bool
    var currentIP: String?
    var currentSubnetMask: String?
    var currentRouter: String?
    var currentDNS: [String]?
    var isDHCP: Bool
}
