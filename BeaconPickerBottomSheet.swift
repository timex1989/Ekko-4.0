import UIKit

class BeaconPickerBottomSheet: UIView {

    private let addressCard = UIView()
    private let carCard = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        // MARK: - Address Card (Top Search Card)
        addressCard.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        addressCard.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addressCard)

        NSLayoutConstraint.activate([
            addressCard.widthAnchor.constraint(equalToConstant: 339),
            addressCard.heightAnchor.constraint(equalToConstant: 150),
            addressCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            addressCard.topAnchor.constraint(equalTo: topAnchor, constant: 110)
        ])

        // MARK: - Car Card (Bottom Card Preview)
        carCard.backgroundColor = .white
        carCard.layer.cornerRadius = 20
        carCard.layer.shadowColor = UIColor.black.cgColor
        carCard.layer.shadowOpacity = 0.1
        carCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        carCard.layer.shadowRadius = 8
        carCard.translatesAutoresizingMaskIntoConstraints = false
        addSubview(carCard)

        let carTitle = UILabel()
        carTitle.text = "Premium - Car"
        carTitle.font = UIFont.boldSystemFont(ofSize: 16)

        let carPrice = UILabel()
        carPrice.text = "Price: $5/km"
        carPrice.font = UIFont.systemFont(ofSize: 14)
        carPrice.textColor = .gray

        let carStack = UIStackView(arrangedSubviews: [carTitle, carPrice])
        carStack.axis = .vertical
        carStack.spacing = 4
        carStack.translatesAutoresizingMaskIntoConstraints = false
        carCard.addSubview(carStack)

        NSLayoutConstraint.activate([
            carCard.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            carCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            carCard.widthAnchor.constraint(equalToConstant: 272),
            carCard.heightAnchor.constraint(equalToConstant: 178),

            carStack.centerYAnchor.constraint(equalTo: carCard.centerYAnchor),
            carStack.leadingAnchor.constraint(equalTo: carCard.leadingAnchor, constant: 16)
        ])
    }
}

