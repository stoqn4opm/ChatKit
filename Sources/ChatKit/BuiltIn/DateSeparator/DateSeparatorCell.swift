import UIKit

public final class DateSeparatorCell: UICollectionViewCell {

    public static let reuseID = "DateSeparatorCell"

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let pill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.tertiarySystemBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(pill)
        pill.addSubview(label)

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pill.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            pill.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    public func configure(text: String, textColor: UIColor? = nil, pillColor: UIColor? = nil) {
        label.text = text
        if let textColor { label.textColor = textColor }
        if let pillColor { pill.backgroundColor = pillColor }
    }
}
