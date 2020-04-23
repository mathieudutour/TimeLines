//
//  ContentView.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared
import CoreLocation

enum AlertType {
  case noProducts
  case cantBuy
  case cantRestore
  case didRestore
  case upsell
}

struct ContentView: View {
  @Environment(\.managedObjectContext) var context
  @Environment(\.inAppPurchaseContext) var iapManager

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  @State private var showingSheet = false
  @State private var showingRestoreAlert = false
  @State private var showingAlert = false
  @State private var alertType: AlertType?
  @State private var showEmptyEdit = false
  @State private var errorMessage: String?

  var addNewContact: some View {
    Button(action: {
      if (!self.iapManager.hasAlreadyPurchasedUnlimitedContacts && self.contacts.count >= self.iapManager.contactsLimit) {
        self.showAlert(.upsell)
      } else {
        self.showEmptyEdit = true
      }
    }) {
      HStack {
        Image(systemName: "plus").padding()
        Text("Add a new contact")
      }
    }.disabled(!iapManager.hasAlreadyPurchasedUnlimitedContacts && !iapManager.canBuy())
  }

  var body: some View {
    NavigationView {
      List {
        addNewContact.foregroundColor(Color(UIColor.secondaryLabel))
        ContactRow(
          name: "Me",
          timezone: TimeZone.current,
          coordinate: TimeZone.current.roughLocation
        ).padding(.trailing, 16)
        ForEach(contacts, id: \.self) { (contact: Contact) in
          NavigationLink(destination: ContactDetails(contact: contact, editView: {
            NavigationLink(destination: ContactEdition(contact: contact)) {
              Text("Edit")
            }
            .padding(.init(top: 5, leading: 10, bottom: 5, trailing: 10))
            .background(Color(UIColor.systemBackground))
            .cornerRadius(5)
          })) {
            ContactRow(
              name: contact.name ?? "",
              timezone: contact.timeZone,
              coordinate: contact.location
            )
          }.onAppear(perform: {
            contact.refreshTimeZone()
          })
        }
        .onDelete(perform: self.deleteContact)
        .onMove(perform: self.moveContact)
        NavigationLink(destination: ContactEdition(contact: nil), isActive: $showEmptyEdit) {
          EmptyView()
        }
      }
      .navigationBarTitle(Text("Contacts"))
      .navigationBarItems(leading: contacts.count > 0 ? EditButton() : nil, trailing: Button(action: {
        self.showingSheet = true
      }) {
        Image(systemName: "person").padding()
      }
      .actionSheet(isPresented: $showingSheet) {
        ActionSheet(title: Text("Settings"), buttons: [
          .default(Text("Send Feedback"), action: {
            UIApplication.shared.open(App.feedbackPage)
          }),
          .default(Text("Restore Purchases"), action: tryAgainRestore),
          .cancel()
        ])
      })
      .alert(isPresented: $showingAlert) {
        switch self.alertType {
        case .noProducts:
          return Alert(
            title: Text("Error while trying to get the In App Purchases"),
            message: Text(self.errorMessage ?? "Seems like there was an issue with the Apple's servers."),
            primaryButton: .cancel(Text("Cancel"), action: self.dismissAlert),
            secondaryButton: .default(Text("Try Again"), action: self.tryAgainBuyWithNoProduct)
          )
        case .cantBuy:
          return Alert(
            title: Text("Error while trying to purchase the product"),
            message: Text(self.errorMessage ?? "Seems like there was an issue with the Apple's servers."),
            primaryButton: .cancel(Text("Cancel"), action: self.dismissAlert),
            secondaryButton: .default(Text("Try Again"), action: self.tryAgainBuy)
          )
        case .cantRestore:
          return Alert(
            title: Text(self.errorMessage ?? "Error while trying to restore the purchases"),
            primaryButton: .cancel(Text("Cancel"), action: self.dismissAlert),
            secondaryButton: .default(Text("Try Again"), action: self.tryAgainRestore)
          )
        case .didRestore:
          return Alert(title: Text("Purchases restored successfully!"), dismissButton: .default(Text("OK")))
        case .upsell:
          return Alert(
            title: Text("You've reached the limit of the free Time Lines version"),
            message: Text("Unlock the full version to add an unlimited number of contacts."),
            primaryButton: .default(Text("Unlock Full Version"), action: self.tryAgainBuy),
            secondaryButton: .cancel(Text("Cancel"), action: self.dismissAlert)
          )
        case nil:
          return Alert(title: Text("Unknown Error"), dismissButton: .default(Text("OK")))
        }
      }
      if contacts.count > 0 {
        ContactDetails(contact: contacts[0]) {
          NavigationLink(destination: ContactEdition(contact: self.contacts[0])) {
            Text("Edit")
          }
          .padding(.init(top: 5, leading: 10, bottom: 5, trailing: 10))
          .background(Color(UIColor.systemBackground))
          .cornerRadius(5)
        }
      } else {
        VStack {
          Text("Get started by adding a new contact")
          addNewContact.padding(.trailing, 20).foregroundColor(Color.accentColor).border(Color.accentColor)
        }
      }
    }

  }

  private func deleteContact(at indexSet: IndexSet) {
    for index in indexSet {
      CoreDataManager.shared.deleteContact(contacts[index])
    }
  }

  private func moveContact(from source: IndexSet, to destination: Int) {
    for index in source {
      CoreDataManager.shared.moveContact(from: index, to: destination)
    }
  }

  private func showAlert(_ type: AlertType, withMessage message: String? = nil) {
    self.alertType = type
    self.errorMessage = message
    self.showingAlert = true
  }

  private func dismissAlert() {
    self.showingAlert = false
    self.alertType = nil
    self.errorMessage = nil
  }

  private func tryAgainBuyWithNoProduct() {
    dismissAlert()
    self.iapManager.getProducts(withHandler: { result in
      switch result {
      case .success(_):
        self.tryAgainBuy()
        break
      case .failure(let error):
        self.showAlert(.noProducts, withMessage: error.localizedDescription)
        break
      }
    })
  }

  private func tryAgainBuy() {
    dismissAlert()
    DispatchQueue.main.async {
      if let unlimitedContactsProduct = self.iapManager.unlimitedContactsProduct {
        self.iapManager.buy(product: unlimitedContactsProduct) { result in
          switch result {
          case .success(_):
            self.showEmptyEdit = true
            break
          case .failure(let error):
            print(error)
            self.showAlert(.cantBuy, withMessage: error.localizedDescription)
          }
        }
      } else {
        self.showAlert(.noProducts)
      }
    }
  }

  private func tryAgainRestore() {
    dismissAlert()
    DispatchQueue.main.async {
      self.iapManager.restorePurchases() { res in
        switch res {
        case .success(_):
          self.showAlert(.didRestore)
          break
        case .failure(let error):
          print(error)
          self.showAlert(.cantRestore, withMessage: error.localizedDescription)
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
