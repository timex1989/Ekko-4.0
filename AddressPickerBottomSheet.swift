import UIKit
import CoreLocation
import MapKit

protocol PlanYourRideDelegate: AnyObject {
    func didSelectLocation(name: String, address: String, coordinate: CLLocationCoordinate2D)
}

class PlanYourRideViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MKLocalSearchCompleterDelegate, CLLocationManagerDelegate {

    weak var delegate: PlanYourRideDelegate?

    private let titleLabel = UILabel()
    private let pillStack = UIStackView()
    private let pickupField = UITextField()
    private let destinationField = UITextField()
    private let suggestionsTable = UITableView()

    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var nearbyPOIs: [MKMapItem] = []
    private var userCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureLocationManager()
        configureSearchCompleter()
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.clipsToBounds = true

        titleLabel.text = "Plan your ride"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .black
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        let pickupNowButton = makePillButton(title: "Pickup now")
        let forMeButton = makePillButton(title: "For me")
        pillStack.axis = .horizontal
        pillStack.spacing = 8
        pillStack.distribution = .fillEqually
        pillStack.translatesAutoresizingMaskIntoConstraints = false
        pillStack.addArrangedSubview(pickupNowButton)
        pillStack.addArrangedSubview(forMeButton)
        view.addSubview(pillStack)

