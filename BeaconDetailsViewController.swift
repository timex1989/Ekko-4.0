import UIKit
import MapKit
import CoreLocation

protocol BeaconDetailsDelegate: AnyObject {
    func didConfirmBeaconNavigation(to coordinate: CLLocationCoordinate2D)
}

class BeaconDetailsViewController: UIViewController {

    weak var delegate: BeaconDetailsDelegate?

    private let headerLabel = UILabel()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let distanceLabel = UILabel()
    private let offerLabel = UILabel()
    private let modesScrollView = UIScrollView()
    private let modesStack = UIStackView()
    private let goButton = UIButton(type: .system)

    private var selectedCard: UIView?
    private var selectedMode: String?

    private var beaconName: String?
    private var beaconAddress: String?
    private var beaconDistance: String?
    private var beaconOffer: String?
    private var destinationCoordinate: CLLocationCoordinate2D?

    func configure(name: String, address: String, distance: String, offer: String, coordinate: CLLocationCoordinate2D) {
        self.beaconName = name
        self.beaconAddress = address
        self.beaconDistance = distance
        self.beaconOffer = offer
        self.destinationCoordinate = coordinate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        print("🟥 BeaconDetailsViewController sheet has appeared!")

        setupSheetPresentation()
        setupLayout()
        setupModes()
        populateBeaconInfo()
    }

    private func setupSheetPresentation() {
        if let sheet = self.sheetPresentationController {
            let short = UIScreen.main.bounds.height * 0.2
            let medium = UIScreen.main.bounds.height * 0.5
            sheet.detents = [
                .custom(resolver: { _ in short }),
                .custom(resolver: { _ in medium })
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
            print("🟥 Sheet has short: \(short), medium: \(medium)")
        }
    }

    private func setupLayout() {
        headerLabel.text = "Select your beacon"
        headerLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        addressLabel.font = UIFont.systemFont(ofSize: 14)
        addressLabel.textColor = .darkGray
        addressLabel.textAlignment = .center
        addressLabel.numberOfLines = 0
        addressLabel.translatesAutoresizingMaskIntoConstraints = false

        distanceLabel.font = UIFont.systemFont(ofSize: 14)
        distanceLabel.textColor = .black
        distanceLabel.textAlignment = .center
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false

        offerLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        offerLabel.textColor = .systemGreen
        offerLabel.textAlignment = .center
        offerLabel.translatesAutoresizingMaskIntoConstraints = false

        modesScrollView.translatesAutoresizingMaskIntoConstraints = false
        modesScrollView.alwaysBounceVertical = true

        modesStack.axis = .vertical
        modesStack.spacing = 12
        modesStack.translatesAutoresizingMaskIntoConstraints = false

        modesScrollView.addSubview(modesStack)
        view.addSubview(headerLabel)
        view.addSubview(nameLabel)
        view.addSubview(addressLabel)
        view.addSubview(distanceLabel)
        view.addSubview(offerLabel)
        view.addSubview(modesScrollView)
        view.addSubview(goButton)

        goButton.setTitle("GO", for: .normal)
        goButton.setTitleColor(.white, for: .normal)
        goButton.backgroundColor = .black
        goButton.layer.cornerRadius = 8
        goButton.translatesAutoresizingMaskIntoConstraints = false
        goButton.addTarget(self, action: #selector(goButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            addressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            distanceLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 4),
            distanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            distanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            offerLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 6),
            offerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            offerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            modesScrollView.topAnchor.constraint(equalTo: offerLabel.bottomAnchor, constant: 20),
            modesScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            modesScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            modesScrollView.bottomAnchor.constraint(equalTo: goButton.topAnchor, constant: -20),

            modesStack.topAnchor.constraint(equalTo: modesScrollView.topAnchor),
            modesStack.leadingAnchor.constraint(equalTo: modesScrollView.leadingAnchor),
            modesStack.trailingAnchor.constraint(equalTo: modesScrollView.trailingAnchor),
            modesStack.bottomAnchor.constraint(equalTo: modesScrollView.bottomAnchor),
            modesStack.widthAnchor.constraint(equalTo: modesScrollView.widthAnchor),

            goButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            goButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            goButton.widthAnchor.constraint(equalToConstant: 120),
            goButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupModes() {
        let modes: [(icon: String, title: String, subtitle: String)] = [
            ("figure.walk", "Walk", "5 min · 0.3 mi · 40 cal"),
            ("figure.run", "Run", "2 min · 0.3 mi · 65 cal"),
            ("bicycle", "Cycle", "1 min · 0.3 mi · 15 cal"),
            ("car", "Drive", "1 min · 0.3 mi · 5 cal")
        ]

        for (icon, title, subtitle) in modes {
            let card = createModeCard(icon: icon, title: title, subtitle: subtitle)
            modesStack.addArrangedSubview(card)
        }
    }

    private func populateBeaconInfo() {
        nameLabel.text = beaconName ?? "Selected Beacon"
        addressLabel.text = beaconAddress ?? "Unknown address"
        distanceLabel.text = beaconDistance ?? "Unknown distance"
        offerLabel.text = beaconOffer ?? ""
    }

    private func createModeCard(icon: String, title: String, subtitle: String) -> UIView {
        let card = UIView()
        card.layer.borderColor = UIColor.black.cgColor
        card.layer.borderWidth = 1
        card.layer.cornerRadius = 12
        card.backgroundColor = .white
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 70).isActive = true
        card.accessibilityLabel = title

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .black
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .darkGray

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let horizontalStack = UIStackView(arrangedSubviews: [iconView, textStack])
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 12
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(horizontalStack)

        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            horizontalStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            horizontalStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            horizontalStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCard(_:)))
        card.addGestureRecognizer(tapGesture)

        return card
    }

    @objc private func didTapCard(_ gesture: UITapGestureRecognizer) {
        guard let selected = gesture.view else { return }

        selectedCard?.layer.borderWidth = 1
        selectedCard?.backgroundColor = .white

        selected.layer.borderWidth = 2
        selected.backgroundColor = UIColor(white: 0.95, alpha: 1)
        selectedCard = selected

        selectedMode = selected.accessibilityLabel
    }

    @objc private func goButtonTapped() {
        guard let coordinate = destinationCoordinate else {
            print("❌ No destination provided.")
            return
        }
        delegate?.didConfirmBeaconNavigation(to: coordinate)
        dismiss(animated: true)
    }
}

