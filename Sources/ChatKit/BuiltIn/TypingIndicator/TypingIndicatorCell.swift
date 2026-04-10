import UIKit

public final class TypingIndicatorCell: UICollectionViewCell {

    public static let reuseID = "TypingIndicatorCell"

    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let dot1 = TypingIndicatorCell.makeDot()
    private let dot2 = TypingIndicatorCell.makeDot()
    private let dot3 = TypingIndicatorCell.makeDot()

    private let avatarView: AvatarView = {
        let avatar = AvatarView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()

    private static func makeDot() -> UIView {
        let dot = UIView()
        dot.backgroundColor = .systemGray
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        return dot
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(avatarView)
        contentView.addSubview(bubbleView)

        let stack = UIStackView(arrangedSubviews: [dot1, dot2, dot3])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(stack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),

            bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 6),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(equalToConstant: 70),
            bubbleView.heightAnchor.constraint(equalToConstant: 36),

            stack.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),

            dot1.widthAnchor.constraint(equalToConstant: 8),
            dot1.heightAnchor.constraint(equalToConstant: 8),
            dot2.widthAnchor.constraint(equalToConstant: 8),
            dot2.heightAnchor.constraint(equalToConstant: 8),
            dot3.widthAnchor.constraint(equalToConstant: 8),
            dot3.heightAnchor.constraint(equalToConstant: 8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    public func configure(name: String = "...", color: UIColor = .systemPurple) {
        avatarView.configure(initial: String(name.prefix(1)), color: color)
        startAnimating()
    }

    private func startAnimating() {
        let dots = [dot1, dot2, dot3]
        for (i, dot) in dots.enumerated() {
            dot.layer.removeAllAnimations()
            let animation = CABasicAnimation(keyPath: "transform.translation.y")
            animation.fromValue = 0
            animation.toValue = -4
            animation.duration = 0.35
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(i) * 0.15
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            dot.layer.add(animation, forKey: "bounce")
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        [dot1, dot2, dot3].forEach { $0.layer.removeAllAnimations() }
    }
}
