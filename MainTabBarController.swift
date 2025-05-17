import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = false
        tabBar.tintColor = .white

        let mapVC = MapViewController()
        mapVC.tabBarItem = UITabBarItem(title: "Live", image: UIImage(systemName: "map"), tag: 0)

        let socialsVC = SocialsViewController()
        socialsVC.tabBarItem = UITabBarItem(title: "Socials", image: UIImage(systemName: "person.3"), tag: 1)

        let challengeVC = ChallengeViewController()
        challengeVC.tabBarItem = UITabBarItem(title: "Challenge", image: UIImage(systemName: "flag"), tag: 2)

        let accountVC = AccountViewController()
        accountVC.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person.crop.circle"), tag: 3)

        viewControllers = [mapVC, socialsVC, challengeVC, accountVC]
        selectedIndex = 0 // Start with Live tab
    }
}

