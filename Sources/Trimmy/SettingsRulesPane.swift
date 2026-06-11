import SwiftUI

@MainActor
struct RulesSettingsPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        SettingsPaneLayout {
            SettingsSection(
                "Auto-trim exclusions",
                systemImage: "hand.raised",
                subtitle: "Skip automatic clipboard changes in selected apps or browser sites. "
                    + "Manual actions still work.")
            {
                HStack(alignment: .top, spacing: 12) {
                    SettingsTextEditor(
                        title: "Apps",
                        subtitle: "App names or bundle IDs, one per line.",
                        text: self.$settings.autoTrimExcludedApps,
                        minHeight: 120)

                    SettingsTextEditor(
                        title: "Websites",
                        subtitle: "Domains such as example.com, one per line.",
                        text: self.$settings.autoTrimExcludedSites,
                        minHeight: 120)
                }
            }

            SettingsSection(
                "URL query parameters",
                systemImage: "link",
                subtitle: "Control the menu action that removes tracking and other query parameters from copied links.")
            {
                VStack(alignment: .leading, spacing: 14) {
                    PreferenceToggleRow(
                        title: "Show “Paste without Query Params”",
                        subtitle: "Add a menu action that pastes the copied URL without unnecessary parameters.",
                        binding: self.$settings.showURLQueryParamStripOption)

                    if self.settings.showURLQueryParamStripOption {
                        Divider()

                        SettingsTextEditor(
                            title: "Preserved content parameters",
                            subtitle: "One rule per line: domain.com: param1, param2",
                            text: self.$settings.urlQueryParamCustomRules,
                            minHeight: 150)
                    }
                }
            }
        }
    }
}
