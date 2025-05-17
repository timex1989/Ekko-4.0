import UIKit
import MapboxMaps
import CoreLocation
import MapKit
import FloatingPanel

class HomeViewController: UIViewController, PlanYourRideDelegate {

    private var mapView: MapView!
    private var floatingPanel: FloatingPanelController!
    private var beaconCoordinates: [CLLocationCoordinate2D] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupMap()
        setupTopButtons()
        setupFloatingPanel()
    }

    private func setupMap() {
        let dallasCenter = CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970)
        let options = MapInitOptions(
            cameraOptions: CameraOptions(center: dallasCenter, zoom: 13)
        )
        mapView = MapView(frame: .zero, mapInitOptions: options)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupTopButtons() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .black
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 22
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        view.addSubview(backButton)

        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location"), for: .normal)
        locationButton.setTitle(" Location", for: .normal)
        locationButton.setTitleColor(.black, for: .normal)
        locationButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        locationButton.tintColor = .black
        locationButton.backgroundColor = .white
        locationButton.layer.cornerRadius = 22
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        locationButton.addTarget(self, action: #selector(didTapRecenter), for: .touchUpInside)
        view.addSubview(locationButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            locationButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locationButton.heightAnchor.constraint(equalToConstant: 44),
            locationButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 110)
        ])
    }

    private func setupFloatingPanel() {
        floatingPanel = FloatingPanelController()
        floatingPanel.contentMode = .fitToBounds
        floatingPanel.isRemovalInteractionEnabled = false

        let rideVC = PlanYourRideViewController()
        rideVC.delegate = self

        floatingPanel.set(contentViewController: rideVC)
        floatingPanel.surfaceView.layer.cornerRadius = 24
        floatingPanel.surfaceView.layer.masksToBounds = true
        floatingPanel.surfaceView.backgroundColor = .white
        floatingPanel.surfaceView.grabberHandle.isHidden = false
        floatingPanel.layout = BeaconRevealFloatingPanelLayout()

        floatingPanel.addPanel(toParent: self)
    }

    @objc private func didTapBack() {
        print("🔙 Reopening search panel")
        setupFloatingPanel()
    }

    @objc private func didTapRecenter() {
        let userLocation = mapView.location.latestLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970)
        let cameraOptions = CameraOptions(center: userLocation, zoom: 16)
        mapView.camera.ease(to: cameraOptions, duration: 1.0, curve: .easeInOut)
    }

    // MARK: - PlanYourRideDelegate
    func didSelectLocation(name: String, address: String, coordinate: CLLocationCoordinate2D) {
        print("✅ Selected: \(name), \(address), Coordinate: \(coordinate)")

        let cameraOptions = CameraOptions(center: coordinate, zoom: 15)
        mapView.camera.ease(to: cameraOptions, duration: 1.0, curve: .easeInOut)

        beaconCoordinates = [
            coordinate,
            CLLocationCoordinate2D(latitude: coordinate.latitude + 0.001, longitude: coordinate.longitude + 0.001),
            CLLocationCoordinate2D(latitude: coordinate.latitude - 0.001, longitude: coordinate.longitude - 0.001)
        ]

        // TODO: Add your beacon display logic here
        // Example: addMultipleBeacons(at: beaconCoordinates)

        floatingPanel.removePanelFromParent(animated: true)
    }

    // You can implement your route drawing and beacon display logic below as needed
}

final class BeaconRevealFloatingPanelLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition { .bottom }
    var initialState: FloatingPanelState { .full }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        return UIScreen.main.bounds.height * 0.6
    }

    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(
                absoluteInset: UIScreen.main.bounds.height * 0.6,
                edge: .top,
                referenceGuide: .superview
            )
        ]
    }
}

