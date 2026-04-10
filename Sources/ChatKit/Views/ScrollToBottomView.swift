import UIKit

/// A floating "scroll to bottom" pill with an unread message count badge.
///
/// Taps fire the `onTap` closure. The badge hides automatically when
/// `unreadCount` is zero.
public final class ScrollToBottomView: UIView, ScrollToBottomProviding {

    // MARK: - Public

    /// Called when the user taps the pill.
    public var onTap: (() -> Void)?

    /// Number of unread messages to show in the badge.
    /// Setting this to 0 hides the badge; any positive value shows it.
    public var unreadCount: Int = 0 {
        didSet { updateBadge() }
    }

    // MARK: - Subviews

    private let pill = UIView()
    private let arrowImageView = UIImageView()
    private let badgeLabel = UILabel()
    private let badgeBackground = UIView()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Setup

    private func setupViews() {
        // Pill container
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.backgroundColor = .systemBackground
        pill.layer.cornerRadius = 20
        pill.layer.shadowColor = UIColor.black.cgColor
        pill.layer.shadowOpacity = 0.15
        pill.layer.shadowOffset = CGSize(width: 0, height: 2)
        pill.layer.shadowRadius = 6
        addSubview(pill)

        // Down-arrow
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        arrowImageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        arrowImageView.tintColor = .label
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.contentMode = .scaleAspectFit
        pill.addSubview(arrowImageView)

        // Badge background
        badgeBackground.translatesAutoresizingMaskIntoConstraints = false
        badgeBackground.backgroundColor = .systemBlue
        badgeBackground.layer.cornerRadius = 10
        badgeBackground.isHidden = true
        addSubview(badgeBackground)

        // Badge label
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = .systemFont(ofSize: 12, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeBackground.addSubview(badgeLabel)

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        pill.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            // Pill
            pill.centerXAnchor.constraint(equalTo: centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: centerYAnchor),
            pill.widthAnchor.constraint(equalToConstant: 40),
            pill.heightAnchor.constraint(equalToConstant: 40),

            // Arrow centered in pill
            arrowImageView.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            arrowImageView.centerYAnchor.constraint(equalTo: pill.centerYAnchor),

            // Badge sits at top-trailing of pill
            badgeBackground.centerYAnchor.constraint(equalTo: pill.topAnchor, constant: 2),
            badgeBackground.centerXAnchor.constraint(equalTo: pill.trailingAnchor, constant: -2),
            badgeBackground.heightAnchor.constraint(equalToConstant: 20),
            badgeBackground.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),

            // Badge label inside badge background
            badgeLabel.topAnchor.constraint(equalTo: badgeBackground.topAnchor, constant: 2),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeBackground.bottomAnchor, constant: -2),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeBackground.leadingAnchor, constant: 5),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeBackground.trailingAnchor, constant: -5),

            // Self sizing
            widthAnchor.constraint(equalToConstant: 60),
            heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // MARK: - Badge

    private func updateBadge() {
        if unreadCount <= 0 {
            badgeBackground.isHidden = true
        } else {
            badgeBackground.isHidden = false
            badgeLabel.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
        }
    }

    // MARK: - Actions

    @objc private func didTap() {
        onTap?()
    }
}
