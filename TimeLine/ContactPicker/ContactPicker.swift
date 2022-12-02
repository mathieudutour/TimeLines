//
//  ContactPicker.swift
//  TimeLine
//
//  Created by Matt B on 31/10/2022.
//  Copyright © 2022 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import Contacts
import TimeLineShared
import PhoneNumberKit

protocol ContactPickerDelegate {
    func hasReceivedContact(contact: Contact?)
}

struct ContactPicker: UIViewControllerRepresentable {
    private let delegate: ContactPickerDelegate
    
    init(delegate: ContactPickerDelegate) {
        self.delegate = delegate
    }
    
    final class Coordinator: NSObject, ContactPickerViewControllerDelegate {
        private let contactPickerDelegate: ContactPickerDelegate
        
        init(contactPickerDelegate: ContactPickerDelegate) {
            self.contactPickerDelegate = contactPickerDelegate
            super.init()
        }
        
        func contactPickerViewController(_ viewController: ContactPickerViewController, didSelect contact: CNContact) {
            convertToContact(cnContact: contact) { [weak self] in
                self?.contactPickerDelegate.hasReceivedContact(contact: $0)
            }
        }
        
        func contactPickerViewControllerDidCancel(_ viewController: ContactPickerViewController) {
            viewController.dismiss(animated: true)
        }

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(contactPickerDelegate: delegate)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ContactPicker>) -> ContactPicker.UIViewControllerType {
        let result = ContactPicker.UIViewControllerType()
        result.delegate = context.coordinator
        return result
    }
    
    func updateUIViewController(_ uiViewController: ContactPickerViewController, context: UIViewControllerRepresentableContext<ContactPicker>) { }

}
