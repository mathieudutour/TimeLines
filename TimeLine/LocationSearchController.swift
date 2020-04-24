//
//  SearchBar.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//
import SwiftUI
import MapKit

struct LocationSearchController: UIViewControllerRepresentable {
  @State var matchingItems: [MKLocalSearchCompletion] = []

  var searchBarPlaceholder: String
  var resultView: (_ mapItem: MKLocalSearchCompletion) -> Button<Text>

  func makeUIViewController(context: Context) -> UINavigationController {
    let contentViewController = UIHostingController(rootView: LocationSearchResultView(result: $matchingItems, content: resultView))
    let navigationController = UINavigationController(rootViewController: contentViewController)

    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = context.coordinator
    searchController.delegate = context.coordinator
    searchController.obscuresBackgroundDuringPresentation = false // for results
    searchController.searchBar.placeholder = searchBarPlaceholder

    contentViewController.title = "Location"
    contentViewController.navigationItem.searchController = searchController
    contentViewController.navigationItem.hidesSearchBarWhenScrolling = true
    contentViewController.definesPresentationContext = true

    searchController.searchBar.delegate = context.coordinator

    return navigationController
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<LocationSearchController>) {
    uiViewController.visibleViewController?.navigationItem.searchController?.searchBar.placeholder = searchBarPlaceholder

    if !context.coordinator.didBecomeFirstResponder, uiViewController.view.window != nil  {
      context.coordinator.didBecomeFirstResponder = true
      uiViewController.visibleViewController?.navigationItem.searchController?.isActive = true
    }
  }
}

class LocationSearchControllerCoordinator: NSObject, UISearchResultsUpdating, UISearchBarDelegate, MKLocalSearchCompleterDelegate, UISearchControllerDelegate {
  var parent: LocationSearchController
  var didBecomeFirstResponder = false
  var searchCompleter = MKLocalSearchCompleter()

  init(_ parent: LocationSearchController) {
    self.parent = parent
    super.init()
    searchCompleter.delegate = self
    searchCompleter.resultTypes = .address
  }

  // MARK: - UISearchResultsUpdating
  func updateSearchResults(for searchController: UISearchController) {
    searchCompleter.queryFragment = searchController.searchBar.text ?? ""
  }

  // MARK: - UISearchBarDelegate
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchCompleter.queryFragment = ""
  }

  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchCompleter.queryFragment = ""
    return true
  }

  // MARK: - UISearchControllerDelegate
  func didPresentSearchController(_ searchController: UISearchController) {
    DispatchQueue.main.async {
      searchController.searchBar.becomeFirstResponder()
    }
  }

  // MARK: - MKLocalSearchCompleterDelegate
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    self.parent.matchingItems = completer.results
  }
}

extension LocationSearchController {
  func makeCoordinator() -> LocationSearchControllerCoordinator {
    LocationSearchControllerCoordinator(self)
  }
}

// "nofity" the result content about the searchText
struct LocationSearchResultView<Content: View>: View {
  @Binding var matchingItems: [MKLocalSearchCompletion]
  private var content: (_ mapItem: MKLocalSearchCompletion) -> Content

  init(result matchingItems: Binding<[MKLocalSearchCompletion]>, @ViewBuilder content: @escaping (_ mapItem: MKLocalSearchCompletion) -> Content) {
    self._matchingItems = matchingItems
    self.content = content
  }

  var body: some View {
    List {
      ForEach(matchingItems, id: \.self) { (item: MKLocalSearchCompletion) in
        self.content(item)
      }
    }
  }
}

#if DEBUG
struct TestSearchController: View {
    var body: some View {
      LocationSearchController(searchBarPlaceholder: "placeholder") { res in
        Button(action: {}) {
          Text(res.title)
        }
      }
    }
}

struct TestSearchController_Previews: PreviewProvider {
    static var previews: some View {
        TestSearchController()
    }
}
#endif