        let addressContainer = UIView()
        addressContainer.backgroundColor = .white
        addressContainer.layer.cornerRadius = 10
        addressContainer.layer.borderWidth = 1
        addressContainer.layer.borderColor = UIColor.black.cgColor
        addressContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addressContainer)

        configureTextField(pickupField, text: "2929 Oak Lawn Ave")
        configureTextField(destinationField, placeholder: "Where to?")
        destinationField.delegate = self

        let dottedLine = UIView()
        dottedLine.translatesAutoresizingMaskIntoConstraints = false
        dottedLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        dottedLine.backgroundColor = .clear
        DispatchQueue.main.async {
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = UIColor.black.cgColor
            shapeLayer.lineDashPattern = [2, 2]
            shapeLayer.lineWidth = 1
            shapeLayer.frame = dottedLine.bounds
            shapeLayer.path = UIBezierPath(rect: dottedLine.bounds).cgPath
            shapeLayer.fillColor = nil
            dottedLine.layer.addSublayer(shapeLayer)
        }

        let circleIcon = UIImageView(image: UIImage(systemName: "circle.fill"))
        circleIcon.tintColor = .black
        circleIcon.translatesAutoresizingMaskIntoConstraints = false
        circleIcon.widthAnchor.constraint(equalToConstant: 10).isActive = true
        circleIcon.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let squareIcon = UIImageView(image: UIImage(systemName: "stop.fill"))
        squareIcon.tintColor = .black
        squareIcon.translatesAutoresizingMaskIntoConstraints = false
        squareIcon.widthAnchor.constraint(equalToConstant: 10).isActive = true
        squareIcon.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let connectorLine = UIView()
        connectorLine.translatesAutoresizingMaskIntoConstraints = false
        connectorLine.backgroundColor = .black
        connectorLine.widthAnchor.constraint(equalToConstant: 1).isActive = true
        connectorLine.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let iconStack = UIStackView(arrangedSubviews: [circleIcon, connectorLine, squareIcon])
        iconStack.axis = .vertical
        iconStack.alignment = .center
        iconStack.spacing = 10
        iconStack.translatesAutoresizingMaskIntoConstraints = false
        iconStack.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let textFieldStack = UIStackView(arrangedSubviews: [pickupField, dottedLine, destinationField])
        textFieldStack.axis = .vertical
        textFieldStack.spacing = 12
        textFieldStack.translatesAutoresizingMaskIntoConstraints = false

        let addressStack = UIStackView(arrangedSubviews: [iconStack, textFieldStack])
        addressStack.axis = .horizontal
        addressStack.alignment = .top
        addressStack.spacing = 12
        addressStack.translatesAutoresizingMaskIntoConstraints = false
        addressContainer.addSubview(addressStack)

        suggestionsTable.delegate = self
        suggestionsTable.dataSource = self
        suggestionsTable.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        suggestionsTable.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTable.separatorStyle = .none
        suggestionsTable.backgroundColor = .white
        suggestionsTable.allowsSelection = true
        view.addSubview(suggestionsTable)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            pillStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            pillStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pillStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            addressContainer.topAnchor.constraint(equalTo: pillStack.bottomAnchor, constant: 16),
            addressContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addressContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            addressStack.topAnchor.constraint(equalTo: addressContainer.topAnchor, constant: 12),
            addressStack.bottomAnchor.constraint(equalTo: addressContainer.bottomAnchor, constant: -12),
            addressStack.leadingAnchor.constraint(equalTo: addressContainer.leadingAnchor, constant: 12),
            addressStack.trailingAnchor.constraint(equalTo: addressContainer.trailingAnchor, constant: -12),

            suggestionsTable.topAnchor.constraint(equalTo: addressContainer.bottomAnchor, constant: 16),
            suggestionsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureTextField(_ textField: UITextField, text: String? = nil, placeholder: String? = nil) {
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.text = text
        textField.textColor = .black
        textField.translatesAutoresizingMaskIntoConstraints = false

        if let placeholder = placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor.black]
            )
        }
    }

    private func makePillButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1)
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return button
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func configureSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == destinationField else { return true }
        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        searchCompleter.queryFragment = updatedText
        return true
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionsTable.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Autocomplete failed: \(error.localizedDescription)")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return destinationField.text?.isEmpty == false ? searchResults.count : nearbyPOIs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        var content = UIListContentConfiguration.subtitleCell()

        content.textProperties.font = .systemFont(ofSize: 14, weight: .semibold)
        content.secondaryTextProperties.font = .systemFont(ofSize: 13)
        content.textProperties.color = .black
        content.secondaryTextProperties.color = .darkGray
        cell.selectionStyle = .default
        cell.backgroundColor = .white

        if destinationField.text?.isEmpty == false {
            let item = searchResults[indexPath.row]
            content.text = item.title
            content.secondaryText = item.subtitle
        } else {
            let poi = nearbyPOIs[indexPath.row]
            content.text = poi.name
            content.secondaryText = poi.placemark.title
        }

        content.image = UIImage(systemName: "mappin.and.ellipse")
        content.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        destinationField.resignFirstResponder()

        if destinationField.text?.isEmpty == false {
            let selected = searchResults[indexPath.row]
            destinationField.text = selected.title
            searchResults = []
            suggestionsTable.reloadData()

            let request = MKLocalSearch.Request(completion: selected)
            let search = MKLocalSearch(request: request)
            search.start { [weak self] response, error in
                guard let self = self,
                      let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    print("❌ Could not resolve address")
                    return
                }
                self.delegate?.didSelectLocation(name: selected.title, address: selected.subtitle, coordinate: coordinate)
            }
        } else {
            let poi = nearbyPOIs[indexPath.row]
            let name = poi.name ?? "Popular Location"
            let address = poi.placemark.title ?? ""
            destinationField.text = name
            nearbyPOIs = []
            suggestionsTable.reloadData()
            delegate?.didSelectLocation(name: name, address: address, coordinate: poi.placemark.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userCoordinate = location.coordinate
        locationManager.stopUpdatingLocation()
        fetchNearbyPOIs(from: location.coordinate)
    }

    private func fetchNearbyPOIs(from coordinate: CLLocationCoordinate2D) {
        let categories = ["restaurant", "bar", "cafe", "gym", "hotel", "park", "museum", "bakery"]
        let group = DispatchGroup()
        var results: [MKMapItem] = []

        for keyword in categories {
            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = keyword
            request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 4000, longitudinalMeters: 4000)

            MKLocalSearch(request: request).start { response, _ in
                if let items = response?.mapItems {
                    results.append(contentsOf: items)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let unique = Dictionary(grouping: results, by: { $0.name ?? "" }).compactMap { $0.value.first }
            self.nearbyPOIs = Array(unique.prefix(12))
            self.suggestionsTable.reloadData()
        }
    }

    @objc private func didTapBack() {
        self.dismiss(animated: true, completion: nil)
    }
}

