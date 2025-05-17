import UIKit
import MapboxMaps
import CoreLocation
import MapboxNavigationUIKit
import MapboxNavigationCore

@MainActor
final class EkkoNavigationController {
    static func startNavigation(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        placeName: String,
        placeAddress: String,
        in presentingVC: UIViewController
    ) async {
        let provider = MapboxNavigationProvider(coreConfig: .init(locationSource: .live))
        let mapboxNavigation = provider.mapboxNavigation

        let options = NavigationRouteOptions(coordinates: [origin, destination])
        options.profileIdentifier = .automobileAvoidingTraffic

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)
        let result = await request.result

        switch result {
        case .failure(let error):
            print("❌ Failed to generate route: \(error)")
        case .success(let routes):
            let navVC = NavigationViewController(
                navigationRoutes: routes,
                navigationOptions: NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: provider.routeVoiceController,
                    eventsManager: provider.eventsManager()
                )
            )

            navVC.title = placeName
            navVC.modalPresentationStyle = .overFullScreen
            navVC.routeLineTracksTraversal = true

            presentingVC.present(navVC, animated: true)
        }
    }
}

