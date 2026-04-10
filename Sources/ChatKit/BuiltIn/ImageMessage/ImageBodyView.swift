import UIKit

/// The body view for real image messages (local files and remote URLs).
///
/// Displays an image with a loading spinner. The view uses a fixed size
/// so the bubble dimensions are known before the image loads.
/// Installed inside `MessageBubbleCell` by `ImageMessageRenderer`.
final class ImageBodyView: UIView {

    let imageContainer: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.systemGray5
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        return imageView
    }()

    let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    /// Tracks whether KVO on `imageContainer.image` is active.
    var isObservingImage = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageContainer)
        addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            // Fixed body size
            widthAnchor.constraint(equalToConstant: 220),
            heightAnchor.constraint(equalToConstant: 220),

            // Image fills with small inset
            imageContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            imageContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            imageContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            // Spinner centered
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}
