import AppKit
import SwiftUI

@MainActor
struct GeneralSettingsPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: AccessibilityPermissionManager

    var body: some View {
        SettingsPaneLayout {
            if !self.permissions.isTrusted {
                AccessibilityPermissionCallout(permissions: self.permissions)
            }

            SettingsSection(
                "Automatic trimming",
                systemImage: "scissors",
                subtitle: "The main clipboard watcher. Manual paste actions remain available when this is off.")
            {
                PreferenceToggleRow(
                    title: "Enable auto-trim",
                    subtitle: "Automatically clean clipboard content when it looks like a command.",
                    binding: self.$settings.autoTrimEnabled)
            }

            SettingsSection(
                "Menu actions",
                systemImage: "menubar.rectangle",
                subtitle: "Choose which optional transformations appear in the Trimmy menu.")
            {
                PreferenceToggleRow(
                    title: "Show Markdown reformat",
                    subtitle: "Reflow wrapped Markdown while preserving headings, lists, and code fences.",
                    binding: self.$settings.showMarkdownReformatOption)
            }

            SettingsSection(
                "App",
                systemImage: "app.badge",
                subtitle: "Control how Trimmy starts and appears on your Mac.")
            {
                VStack(alignment: .leading, spacing: 16) {
                    PreferenceToggleRow(
                        title: "Hide menu bar icon",
                        subtitle: "Keep Trimmy running without showing its scissors icon.",
                        binding: self.$settings.hideMenuBarIcon)

                    Divider()

                    PreferenceToggleRow(
                        title: "Start at Login",
                        subtitle: "Launch Trimmy automatically when you sign in.",
                        binding: self.$settings.launchAtLogin)

                    Divider()

                    HStack {
                        Text("Stop the clipboard watcher and quit the app.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Quit Trimmy") {
                            NSApp.terminate(nil)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}
