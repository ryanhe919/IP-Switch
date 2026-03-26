//
//  GlassCard.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import SwiftUI

// MARK: - Glass Card Container

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            }
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.gray.opacity(0.5))
            .frame(width: 8, height: 8)
            .shadow(color: isActive ? .green.opacity(0.5) : .clear, radius: 4)
    }
}

// MARK: - Profile Badge

struct ProfileBadge: View {
    let iconName: String
    let color: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
            }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16))
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        }
    }
}

// MARK: - IP Address Text

struct IPAddressText: View {
    let ip: String?
    let placeholder: String

    init(_ ip: String?, placeholder: String = "N/A") {
        self.ip = ip
        self.placeholder = placeholder
    }

    var body: some View {
        Text(ip ?? placeholder)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(ip != nil ? .primary : .tertiary)
    }
}
