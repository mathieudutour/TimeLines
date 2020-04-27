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

extension UIApplication {
  func endEditing(_ force: Bool) {
    self.windows
      .filter{$0.isKeyWindow}
      .first?
      .endEditing(force)
  }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
  var gesture = DragGesture().onChanged{_ in
    UIApplication.shared.endEditing(true)
  }
  func body(content: Content) -> some View {
    content.gesture(gesture)
  }
}

extension View {
  func resignKeyboardOnDragGesture() -> some View {
    return modifier(ResignKeyboardOnDragGesture())
  }
}

struct MeRow: View {
  @Environment(\.editMode) var editMode

  private let currentTimeZone = TimeZone.autoupdatingCurrent
  private let roughLocation = TimeZone.autoupdatingCurrent.roughLocation

  var body: some View {
    Group {
      if editMode?.wrappedValue == EditMode.inactive {
        ContactRow(
          name: "Me",
          timezone: currentTimeZone,
          coordinate: roughLocation
        ).padding(.trailing, 15)
      }
    }
  }
}

struct BindedContactRow: View {
  @Environment(\.editMode) var editMode
  @EnvironmentObject var routeState: RouteState

  var contact: Contact
  @Binding var search: String
  @Binding var searchTokens: [Tag]

  var destination: some View {
    ContactDetails(contact: contact, onSelectTag: { tag, presentationMode in
      self.searchTokens = [tag]
      self.search = ""
      presentationMode.dismiss()
    }, editView: {
      Button(action: {
        self.routeState.navigate(.editContact(contact: self.contact))
      }) {
        Text("Edit")
      }
      .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
      .background(Color(UIColor.systemBackground))
      .cornerRadius(5)
    })
  }

  var body: some View {
    NavigationLink(destination: destination, tag: contact, selection: $routeState.contactDetailed) {
      ContactRow(
        name: contact.name ?? "",
        timezone: contact.timeZone,
        coordinate: contact.location,
        startTime: contact.startTime,
        endTime: contact.endTime,
        hideLine: editMode?.wrappedValue == .active
      )
    }.onAppear(perform: {
      self.contact.refreshTimeZone()
    })
  }
}

struct ContentView: View {
  @Environment(\.managedObjectContext) var context
  @Environment(\.inAppPurchaseContext) var iapManager
  @EnvironmentObject var routeState: RouteState

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  @State private var showingSheet = false
  @State private var showingRestoreAlert = false
  @State private var showingAlert = false
  @State private var alertType: AlertType?
  @State private var errorMessage: String?
  @State private var search = ""
  @State private var searchTokens: [Tag] = []

  var addNewContact: some View {
    Button(action: {
      if (!self.iapManager.hasAlreadyPurchasedUnlimitedContacts && self.contacts.count >= self.iapManager.contactsLimit) {
        self.showAlert(.upsell)
      } else {
        self.routeState.navigate(.editContact(contact: nil))
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
        SearchBar(search: $search, tokens: $searchTokens)

        if search.count == 0 {
          addNewContact.foregroundColor(Color(UIColor.secondaryLabel))
        }

        MeRow()

        ForEach(contacts.filter { filterContact($0) }, id: \Contact.name) { (contact: Contact) in
          BindedContactRow(contact: contact, search: self.$search, searchTokens: self.$searchTokens)
        }
        .onDelete(perform: self.deleteContact)
        .onMove(perform: self.moveContact)
      }
      .resignKeyboardOnDragGesture()
      .navigationBarTitle(Text("Contacts"))
      .navigationBarItems(leading: contacts.count > 0 ? EditButton() : nil, trailing: Button(action: {
        self.showingSheet = true
      }) {
        Image(systemName: "person").padding()
      }
      .actionSheet(isPresented: $showingSheet) {
        ActionSheet(title: Text("Settings"), buttons: [
          .default(Text("Manage Tags"), action: {
            self.routeState.navigate(.tags)
          }),
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

      // default view on iPad
      if contacts.count > 0 {
        ContactDetails(contact: contacts[0]) {
          Button(action: {
            self.routeState.navigate(.editContact(contact: self.contacts[0]))
          }) {
            Text("Edit")
          }
          .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
          .background(Color(UIColor.systemBackground))
          .cornerRadius(5)
        }
      } else {
        VStack {
          Text("Get started by adding a new contact")
          addNewContact.padding(.trailing, 20).foregroundColor(Color.accentColor).border(Color.accentColor)
        }
      }
    }.sheet(isPresented: self.$routeState.isShowingSheetFromList) {
      if self.routeState.isEditing {
        ContactEdition().environment(\.managedObjectContext, self.context).environmentObject(self.routeState)
      } else if self.routeState.isShowingTags {
        Tags().environment(\.managedObjectContext, self.context).environmentObject(self.routeState)
      }
    }

  }

  private func filterContact(_ contact: Contact) -> Bool {
    guard search.count == 0 || NSPredicate(format: "name contains[c] %@", argumentArray: [search]).evaluate(with: contact) || contact.tags?.first(where: { tag in
      guard let tag = tag as? Tag else {
        return false
      }
      return tag.name?.lowercased().contains(search.lowercased()) ?? false
    }) != nil else {
      return false
    }

    if searchTokens.count == 0 {
      return true
    }

    return searchTokens.allSatisfy { token in
      contact.tags?.first(where: { tag in
        guard let tag = tag as? Tag else {
          return false
        }
        return tag.name?.lowercased() == token.name?.lowercased()
      }) != nil
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
            self.routeState.navigate(.editContact(contact: nil))
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
