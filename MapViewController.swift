import UIKit
import MapboxMaps
import CoreLocation
import MapKit
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxDirections
import Turf
import FloatingPanel
import Lottie

// --- Hashable wrapper for CLLocationCoordinate2D ---
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

class MapViewController: UIViewController, PlanYourRideDelegate, BeaconDetailsDelegate {

    internal var mapView: MapView!
    internal let previewSourceId = "preview-line-source"
    internal let routeLayerId = "route-line"
    internal let casingLayerId = "route-casing"
    internal var animationTimer: Timer?
    internal var animationPhase: Double = 0.0
    internal var lastStartCoordinate: CLLocationCoordinate2D?
    internal var lastEndCoordinate: CLLocationCoordinate2D?
    private var shortPanel: FloatingPanelController?
    private var routeOverlayView: RouteOverlayView?

    private var currentRouteCoordinates: [CLLocationCoordinate2D] = []

    // --- DO NOT declare lottieBeaconViews or beacon methods here. ---

    // MARK: - PlanYourRideDelegate REQUIRED
    func didSelectLocation(name: String, address: String, coordinate: CLLocationCoordinate2D) {
        print("didSelectLocation called with name: \(name), address: \(address), coordinate: \(coordinate)")
        addMultipleBeacons(at: [coordinate])  // <-- This will show your Lottie beacon!
        mapView.mapboxMap.setCamera(to: CameraOptions(center: coordinate, zoom: 16, pitch: 20))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupMapView()
        setupTopButtons()
        setupBeaconPanelButton()

        routeOverlayView = RouteOverlayView(frame: .zero)
        routeOverlayView?.isUserInteractionEnabled = false
        if let overlay = routeOverlayView {
            view.addSubview(overlay)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(stopGradient), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restartGradientIfNeeded), name: UIApplication.didBecomeActiveNotification, object: nil)

