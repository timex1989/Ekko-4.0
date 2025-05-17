import UIKit
import MapboxMaps
import Lottie

struct BeaconCoordinate: Hashable {
    let coordinate: CLLocationCoordinate2D
    func hash(into hasher: inout Hasher) {
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
    static func == (lhs: BeaconCoordinate, rhs: BeaconCoordinate) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

class BeaconGlowHandler {
    private(set) var lottieBeaconViews: [BeaconCoordinate: LottieAnimationView] = [:]
    private var glowViews: [BeaconCoordinate: UIView] = [:]

    func addBeaconsWithGlow(
        at coordinates: [CLLocationCoordinate2D],
        mapView: MapView,
        to parentView: UIView
    ) {
        // Remove old
        for view in lottieBeaconViews.values { view.removeFromSuperview() }
        for view in glowViews.values { view.removeFromSuperview() }
        lottieBeaconViews = [:]
        glowViews = [:]

        for coord in coordinates {
            guard let _ = Bundle.main.url(forResource: "Bounce 7", withExtension: "json") else {
                print("❌ Bounce 7.json not found! Skipping.")
                continue
            }
            let lottieView = LottieAnimationView(name: "Bounce 7")
            lottieView.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
            lottieView.loopMode = .loop
            lottieView.backgroundBehavior = .pauseAndRestore
            lottieView.contentMode = .scaleAspectFit
            lottieView.animationSpeed = 5
            lottieView.play()

            let glowView = UIView(frame: lottieView.frame)
            glowView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.4)
            glowView.layer.cornerRadius = 75
            glowView.layer.shadowColor = UIColor.systemBlue.cgColor
            glowView.layer.shadowRadius = 40
            glowView.layer.shadowOpacity = 0.8
            glowView.layer.shadowOffset = .zero
            glowView.layer.masksToBounds = false

            parentView.addSubview(glowView)
            parentView.addSubview(lottieView)
            parentView.bringSubviewToFront(lottieView)

            let screenPoint = mapView.mapboxMap.point(for: coord)
            lottieView.center = screenPoint
            glowView.center = screenPoint

            lottieBeaconViews[BeaconCoordinate(coordinate: coord)] = lottieView
            glowViews[BeaconCoordinate(coordinate: coord)] = glowView
        }
    }

    // Call this when camera moves!
    func updateBeaconPositions(mapView: MapView) {
        for (coordWrapper, lottieView) in lottieBeaconViews {
            let screenPoint = mapView.mapboxMap.point(for: coordWrapper.coordinate)
            lottieView.center = screenPoint
            glowViews[coordWrapper]?.center = screenPoint
        }
    }
}

