import UIKit
import LocalAuthentication
import AVFoundation

class SplashViewController: UIViewController {

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        print("🟢 SplashViewController loaded")

        // Start the beacon animation after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            print("🟢 Starting beacon animation")
            self.showBeaconVideoAnimation()
        }
    }

    private func showBeaconVideoAnimation() {
        guard let path = Bundle.main.path(forResource: "beacon-animation", ofType: "mp4") else {
            print("❌ Beacon video not found in bundle")
            return
        }

        print("✅ Beacon video found at path: \(path)")
        let url = URL(fileURLWithPath: path)
        player = AVPlayer(url: url)

        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspectFill

        if let playerLayer = playerLayer {
            // Fade in the animation layer
            playerLayer.opacity = 0
            view.layer.addSublayer(playerLayer)

            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0
            fadeIn.toValue = 1
            fadeIn.duration = 0.6
            playerLayer.add(fadeIn, forKey: "fadeIn")
            playerLayer.opacity = 1
        }

        // Optional: loop the video if needed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loopVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )

        player?.play()
        print("▶️ Video playback started")

        // Start Face ID auth after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            print("🟣 Attempting Face ID auth")
            self.authenticateWithFaceID()
        }
    }

    @objc private func loopVideo() {
        print("🔁 Looping video")
        player?.seek(to: .zero)
        player?.play()
    }

    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock EKKO") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Face ID succeeded")
                        self.goToHome()
                    } else {
                        print("❌ Face ID failed")
                    }
                }
            }
        } else {
            print("⚠️ Face ID not available, going to Home")
            goToHome()
        }
    }

    private func goToHome() {
        print("🚪 Navigating to MainTabBarController")
        UIView.animate(withDuration: 0.4, animations: {
            self.playerLayer?.opacity = 0
        }) { _ in
            let tabBarVC = MainTabBarController()
            tabBarVC.modalPresentationStyle = .fullScreen
            self.view.window?.rootViewController = tabBarVC
        }
    }
}

