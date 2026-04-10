import UIKit

/// A horizontal bar of frequently used emoji reactions plus a button to
/// open the full system emoji keyboard.
///
/// ChatKit provides this as a default implementation. Consumers can present
/// it however they like (e.g. above a context menu, as a popover, etc.)
/// or replace it entirely with their own UI — the data for building a
/// custom bar is available through `ReactionConfiguration.quickReactions`.
///
/// ```
/// [👍] [❤️] [😂] [😮] [😢] [🙏] [•••]
/// ```
public final class QuickReactionBar: UIView {

    /// Called when the user picks an emoji from the quick-reaction set.
    public var onEmojiSelected: ((String) -> Void)?

    /// Called when the user taps the "…" button to open the full keyboard.
    public var onExpandRequested: (() -> Void)?

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let backgroundBlur: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.layer.cornerRadius = 22
        blur.clipsToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false
        return blur
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews() {
        addSubview(backgroundBlur)
        backgroundBlur.contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            backgroundBlur.topAnchor.constraint(equalTo: topAnchor),
            backgroundBlur.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundBlur.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundBlur.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: backgroundBlur.contentView.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: backgroundBlur.contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: backgroundBlur.contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: backgroundBlur.contentView.bottomAnchor, constant: -6),

            heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - Configure

    /// Populates the bar with the given emoji list.
    ///
    /// - Parameter emojis: The quick-reaction emojis to show. A "…" expand
    ///   button is always appended at the end.
    public func configure(emojis: [String]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for emoji in emojis {
            let button = makeEmojiButton(emoji)
            stackView.addArrangedSubview(button)
        }

        // Expand button
        let expandButton = makeExpandButton()
        stackView.addArrangedSubview(expandButton)
    }

    // MARK: - Button factory

    private func makeEmojiButton(_ emoji: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(emoji, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 32),
        ])
        button.addAction(UIAction { [weak self] _ in
            self?.onEmojiSelected?(emoji)
        }, for: .touchUpInside)

        // Highlight effect
        button.addAction(UIAction { _ in
            UIView.animate(withDuration: 0.15) { button.transform = CGAffineTransform(scaleX: 1.3, y: 1.3) }
        }, for: .touchDown)
        button.addAction(UIAction { _ in
            UIView.animate(withDuration: 0.15) { button.transform = .identity }
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel])

        return button
    }

    private func makeExpandButton() -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(
            UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        button.backgroundColor = UIColor.tertiarySystemFill
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 32),
        ])
        button.addAction(UIAction { [weak self] _ in
            self?.onExpandRequested?()
        }, for: .touchUpInside)
        return button
    }
}
