//
//  SearchBar.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//
import SwiftUI
import MapKit

struct SearchController<Result: View>: UIViewControllerRepresentable {
  var searchText: String
  var isFirstResponder: Bool = false
  @State var matchingItems: [MKMapItem] = []

  private var resultView: (_ mapItem: MKMapItem) -> Result

  private var searchBarPlaceholder: String

  init(_ searchBarPlaceholder: String = "", searchedText: Binding<String>, isFirstResponder: Bool = false, resultView: @escaping (_ mapItem: MKMapItem) -> Result) {
    self.resultView = resultView
    self.searchText = searchedText.wrappedValue
    self.searchBarPlaceholder = searchBarPlaceholder
    self.isFirstResponder = isFirstResponder
  }

  func makeUIViewController(context: Context) -> UINavigationController {
    let contentViewController = UIHostingController(rootView: SearchResultView(result: $matchingItems, content: resultView))
    let navigationController = UINavigationController(rootViewController: contentViewController)

    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = context.coordinator
    searchController.obscuresBackgroundDuringPresentation = false // for results
    searchController.searchBar.placeholder = searchBarPlaceholder

    contentViewController.title = "Location"
    contentViewController.navigationItem.searchController = searchController
    contentViewController.navigationItem.hidesSearchBarWhenScrolling = true
    contentViewController.definesPresentationContext = true

    searchController.searchBar.delegate = context.coordinator

    return navigationController
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<SearchController>) {
    if isFirstResponder && !context.coordinator.didBecomeFirstResponder, uiViewController.view.window != nil  {
      DispatchQueue.main.async {
        uiViewController.visibleViewController?.navigationItem.searchController?.searchBar.becomeFirstResponder()
      }
      context.coordinator.didBecomeFirstResponder = true
    }
  }
}

extension SearchController {
  func makeCoordinator() -> SearchController<Result>.Coordinator {
    Coordinator(self)
  }
  class Coordinator: NSObject, UISearchResultsUpdating, UISearchBarDelegate {
    var parent: SearchController
    var didBecomeFirstResponder = false

    init(_ parent: SearchController) {
      self.parent = parent

    }

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
      guard let searchBarText = searchController.searchBar.text else { return }
      self.parent.searchText = searchBarText

      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = searchBarText
      request.resultTypes = .address
      let search = MKLocalSearch(request: request)
      search.start { response, _ in
        guard let response = response else {
          return
        }
        DispatchQueue.main.async {
          self.parent.matchingItems = response.mapItems
        }
      }
    }

    // MARK: - UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
      self.parent.searchText = ""
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
      self.parent.searchText = ""
      return true
    }
  }
}

// "nofity" the result content about the searchText
struct SearchResultView<Content: View>: View {
  @Binding var matchingItems: [MKMapItem]
  private var content: (_ mapItem: MKMapItem) -> Content

  init(result matchingItems: Binding<[MKMapItem]>, @ViewBuilder content: @escaping (_ mapItem: MKMapItem) -> Content) {
    self._matchingItems = matchingItems
    self.content = content
  }
  
  var body: some View {
    List {
      ForEach(matchingItems, id: \.self) { (item: MKMapItem) in
        self.content(item)
      }
    }
  }
}
