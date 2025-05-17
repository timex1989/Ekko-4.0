import UIKit
import MapboxMaps
import MapboxCoreMaps

class BeaconManager {

    static func addPulsingBeacon(
        to mapView: MapView,
        at coordinate: CLLocationCoordinate2D,
        with image: UIImage,
        imageId: String,
        sourceId: String,
        layerId: String,
        duration: TimeInterval = 1.0,
        frameCount: Int = 30
    ) {
        var frames: [UIImage] = []

        for i in 0..<frameCount {
            let t = CGFloat(i) / CGFloat(frameCount - 1)
            let scale = 1.0 + 0.3 * t

            UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: image.size.width / 2, y: image.size.height / 2)
            context?.scaleBy(x: scale, y: scale)
            image.draw(in: CGRect(
                x: -image.size.width / 2,
                y: -image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            ))
            let frame = UIGraphicsGetImageFromCurrentImageContext()
            if let frame = frame {
                frames.append(frame)
            }
            UIGraphicsEndImageContext()
        }

        var frameIndex = 0
        Timer.scheduledTimer(withTimeInterval: duration / Double(frameCount), repeats: true) { _ in
            let currentFrame = frames[frameIndex % frames.count]
            try? mapView.mapboxMap.style.removeImage(withId: imageId)
            try? mapView.mapboxMap.style.addImage(currentFrame, id: imageId)
            frameIndex += 1
        }

        var source = GeoJSONSource(id: sourceId)
        source.data = .feature(Feature(geometry: .point(Point(coordinate))))
        try? mapView.mapboxMap.style.addSource(source)

        var layer = SymbolLayer(id: layerId, source: sourceId)
        layer.iconImage = .constant(.name(imageId))
        layer.iconAllowOverlap = .constant(true)
        layer.iconIgnorePlacement = .constant(true)
        try? mapView.mapboxMap.style.addLayer(layer)
    }
}

