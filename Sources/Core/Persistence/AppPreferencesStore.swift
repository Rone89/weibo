import Foundation

@MainActor
final class AppPreferencesStore: ObservableObject {
    private enum Keys {
        static let guestRecommendation = "preferences.guestRecommendation.v1"
        static let incognitoPlayback = "preferences.incognitoPlayback.v1"
    }

    @Published private(set) var isGuestRecommendationEnabled: Bool
    @Published private(set) var isIncognitoPlaybackEnabled: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isGuestRecommendationEnabled = defaults.bool(forKey: Keys.guestRecommendation)
        self.isIncognitoPlaybackEnabled = defaults.bool(forKey: Keys.incognitoPlayback)
    }

    func setGuestRecommendationEnabled(_ isEnabled: Bool) {
        guard isGuestRecommendationEnabled != isEnabled else { return }
        isGuestRecommendationEnabled = isEnabled
        defaults.set(isEnabled, forKey: Keys.guestRecommendation)
    }

    func setIncognitoPlaybackEnabled(_ isEnabled: Bool) {
        guard isIncognitoPlaybackEnabled != isEnabled else { return }
        isIncognitoPlaybackEnabled = isEnabled
        defaults.set(isEnabled, forKey: Keys.incognitoPlayback)
    }
}