        mapView?.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            self?.updateRouteOverlayPolyline()
            self?.updateLottieBeaconPositions()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        routeOverlayView?.frame = mapView.frame
        updateRouteOverlayPolyline()
        updateLottieBeaconPositions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGradient()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func didConfirmBeaconNavigation(to coordinate: CLLocationCoordinate2D) {
        clearPreviewLine()

        guard let userCoord = mapView.location.latestLocation?.coordinate else {
            print("❌ No user location found.")
            return
        }

        let cameraCenter = CLLocationCoordinate2D(
            latitude: (userCoord.latitude + coordinate.latitude) / 2,
            longitude: (userCoord.longitude + coordinate.longitude) / 2
        )

        let camera = CameraOptions(
            center: cameraCenter,
            zoom: 11.5,
            bearing: 0,
            pitch: 0
        )

        mapView.camera.ease(to: camera, duration: 1.0, curve: .easeOut)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            Task {
                await EkkoNavigationController.startNavigation(
                    from: userCoord,
                    to: coordinate,
                    placeName: "Selected Beacon",
                    placeAddress: "Navigating to Beacon",
                    in: self
                )
            }
        }
    }

    private func setupBeaconPanelButton() {
        let beaconPanelButton = UIButton(type: .system)
        beaconPanelButton.setTitle("Show Beacon Panel", for: .normal)
        beaconPanelButton.setTitleColor(.white, for: .normal)
        beaconPanelButton.backgroundColor = .systemBlue
        beaconPanelButton.layer.cornerRadius = 10
        beaconPanelButton.translatesAutoresizingMaskIntoConstraints = false
        beaconPanelButton.addTarget(self, action: #selector(showShortBeaconPanel), for: .touchUpInside)
        view.addSubview(beaconPanelButton)

        NSLayoutConstraint.activate([
            beaconPanelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            beaconPanelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            beaconPanelButton.widthAnchor.constraint(equalToConstant: 200),
            beaconPanelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func showShortBeaconPanel() {
        if shortPanel != nil {
            print("⚠️ Panel already shown.")
            return
        }

        let fpc = FloatingPanelController()
        fpc.surfaceView.grabberHandle.isHidden = false
        fpc.surfaceView.layer.cornerRadius = 20
        fpc.contentMode = .fitToBounds

        let panelVC = UIViewController()
        panelVC.view.backgroundColor = .white

        let label = UILabel()
        label.text = "🔔 Beacon Info Panel"
        label.textColor = .black
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        panelVC.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: panelVC.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: panelVC.view.centerYAnchor)
        ])

        fpc.set(contentViewController: panelVC)
        fpc.addPanel(toParent: self)

        print("✅ Floating Panel appeared with default layout")
        shortPanel = fpc
    }

    // ==============================
    // ROUTE OVERLAY DRAWING
    // ==============================

    func showOverlayRoutePolyline(with coordinates: [CLLocationCoordinate2D]) {
        self.currentRouteCoordinates = coordinates
        updateRouteOverlayPolyline()

        // ---- ANIMATED DRAW-ON EFFECT ----
        routeOverlayView?.shapeLayer.removeAllAnimations()
        routeOverlayView?.shapeLayer.strokeEnd = 1.0 // show full when animation starts
        let drawAnimation = CABasicAnimation(keyPath: "strokeEnd")
        drawAnimation.fromValue = 0
        drawAnimation.toValue = 1
        drawAnimation.duration = 2.0   // Adjust duration as desired
        drawAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        drawAnimation.repeatCount = .infinity
        drawAnimation.autoreverses = false
        drawAnimation.isRemovedOnCompletion = false
        routeOverlayView?.shapeLayer.add(drawAnimation, forKey: "routeDrawOn")
    }

    func updateRouteOverlayPolyline() {
        guard let mapView = mapView, currentRouteCoordinates.count > 1 else { return }
        let points = currentRouteCoordinates.map { mapView.mapboxMap.point(for: $0) }
        routeOverlayView?.drawRoute(points: points)
    }

    // All Lottie handling is in the extension below.

    // ==============================
    // ROUTE FETCH EXAMPLE
    // ==============================

    func drawPreviewLine(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        clearPreviewLine()
        animationPhase = 0.0

        lastStartCoordinate = start
        lastEndCoordinate = end

        fetchRouteFromAPI(start: start, end: end) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let coordinates):
                    self.showOverlayRoutePolyline(with: coordinates)
                case .failure(let error):
                    print("❌ Route fetch failed: \(error)")
                }
            }
        }
    }

    internal func fetchRouteFromAPI(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, completion: @escaping (Result<[CLLocationCoordinate2D], Error>) -> Void) {
        let token = "pk.eyJ1IjoidGltZXgxOTg5IiwiYSI6ImNtOGNhZ253bjF3dG4ybm9teHA4NWc3b24ifQ.h3sZGLMbj2TMt0K_UuBHrQ"
        let coordinates = "\(start.longitude),\(start.latitude);\(end.longitude),\(end.latitude)"
        let urlStr = "https://api.mapbox.com/directions/v5/mapbox/walking/\(coordinates)?geometries=geojson&overview=full&access_token=\(token)"

        guard let url = URL(string: urlStr) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let routes = json?["routes"] as? [[String: Any]],
                   let geometry = routes.first?["geometry"] as? [String: Any],
                   let coords = geometry["coordinates"] as? [[Double]] {
                    let points = coords.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
                    completion(.success(points))
                } else {
                    completion(.failure(NSError(domain: "Malformed response", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - MapViewController Extension for Lottie Beacon Handling

extension MapViewController {

    // MARK: - Associated Object for Lottie Beacons
    private var lottieBeaconViews: [BeaconCoordinate: LottieAnimationView] {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.lottieBeacons) as? [BeaconCoordinate: LottieAnimationView] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.lottieBeacons, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private struct AssociatedKeys {
        static var lottieBeacons = "lottieBeaconViews"
    }

    // MARK: - Add Multiple Lottie Beacons with PRINT TESTS
    internal func addMultipleBeacons(at coordinates: [CLLocationCoordinate2D]) {
        // Print test for bundle presence
        if let url = Bundle.main.url(forResource: "Bounce 7", withExtension: "json") {
            print("✅ Bounce 7.json found at: \(url)")
        } else {
            print("❌ Bounce 7.json NOT found in bundle!")
        }

        // Remove old beacons
        for view in lottieBeaconViews.values {
            view.removeFromSuperview()
        }
        lottieBeaconViews = [:]

        // Add new Lottie beacons
        for coord in coordinates {
            // Check again inside loop for safety
            guard let _ = Bundle.main.url(forResource: "Bounce 7", withExtension: "json") else {
                print("❌ Bounce 7.json not found in bundle! Skipping beacon at \(coord.latitude), \(coord.longitude)")
                continue
            }
            let lottieView = LottieAnimationView(name: "Bounce 7")
            lottieView.frame = CGRect(x: 0, y: 0, width: 120, height: 120) // Bigger beacon
            lottieView.loopMode = .loop
            lottieView.backgroundBehavior = .pauseAndRestore
            lottieView.contentMode = .scaleAspectFit
            lottieView.animationSpeed = 1.5   // Faster animation
            lottieView.play()
            view.addSubview(lottieView)
            view.bringSubviewToFront(lottieView) // Ensure on top

            let screenPoint = mapView.mapboxMap.point(for: coord)
            lottieView.center = screenPoint

            var views = lottieBeaconViews
            views[BeaconCoordinate(coordinate: coord)] = lottieView
            lottieBeaconViews = views

            print("✅ Lottie beacon ADDED and PLAYING at \(coord.latitude), \(coord.longitude)")
        }

        // Sync positions on map move (only set once ideally)
        mapView.mapboxMap.onNext(event: .cameraChanged) { [weak self] _ in
            self?.updateLottieBeaconPositions()
        }
    }

    // MARK: - Update Beacon Positions
    private func updateLottieBeaconPositions() {
        for (coordWrapper, lottieView) in lottieBeaconViews {
            let screenPoint = mapView.mapboxMap.point(for: coordWrapper.coordinate)
            lottieView.center = screenPoint
        }
    }
}

