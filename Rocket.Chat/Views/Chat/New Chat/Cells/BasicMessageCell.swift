//
//  BasicMessageCell.swift
//  Rocket.Chat
//
//  Created by Filipe Alvarenga on 23/09/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import UIKit
import RocketChatViewController

final class BasicMessageCell: BaseMessageCell, BaseMessageCellProtocol, SizingCell {
    static let identifier = String(describing: BasicMessageCell.self)

    // MARK: SizingCell

    static let sizingCell: UICollectionViewCell & ChatCell = {
        guard let cell = BasicMessageCell.instantiateFromNib() else {
            return BasicMessageCell()
        }

        return cell
    }()

    @IBOutlet weak var avatarContainerView: UIView! {
        didSet {
            avatarContainerView.layer.cornerRadius = 4
            avatarView.frame = avatarContainerView.bounds
            avatarContainerView.addSubview(avatarView)
        }
    }

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var text: RCTextView!

    @IBOutlet weak var readReceiptButton: UIButton!

    @IBOutlet weak var textHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var readReceiptWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var readReceiptTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarLeadingConstraint: NSLayoutConstraint!
    var textWidth: CGFloat {
        return
            messageWidth -
            textLeadingConstraint.constant -
            textTrailingConstraint.constant -
            readReceiptWidthConstraint.constant -
            readReceiptTrailingConstraint.constant -
            avatarWidthConstraint.constant -
            avatarLeadingConstraint.constant
    }

    weak var longPressGesture: UILongPressGestureRecognizer?
    weak var usernameTapGesture: UITapGestureRecognizer?
    weak var avatarTapGesture: UITapGestureRecognizer?
    weak var delegate: ChatMessageCellProtocol? {
        didSet {
            text.delegate = delegate
        }
    }

    var initialTextHeightConstant: CGFloat = 0

    override func awakeFromNib() {
        super.awakeFromNib()

        initialTextHeightConstant = textHeightConstraint.constant
        insertGesturesIfNeeded()
    }

    override func configure() {
        configure(with: avatarView, date: date, and: username)
        configure(readReceipt: readReceiptButton)
        updateText()
    }

    func updateText() {
        guard
            let viewModel = viewModel?.base as? BasicMessageChatItem,
            let managedObject = viewModel.message.managedObject
        else {
            return
        }

        if let message = MessageTextCacheManager.shared.message(for: managedObject, with: theme) {
            if viewModel.message.temporary {
                message.setFontColor(MessageTextFontAttributes.systemFontColor(for: theme))
            } else if viewModel.message.failed {
                message.setFontColor(MessageTextFontAttributes.failedFontColor(for: theme))
            }

            text.message = message

            let maxSize = CGSize(
                width: textWidth,
                height: .greatestFiniteMagnitude
            )

            textHeightConstraint.constant = text.textView.sizeThatFits(
                maxSize
            ).height
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        username.text = ""
        date.text = ""
        text.message = nil
        avatarView.prepareForReuse()
        textHeightConstraint.constant = initialTextHeightConstant
    }

    func insertGesturesIfNeeded() {
        if longPressGesture == nil {
            let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressMessageCell(recognizer:)))
            gesture.minimumPressDuration = 0.325
            gesture.delegate = self
            addGestureRecognizer(gesture)

            longPressGesture = gesture
        }

        if usernameTapGesture == nil {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleUsernameTapGestureCell(recognizer:)))
            gesture.delegate = self
            username.addGestureRecognizer(gesture)

            usernameTapGesture = gesture
        }

        if avatarTapGesture == nil {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleUsernameTapGestureCell(recognizer:)))
            gesture.delegate = self
            avatarView.addGestureRecognizer(gesture)

            avatarTapGesture = gesture
        }
    }

    @objc func handleLongPressMessageCell(recognizer: UIGestureRecognizer) {
        guard
            let viewModel = viewModel?.base as? BasicMessageChatItem,
            let managedObject = viewModel.message.managedObject
        else {
            return
        }

        delegate?.handleLongPressMessageCell(managedObject, view: contentView, recognizer: recognizer)
    }

    @objc func handleUsernameTapGestureCell(recognizer: UIGestureRecognizer) {
        guard
            let viewModel = viewModel?.base as? BasicMessageChatItem,
            let managedObject = viewModel.message.managedObject
        else {
            return
        }

        delegate?.handleUsernameTapMessageCell(managedObject, view: username, recognizer: recognizer)
    }
}

// MARK: UIGestureRecognizerDelegate

extension BasicMessageCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

// MARK: Theming

extension BasicMessageCell {

    override func applyTheme() {
        super.applyTheme()

        let theme = self.theme ?? .light
        date.textColor = theme.auxiliaryText
        username.textColor = theme.titleText
        updateText()
    }
}
