//
//  ManageContacts.swift
//  TimeLineMacOS
//
//  Created by Mathieu Dutour on 07/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineSharedMacOS
import CoreLocation

enum AlertType {
  case noProducts
  case cantBuy
  case upsell
}

struct ManageContacts: View {
  @Environment(\.managedObjectContext) var context
  @Environment(\.inAppPurchaseContext) var iapManager

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  @State var selectedContact: Contact?

  @State private var showingEdit = false
  @State private var showingSheet = false
  @State private var showingAlert = false
  @State private var alertType: AlertType?
  @State private var errorMessage: String?

  var body: some View {
    NavigationView {
      List(selection: $selectedContact) {
        Button(action: {
          if (!self.iapManager.hasAlreadyPurchasedUnlimitedContacts && self.contacts.count >= self.iapManager.contactsLimit) {
            self.showAlert(.upsell)
          } else {
            self.selectedContact = nil
            self.showingEdit = true
          }
        }) {
          HStack {
            Image(nsImage: NSImage(named: NSImage.addTemplateName)!)
            Text("Add a new contact")
          }
        }.disabled(!iapManager.hasAlreadyPurchasedUnlimitedContacts && !iapManager.canBuy())

        ForEach(contacts, id: \.self) { (contact: Contact) in
          VStack {
            HStack {
              Text(contact.name ?? "")
                .font(.system(size: 20))
                .lineLimit(1)
              Spacer()
              Text(contact.timeZone?.prettyPrintTimeDiff() ?? "").padding()
            }
            Divider()
          }
          .tag(contact)
          .onAppear(perform: {
            contact.refreshTimeZone()
          })
          .contextMenu(menuItems: {
            Button(action: {
              self.selectedContact = contact
              self.showingEdit = true
            }) {
              Text("Edit Contact")
            }
            Button(action: {
              self.selectedContact = nil
              self.showingEdit = false
              CoreDataManager.shared.deleteContact(contact)
            }) {
              Text("Delete Contact")
            }
          })
        }
        .onDelete(perform: self.deleteContact)
        .onMove(perform: self.moveContact)
      }
      .padding(.top)
      .frame(minWidth: 200)
      .listStyle(SidebarListStyle())

      if showingEdit {
        ContactEdition(contact: $selectedContact, showingEdit: $showingEdit)
      } else if selectedContact != nil {
        ContactDetails(contact: selectedContact!) {
          Button(action: {
            self.showingEdit = true
          }) {
            Text("Edit")
          }
        }
      }
    }
    .edgesIgnoringSafeArea(.top)
    .navigationViewStyle(DoubleColumnNavigationViewStyle())
    .background(Blur().edgesIgnoringSafeArea(.top))
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
      case .upsell:
        return Alert(
          title: Text("You've reached the limit of the free TimeLine version"),
          message: Text("Unlock the full version to add an unlimited number of contacts."),
          primaryButton: .default(Text("Unlock Full Version"), action: self.tryAgainBuy),
          secondaryButton: .cancel(Text("Cancel"), action: self.dismissAlert)
        )
      case nil:
        return Alert(title: Text("Unknown Error"), dismissButton: .default(Text("OK")))
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
            self.selectedContact = nil
            self.showingEdit = true
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
}

struct ManageContacts_Previews: PreviewProvider {
  static var previews: some View {
    ManageContacts()
  }
}

