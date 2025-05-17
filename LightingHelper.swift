import Foundation
import MapboxMaps

class LightingHelper {
    static func getStyleUri() -> StyleURI {
        // Get the current hour in local timezone
        let hour = Calendar.current.dateComponents(in: TimeZone.current, from: Date()).hour ?? 12

        print("🕒 [LightingHelper] Local hour detected: \(hour)")

        // Day: 7am to 7pm (07:00–19:59), Night otherwise
        if hour >= 7 && hour < 19 {
            print("⏰ [LightingHelper] Applying Custom Uber White Day Style")
            return StyleURI(url: URL(string: "mapbox://styles/timex1989/cmasbcp68006y01sc5uq55vp5")!)!
        } else {
            print("⏰ [LightingHelper] Applying Uber Black Night Style")
            return StyleURI(url: URL(string: "mapbox://styles/mapbox/dark-v11")!)!
        }
    }
}

