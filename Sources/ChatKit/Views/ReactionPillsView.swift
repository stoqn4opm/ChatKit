import UIKit

/// A horizontal row of reaction pills shown below a message bubble.
///
/// Each pill shows an emoji and its count. If the current user has
/// reacted with that emoji, the pill is highlighted. An optional "+"
/// button at the end lets users add new reactions.
///
/// ```
/// [😀 3] [❤️ 2] [+]
/// ```
///
/// All interactive elements are `UIButton` subclasses so that they
/// automatically prevent `UICollectionView` from firing
/// `didSelectItemAt` when the user taps a pill or the add button.
final class ReactionPillsView: UIView {

    /// Called when the user taps an existing reaction pill.
    /// Parameter: the emoji string that was tapped.
    var onReactionTapped: ((String) -> Void)?

    /// Called when the user taps the "+" add-reaction button.
    var onAddTapped: (() -> Void)?

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        button.setImage(
            UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        button.backgroundColor = UIColor.tertiarySystemBackground
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28),
        ])
        return button
    }()

    // MARK: - State

    private var showAddButton = true

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    /// Updates the pills to match the given reaction groups.
    ///
    /// - Parameters:
    ///   - groups: The reaction groups to display.
    ///   - maxVisible: Maximum number of distinct emoji pills to show.
    ///   - currentSender: The current user, used to highlight "my" reactions.
    ///   - showAdd: Whether to show the "+" button.
    func configure(groups: [ReactionGroup],
                   maxVisible: Int,
                   currentSender: ChatMessage.Sender,
                   showAdd: Bool) {
        showAddButton = showAdd

        // Disable implicit CALayer animations so that cornerRadius,
        // borderWidth, and backgroundColor don't animate from 0 when
        // pills are rebuilt during an animated snapshot apply.
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Remove existing pills
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard !groups.isEmpty || showAdd else {
            isHidden = true
            CATransaction.commit()
            return
        }
        isHidden = groups.isEmpty && !showAdd

        // Add pills for visible groups
        let visibleGroups = Array(groups.prefix(maxVisible))
        let overflowCount = groups.count - maxVisible

        for group in visibleGroups {
            let pill = makeReactionPill(
                emoji: group.emoji,
                count: group.count,
                isHighlighted: group.containsSender(currentSender))
            stackView.addArrangedSubview(pill)
        }

        // Overflow pill if needed
        if overflowCount > 0 {
            let overflowPill = makeOverflowPill(count: overflowCount)
            stackView.addArrangedSubview(overflowPill)
        }

        // Add button
        if showAdd {
            stackView.addArrangedSubview(addButton)
        }

        CATransaction.commit()
    }

    // MARK: - Pill Factory

    private func makeReactionPill(emoji: String, count: Int,
                                  isHighlighted: Bool) -> UIButton {
        let pillButton = ReactionPillButton(type: .custom)
        pillButton.emoji = emoji

        pillButton.titleLabel?.font = .systemFont(ofSize: 13)
        pillButton.setTitle(count > 1 ? "\(emoji) \(count)" : emoji, for: .normal)
        pillButton.setTitleColor(.label, for: .normal)

        pillButton.layer.cornerRadius = 14
        pillButton.backgroundColor = isHighlighted
            ? UIColor.systemBlue.withAlphaComponent(0.15)
            : UIColor.tertiarySystemBackground
        pillButton.layer.borderWidth = isHighlighted ? 1 : 0
        pillButton.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.4).cgColor

        pillButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        pillButton.translatesAutoresizingMaskIntoConstraints = false
        pillButton.heightAnchor.constraint(equalToConstant: 28).isActive = true

        pillButton.addTarget(self, action: #selector(reactionPillTapped(_:)),
                             for: .touchUpInside)

        return pillButton
    }

    private func makeOverflowPill(count: Int) -> UIButton {
        let overflowButton = UIButton(type: .custom)

        overflowButton.titleLabel?.font = .systemFont(ofSize: 13)
        overflowButton.setTitle("+\(count)", for: .normal)
        overflowButton.setTitleColor(.secondaryLabel, for: .normal)

        overflowButton.layer.cornerRadius = 14
        overflowButton.backgroundColor = UIColor.tertiarySystemBackground

        overflowButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        overflowButton.translatesAutoresizingMaskIntoConstraints = false
        overflowButton.heightAnchor.constraint(equalToConstant: 28).isActive = true

        // Tapping overflow shows all reactions (same as add)
        overflowButton.addTarget(self, action: #selector(addButtonTapped),
                                 for: .touchUpInside)

        return overflowButton
    }

    // MARK: - Actions

    @objc private func reactionPillTapped(_ sender: ReactionPillButton) {
        guard let emoji = sender.emoji else { return }
        onReactionTapped?(emoji)
    }

    @objc private func addButtonTapped() {
        onAddTapped?()
    }

    // MARK: - Reuse

    func reset() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        onReactionTapped = nil
        onAddTapped = nil
        isHidden = true
    }
}

// MARK: - Helpers

/// A UIButton that carries its emoji string for target-action dispatch.
private final class ReactionPillButton: UIButton {
    var emoji: String?
}
