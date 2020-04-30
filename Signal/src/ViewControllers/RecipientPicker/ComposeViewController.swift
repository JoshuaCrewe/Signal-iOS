//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

import Foundation
import PromiseKit

@objc
class ComposeViewController: OWSViewController {
    let recipientPicker = RecipientPickerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("MESSAGE_COMPOSEVIEW_TITLE", comment: "Title for the compose view.")

        view.backgroundColor = Theme.backgroundColor

        let showNewGroupAsCell = RemoteConfig.groupsV2CreateGroups

        recipientPicker.allowsSelectingUnregisteredPhoneNumbers = false
        recipientPicker.shouldShowInvites = true
        recipientPicker.shouldShowNewGroup = showNewGroupAsCell
        recipientPicker.delegate = self
        addChild(recipientPicker)
        view.addSubview(recipientPicker.view)
        recipientPicker.view.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        recipientPicker.view.autoPinEdge(toSuperviewEdge: .leading)
        recipientPicker.view.autoPinEdge(toSuperviewEdge: .trailing)
        recipientPicker.view.autoPinEdge(toSuperviewEdge: .bottom)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissPressed))

        if !showNewGroupAsCell {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "btnGroup--white"), style: .plain, target: self, action: #selector(newGroupPressed))
            navigationItem.rightBarButtonItem?.accessibilityLabel = NSLocalizedString("NEW_GROUP_BUTTON_LABEL",
                                                                                      comment: "Accessibility label for the new group button")
        }
    }

    @objc func dismissPressed() {
        dismiss(animated: true)
    }

    @objc func newGroupPressed() {
        showNewGroupUI()
    }

    func newConversation(address: SignalServiceAddress) {
        assert(address.isValid)
        let thread = TSContactThread.getOrCreateThread(contactAddress: address)
        newConversation(thread: thread)
    }

    func newConversation(thread: TSThread) {
        SignalApp.shared().presentConversation(for: thread, action: .compose, animated: false)
        presentingViewController?.dismiss(animated: true)
    }

    func showNewGroupUI() {
        let newGroupView: UIViewController = (RemoteConfig.groupsV2CreateGroups
            ? NewGroupMembersViewController()
            : NewGroupViewController())
        navigationController?.pushViewController(newGroupView, animated: true)
    }
}

extension ComposeViewController: RecipientPickerDelegate {
    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        canSelectRecipient recipient: PickedRecipient
    ) -> Bool {
        return true
    }

    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        didSelectRecipient recipient: PickedRecipient
    ) {
        switch recipient.identifier {
        case .address(let address):
            newConversation(address: address)
        case .group(let groupThread):
            newConversation(thread: groupThread)
        }
    }

    func recipientPicker(_ recipientPickerViewController: RecipientPickerViewController,
                         willRenderRecipient recipient: PickedRecipient) {
        // Do nothing.
    }

    func recipientPicker(_ recipientPickerViewController: RecipientPickerViewController,
                         prepareToSelectRecipient recipient: PickedRecipient) -> AnyPromise {
        owsFailDebug("This method should not called.")
        return AnyPromise(Promise.value(()))
    }

    func recipientPicker(_ recipientPickerViewController: RecipientPickerViewController,
                         showInvalidRecipientAlert recipient: PickedRecipient) {
        owsFailDebug("Unexpected error.")
    }

    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        didDeselectRecipient recipient: PickedRecipient
    ) {}

    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        accessoryMessageForRecipient recipient: PickedRecipient
    ) -> String? {
        switch recipient.identifier {
        case .address(let address):
            guard recipientPicker.contactsViewHelper.isSignalServiceAddressBlocked(address) else { return nil }
            return MessageStrings.conversationIsBlocked
        case .group(let thread):
            guard recipientPicker.contactsViewHelper.isThreadBlocked(thread) else { return nil }
            return MessageStrings.conversationIsBlocked
        }
    }

    func recipientPickerTableViewWillBeginDragging(_ recipientPickerViewController: RecipientPickerViewController) {}

    func recipientPickerNewGroupButtonWasPressed() {
        showNewGroupUI()
    }

    func recipientPickerCustomHeaderViews() -> [UIView] { return [] }
}
