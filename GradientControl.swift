// MARK: - GradientControl.swift

import UIKit
import MapboxMaps

extension MapViewController {

    internal func startAnimatingGradient() {
        stopGradient()
        animationPhase = 0.0

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.015, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.animationPhase += 0.01
            if self.animationPhase > 1.0 {
                self.animationPhase = 0.0 // 🔁 Loop
            }

            let head = 1.0 - self.animationPhase

            let expression: [Any] = [
                "interpolate", ["linear"], ["line-progress"],
                0.0, ["rgba", 255, 255, 255, 0],
                head - 0.001, ["rgba", 255, 255, 255, 0],
                head, ["rgba", 255, 255, 255, 1],
                1.0, ["rgba", 255, 255, 255, 1]
            ]

            try? self.mapView.mapboxMap.style.setLayerProperty(
                for: self.routeLayerId,
                property: "line-gradient",
                value: expression
            )
        }
    }

    @objc internal func stopGradient() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    @objc internal func restartGradientIfNeeded() {
        if mapView.mapboxMap.style.layerExists(withId: routeLayerId) {
            startAnimatingGradient()
        }
    }

    internal func clearPreviewLine() {
        stopGradient()
        try? mapView.mapboxMap.style.removeLayer(withId: routeLayerId)
        try? mapView.mapboxMap.style.removeLayer(withId: casingLayerId)
        try? mapView.mapboxMap.style.removeSource(withId: previewSourceId)
    }
}

