//
//  ValidationService.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import Foundation

enum ValidationService {

    // MARK: - IP Address

    /// Validates an IPv4 address (e.g. "192.168.1.100")
    static func isValidIPv4(_ address: String) -> Bool {
        let parts = address.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = UInt16(part), num <= 255 else { return false }
            // Reject leading zeros like "01" or "001" (but allow "0" itself)
            if part.count > 1 && part.hasPrefix("0") { return false }
            return true
        }
    }

    /// Validates a subnet mask (must be a valid IPv4 and a contiguous mask)
    static func isValidSubnetMask(_ mask: String) -> Bool {
        guard isValidIPv4(mask) else { return false }
        let parts = mask.split(separator: ".").compactMap { UInt8($0) }
        guard parts.count == 4 else { return false }
        // Convert to 32-bit integer
        let value: UInt32 = parts.reduce(0) { ($0 << 8) | UInt32($1) }
        // A valid mask in binary is a sequence of 1s followed by 0s
        if value == 0 { return true }
        let inverted = ~value
        // inverted + 1 should be a power of 2
        return (inverted & (inverted + 1)) == 0
    }

    /// Validates a single DNS server address (IPv4)
    static func isValidDNS(_ address: String) -> Bool {
        isValidIPv4(address)
    }

    /// Validates a comma-separated DNS string, returns (isValid, invalidEntries)
    static func validateDNSString(_ dnsString: String) -> (isValid: Bool, invalidEntries: [String]) {
        let servers = dnsString.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if servers.isEmpty { return (true, []) }
        let invalid = servers.filter { !isValidDNS($0) }
        return (invalid.isEmpty, invalid)
    }

    // MARK: - Validation Result

    struct ProfileValidation {
        var nameError: String?
        var ipError: String?
        var subnetError: String?
        var routerError: String?
        var dnsError: String?

        var isValid: Bool {
            nameError == nil && ipError == nil && subnetError == nil && routerError == nil && dnsError == nil
        }
    }

    /// Validate a full profile's fields
    static func validateProfile(
        name: String,
        isDHCP: Bool,
        ipAddress: String,
        subnetMask: String,
        router: String,
        dnsString: String
    ) -> ProfileValidation {
        var result = ProfileValidation()

        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            result.nameError = "validation.nameRequired"
        }

        guard !isDHCP else { return result }

        if ipAddress.isEmpty {
            result.ipError = "validation.ipRequired"
        } else if !isValidIPv4(ipAddress) {
            result.ipError = "validation.ipInvalid"
        }

        if !subnetMask.isEmpty && !isValidSubnetMask(subnetMask) {
            result.subnetError = "validation.subnetInvalid"
        }

        if !router.isEmpty && !isValidIPv4(router) {
            result.routerError = "validation.routerInvalid"
        }

        let dnsResult = validateDNSString(dnsString)
        if !dnsResult.isValid {
            result.dnsError = "validation.dnsInvalid"
        }

        return result
    }
}
