//
//  SearchBar.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 24/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//
import SwiftUI
import TimeLineShared

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

  func makeUIView(context: Context) -> UISearchBar {
    let bar = UISearchBar()
    bar.placeholder = placeholder
    bar.delegate = context.coordinator
    bar.text = search
    bar.returnKeyType = .next
    bar.searchBarStyle = .minimal
    return bar
  }
  
  func updateUIView(_ uiView: UISearchBar, context: Context) {
    uiView.placeholder = placeholder
    uiView.text = search
    uiView.searchTextField.allowsCopyingTokens = false
    uiView.searchTextField.allowsDeletingTokens = true
    uiView.searchTextField.tokens = tokens.map { token in
      let res = UISearchToken(
        icon: UIImage(systemName: "circle.fill")?.withTintColor(UIColor(
          red: CGFloat(token.red),
          green: CGFloat(token.green),
          blue: CGFloat(token.blue),
          alpha: 1
        ), renderingMode: .alwaysOriginal),
        text: token.name ?? ""
      )
      res.representedObject = token
      return res
    }
  }
}

class SearchBarCoordinator: NSObject, UISearchBarDelegate {
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
}

extension SearchBar {
  func makeCoordinator() -> SearchBarCoordinator {
    SearchBarCoordinator(self)
  }
}
