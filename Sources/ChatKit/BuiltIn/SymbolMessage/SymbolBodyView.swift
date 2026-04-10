import UIKit

/// The body view for SF Symbol messages.
///
/// Displays a large SF Symbol glyph at a fixed size.
/// Installed inside `MessageBubbleCell` by `SymbolMessageRenderer`.
final class SymbolBodyView: UIView {

    let imageContainer: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.systemGray5
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageContainer)

        NSLayoutConstraint.activate([
            // Fixed body size
            widthAnchor.constraint(equalToConstant: 200),
            heightAnchor.constraint(equalToConstant: 200),

            // Symbol image with small inset
            imageContainer.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            imageContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            imageContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}
