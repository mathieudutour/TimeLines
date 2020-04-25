//
//  SearchBar.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 24/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//
import SwiftUI
import TimeLineShared
import Combine

protocol TagPickerDelegate {
  func didSelectTag(_ tag: Tag) -> Void
}

struct AccessoryView : View {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
      entity: Tag.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
  ) var existingTokens: FetchedResults<Tag>

  var delegate: TagPickerDelegate
  @Binding var search: String
  @Binding var tokens: [Tag]

  func filterTag(_ tag: Tag) -> Bool {
    return (search.count == 0 || NSPredicate(format: "name contains[c] %@", argumentArray: [search]).evaluate(with: tag))
      && tokens.first(where: { token in
        return (tag.name?.lowercased() ?? "") == (token.name?.lowercased() ?? "")
      }) == nil
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 5) {
        ForEach(existingTokens.filter { filterTag($0) }, id: \Tag.name) { tag in
          TagView(tag: tag, onSelectTag: { tag, _ in
            self.delegate.didSelectTag(tag)
          })
        }
        .padding(.leading, 5)
        .padding(.trailing, 5)
      }
    }.frame(maxWidth: UIScreen.main.bounds.width, minHeight: 45, maxHeight: 45)
  }
}

struct SearchBar: UIViewRepresentable {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
      entity: Tag.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
  ) var existingTokens: FetchedResults<Tag>
  
  var placeholder: String = "Search..."

  @Binding var search: String
  @Binding var tokens: [Tag]
  var allowCreatingTokens: Bool = false

  let scroll: UIScrollView = {
    let scroll = UIScrollView(frame: .zero)
    return scroll
  }()

  let accessory: UIInputView = {
    let accessoryView = UIInputView(frame: .zero, inputViewStyle: .keyboard)
    accessoryView.translatesAutoresizingMaskIntoConstraints = false
    return accessoryView
  }()

  func makeUIView(context: Context) -> UISearchBar {
    let bar = UISearchBar()
    bar.placeholder = placeholder
    bar.delegate = context.coordinator
    bar.text = search
    bar.returnKeyType = .next
    bar.searchBarStyle = .minimal

    accessory.frame = CGRect(x: 0, y: 0, width: 100, height: 45)

    bar.inputAccessoryView = accessory

    return bar
  }
  
  func updateUIView(_ uiView: UISearchBar, context: Context) {
    uiView.placeholder = placeholder
    uiView.text = search
    uiView.searchTextField.allowsCopyingTokens = false
    uiView.searchTextField.allowsDeletingTokens = true
    uiView.searchTextField.tokens = tokens.map { token in
      let res = UISearchToken(
        icon: token.image,
        text: token.name ?? ""
      )
      res.representedObject = token
      return res
    }
  }
}

class SearchBarCoordinator: NSObject, UISearchBarDelegate, TagPickerDelegate {
  var parent: SearchBar

  init(_ parent: SearchBar) {
    self.parent = parent
    super.init()
  }

  // MARK: - UISearchBarDelegate
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    parent.search = ""
    parent.tokens = []
  }

  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    let child = UIHostingController(rootView: AccessoryView(delegate: self, search: parent.$search, tokens: parent.$tokens).environment(\.managedObjectContext, parent.context))
    child.view.translatesAutoresizingMaskIntoConstraints = false
    child.view.frame = parent.accessory.bounds
    child.view.backgroundColor = .clear

    parent.accessory.addSubview(child.view)
  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    // remove the UIHostingController
    parent.accessory.subviews.last?.removeFromSuperview()
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    parent.search = searchText
    parent.tokens = searchBar.searchTextField.tokens.map { $0.representedObject as! Tag }
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    guard let text = searchBar.text, text.count > 0  else {
      return
    }

    let existingToken = parent.existingTokens.first(where: { $0.name?.lowercased() == text.lowercased() })

    if !parent.allowCreatingTokens && existingToken == nil {
      return
    }

    parent.search = ""

    guard let newToken = existingToken ?? CoreDataManager.shared.createTag(name: text) else {
      return
    }

    if parent.tokens.first(where: { $0.name?.lowercased() == newToken.name?.lowercased() }) == nil {
      parent.tokens.append(newToken)
    }
  }

  func didSelectTag(_ tag: Tag) {
    parent.tokens.append(tag)
  }
}

extension SearchBar {
  func makeCoordinator() -> SearchBarCoordinator {
    SearchBarCoordinator(self)
  }
}
