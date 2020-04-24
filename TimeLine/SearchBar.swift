//
//  SearchBar.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 24/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//
import SwiftUI

struct SearchBar: UIViewRepresentable {
  var placeholder: String = "Search..."

  @Binding var search: String
  @Binding var tokens: [String]
  var existingTokens: [String]
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
      let res = UISearchToken(icon: nil, text: token)
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
    parent.tokens = searchBar.searchTextField.tokens.map { $0.representedObject as! String }
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    guard let text = searchBar.text, text.count > 0  else {
      return
    }

    let existingToken = parent.existingTokens.first(where: { $0.lowercased() == text.lowercased() })

    if !parent.allowCreatingTokens && existingToken == nil {
      return
    }

    if parent.tokens.first(where: { $0.lowercased() == (existingToken ?? text).lowercased() }) == nil {
      parent.tokens.append(existingToken ?? text)
    }

    parent.search = ""
  }
}

extension SearchBar {
  func makeCoordinator() -> SearchBarCoordinator {
    SearchBarCoordinator(self)
  }
}
