import Foundation

protocol BrowserLocationProviding {
    func currentHost(for sourceContext: ClipboardSourceContext) -> String?
}

struct BrowserLocationProvider: BrowserLocationProviding {
    static func supports(_ sourceContext: ClipboardSourceContext) -> Bool {
        guard let bundleIdentifier = sourceContext.bundleIdentifier else { return false }
        return Self.script(for: bundleIdentifier) != nil
    }

    func currentHost(for sourceContext: ClipboardSourceContext) -> String? {
        guard let bundleIdentifier = sourceContext.bundleIdentifier,
              let script = Self.script(for: bundleIdentifier)
        else { return nil }

        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let rawURL = appleScript.executeAndReturnError(&error).stringValue
        guard error == nil, let rawURL else { return nil }
        return AutoTrimExclusionMatcher.normalizedHost(from: rawURL)
    }

    private static func script(for bundleIdentifier: String) -> String? {
        switch bundleIdentifier {
        case "com.apple.Safari":
            """
            tell application id "\(bundleIdentifier)"
                if (count of documents) is 0 then return ""
                return URL of front document
            end tell
            """
        case "com.google.Chrome",
             "com.google.Chrome.canary",
             "com.brave.Browser",
             "com.microsoft.edgemac",
             "com.microsoft.edgemac.Canary",
             "company.thebrowser.Browser":
            """
            tell application id "\(bundleIdentifier)"
                if (count of windows) is 0 then return ""
                return URL of active tab of front window
            end tell
            """
        default:
            nil
        }
    }
}

enum AutoTrimExclusionMatcher {
    static func tokens(from text: String) -> [String] {
        text
            .split { $0.isNewline || $0 == "," }
            .compactMap { rawToken in
                let withoutComment = rawToken.split(separator: "#", maxSplits: 1).first ?? ""
                let token = withoutComment.trimmingCharacters(in: .whitespacesAndNewlines)
                return token.isEmpty ? nil : token
            }
    }

    static func matchesApp(_ sourceContext: ClipboardSourceContext, patterns: String) -> Bool {
        let appValues = [
            sourceContext.bundleIdentifier?.lowercased(),
            sourceContext.appName?.lowercased(),
        ].compactMap(\.self)

        return self.tokens(from: patterns).contains { rawPattern in
            let pattern = rawPattern.lowercased()
            return appValues.contains { value in
                value == pattern || (!pattern.contains(".") && value.contains(pattern))
            }
        }
    }

    static func matchesSite(host: String?, patterns: String) -> Bool {
        guard let host = host?.lowercased(), !host.isEmpty else { return false }
        return self.tokens(from: patterns).contains { rawPattern in
            guard var pattern = self.normalizedHost(from: rawPattern) else { return false }
            if pattern.hasPrefix("*.") {
                pattern.removeFirst(2)
            }
            return host == pattern || host.hasSuffix(".\(pattern)")
        }
    }

    static func normalizedHost(from rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        if let host = URLComponents(string: candidate)?.host?.lowercased(), !host.isEmpty {
            return host
        }

        return trimmed
            .split { $0 == "/" || $0 == ":" || $0.isWhitespace }
            .first
            .map { String($0).lowercased() }
    }
}

extension AppSettings {
    var hasAutoTrimSiteExclusions: Bool {
        !AutoTrimExclusionMatcher.tokens(from: self.autoTrimExcludedSites).isEmpty
    }

    func excludesAutoTrimApp(sourceContext: ClipboardSourceContext) -> Bool {
        AutoTrimExclusionMatcher.matchesApp(sourceContext, patterns: self.autoTrimExcludedApps)
    }

    func excludesAutoTrimSite(host: String?) -> Bool {
        AutoTrimExclusionMatcher.matchesSite(host: host, patterns: self.autoTrimExcludedSites)
    }
}
