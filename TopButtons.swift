// MARK: - TopButtons.swift

import UIKit
import MapboxMaps

extension MapViewController {
    func setupTopButtons() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .black
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 20
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        view.addSubview(backButton)

        let locationButton = UIButton(type: .system)
        locationButton.setTitle("\u{1F4CD} Location", for: .normal)
        locationButton.setTitleColor(.black, for: .normal)
        locationButton.backgroundColor = .white
        locationButton.layer.cornerRadius = 20
        locationButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        locationButton.addTarget(self, action: #selector(didTapLocation), for: .touchUpInside)
        view.addSubview(locationButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            locationButton.widthAnchor.constraint(equalToConstant: 120),
            locationButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func didTapBack() {
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

    @objc private func didTapLocation() {
        if let userLocation = mapView.location.latestLocation?.coordinate {
            mapView.mapboxMap.setCamera(to: CameraOptions(center: userLocation, zoom: 16, pitch: 60))
        }
    }
}

