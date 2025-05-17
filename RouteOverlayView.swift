import UIKit

class RouteOverlayView: UIView {
    let shapeLayer = CAShapeLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.addSublayer(shapeLayer)
        shapeLayer.fillColor = nil // <-- Prevents any fill (NO POLYGON!)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func drawRoute(points: [CGPoint]) {
        guard points.count > 1 else { shapeLayer.path = nil; return }
        let path = UIBezierPath()
        path.move(to: points[0])
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 5.0
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.fillColor = nil // <-- Absolutely crucial: no fill!
    }
}

