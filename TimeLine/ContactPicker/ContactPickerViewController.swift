//
//  ContactPickerViewController.swift
//  TimeLine
//
//  Created by Matt B on 31/10/2022.
//  Copyright © 2022 Mathieu Dutour. All rights reserved.
//

import Foundation
import ContactsUI
import Contacts

protocol ContactPickerViewControllerDelegate: AnyObject {
    func contactPickerViewControllerDidCancel(_ viewController: ContactPickerViewController)
    func contactPickerViewController(_ viewController: ContactPickerViewController, didSelect contact: CNContact)
}

class ContactPickerViewController: UIViewController, CNContactPickerDelegate {
    weak var delegate: ContactPickerViewControllerDelegate?
    private let activityIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showActivityIndicator()
        let viewController = CNContactPickerViewController()
        viewController.delegate = self
        self.present(viewController, animated: false)
    }
    
    private func showActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        self.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            self.delegate?.contactPickerViewControllerDidCancel(self)
        }
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        self.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            self.delegate?.contactPickerViewController(self, didSelect: contact)
        }
    }
    
}
