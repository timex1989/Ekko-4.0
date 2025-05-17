import FloatingPanel
import UIKit

final class ShortFloatingPanelLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition { .bottom }
    var initialState: FloatingPanelState { .tip }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        guard position == .bottom else { return nil }
        return UIScreen.main.bounds.height * 0.8 // Show only top 20%
    }

    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .tip: FloatingPanelLayoutAnchor(
                absoluteInset: UIScreen.main.bounds.height * 0.8,
                edge: .top,
                referenceGuide: .superview
            ),
            .half: FloatingPanelLayoutAnchor(
                fractionalInset: 0.5,
                edge: .top,
                referenceGuide: .superview
            ),
            .full: FloatingPanelLayoutAnchor(
                absoluteInset: 16,
                edge: .top,
                referenceGuide: .safeArea
            )
        ]
    }
}

