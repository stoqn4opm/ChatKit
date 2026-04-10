import UIKit

/// A modal view controller showing who reacted to a message and with
/// which emoji.
///
/// ChatKit provides this as a default implementation. Consumers can use
/// the data from `ChatMessage.reactionGroups` to build their own UI
/// instead, or subclass this for customisation.
///
/// Present it as a sheet:
/// ```swift
/// let detail = ReactionsDetailViewController(message: message)
/// present(detail, animated: true)
/// ```
public final class ReactionsDetailViewController: UIViewController {

    /// The message whose reactions are displayed.
    public let message: ChatMessage

    // MARK: - Subviews

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ReactionDetailCell.self,
                       forCellReuseIdentifier: ReactionDetailCell.reuseID)
        return table
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.text = "Reactions"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Data

    /// Flat list of (emoji, sender) pairs, sorted by emoji then sender name.
    private var entries: [(emoji: String, sender: ChatMessage.Sender)] = []

    // MARK: - Init

    public init(message: ChatMessage) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        buildEntries()
        setupViews()
    }

    // MARK: - Setup

    private func buildEntries() {
        for group in message.reactionGroups {
            for sender in group.senders {
                entries.append((emoji: group.emoji, sender: sender))
            }
        }
    }

    private func setupViews() {
        view.addSubview(headerLabel)
        view.addSubview(tableView)

        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(
                equalTo: headerLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ReactionsDetailViewController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReactionDetailCell.reuseID, for: indexPath
        ) as? ReactionDetailCell else {
            return UITableViewCell()
        }
        let entry = entries[indexPath.row]
        cell.configure(emoji: entry.emoji, sender: entry.sender)
        return cell
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
        52
    }
}

// MARK: - ReactionDetailCell

/// A table view cell showing an avatar, sender name, and their emoji.
private final class ReactionDetailCell: UITableViewCell {

    static let reuseID = "ReactionDetailCell"

    private let avatarView: AvatarView = {
        let avatar = AvatarView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emojiLabel)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 34),
            avatarView.heightAnchor.constraint(equalToConstant: 34),

            nameLabel.leadingAnchor.constraint(
                equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: emojiLabel.leadingAnchor, constant: -8),

            emojiLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -16),
            emojiLabel.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(emoji: String, sender: ChatMessage.Sender) {
        emojiLabel.text = emoji
        nameLabel.text = sender.displayName
        avatarView.configure(
            initial: String(sender.displayName.prefix(1)),
            color: sender.avatarColor)
    }
}
