// MARK: - MapSetup.swift

import UIKit
import MapboxMaps
import CoreLocation

extension MapViewController {
    func setupMapView() {
        let mapInitOptions = MapInitOptions(styleURI: LightingHelper.getStyleUri())
        mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)
        mapView.location.options.puckType = .puck2D()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        mapView.mapboxMap.onNext(event: .mapLoaded) { [weak self] _ in
            self?.handleMapLoaded()
        }

        mapView.gestures.singleTapGestureRecognizer.addTarget(self, action: #selector(handleMapTap(_:)))
    }

    private func handleMapLoaded() {
        guard let userLocation = mapView.location.latestLocation?.coordinate else { return }
        mapView.mapboxMap.setCamera(to: CameraOptions(center: userLocation, zoom: 16, pitch: 60))

        let plannerVC = PlanYourRideViewController()
        plannerVC.delegate = self
        plannerVC.modalPresentationStyle = .pageSheet
        if let sheet = plannerVC.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in context.maximumDetentValue * 0.8 })]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        self.present(plannerVC, animated: true)
    }

    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: mapView)
        let coordinate = mapView.mapboxMap.coordinate(for: tapPoint)
        print("🗺️ Map tapped at: \(coordinate.latitude), \(coordinate.longitude)")
        // Example: addMultipleBeacons(at: [coordinate])
    }
}

