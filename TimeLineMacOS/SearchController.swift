//
//  SearchController.swift
//  Time LinesMacOS
//
//  Created by Mathieu Dutour on 08/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import MapKit
import Combine

struct ButtonThatLookLikeRowStyle: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .font(.body)
      .padding(10)
      .foregroundColor(Color(NSColor.labelColor))
      .background(Color(NSColor.controlBackgroundColor))
      .border(Color(NSColor.separatorColor), width: 0)
  }
}

struct ButtonThatLookLikeNothingStyle: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .font(.body)
      .padding(.trailing, 3)
      .foregroundColor(Color(NSColor.secondaryLabelColor))
      .background(Color(NSColor.clear))
      .border(Color(NSColor.separatorColor), width: 0)
  }
}

class ObservableArray<T>: ObservableObject {

  @Published var array:[T] = []
  var cancellables = [AnyCancellable]()

  init(array: [T]) {
    self.array = array
  }

  func observeChildrenChanges<T: ObservableObject>() -> ObservableArray<T> {
    let array2 = array as! [T]
    array2.forEach({
      let c = $0.objectWillChange.sink(receiveValue: { _ in self.objectWillChange.send() })

      // Important: You have to keep the returned value allocated,
      // otherwise the sink subscription gets cancelled
      self.cancellables.append(c)
    })
    return self as! ObservableArray<T>
  }
}

struct SearchController<Result>: View where Result: View {
  var resultView: (_ mapItem: MKLocalSearchCompletion) -> Result

  @Environment(\.presentationMode) var presentationMode

  @ObservedObject var matchingItems: ObservableArray<MKLocalSearchCompletion> = ObservableArray(array: [])
  @State private var searchText = ""
  @State private var error: String? = nil

  var body: some View {
    VStack {
      // Search view
      HStack {
        ZStack(alignment: .leading) {

          AutoFocusTextField(placeholder: "Location", error: $error, text: $searchText, matchingItems: $matchingItems.array)
          .foregroundColor(.primary)
          .padding(.leading, 18)

          Image(nsImage: NSImage(named: NSImage.revealFreestandingTemplateName)!)

          if self.searchText != "" {
            HStack {
              Spacer()
              Button(action: {
                  self.searchText = ""
              }) {
                Image(nsImage: NSImage(named: NSImage.stopProgressFreestandingTemplateName)!).opacity(searchText == "" ? 0 : 1)
              }.buttonStyle(ButtonThatLookLikeNothingStyle())

            }

          }
        }
        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        .foregroundColor(.secondary)

        Button("Cancel") {
          self.presentationMode.wrappedValue.dismiss()
        }
      }
      .background(Color(.windowBackgroundColor))
      .padding(.horizontal)

      GeometryReader { p in
        ScrollView(.vertical, showsIndicators: false) {
          VStack() {
            if self.error != nil {
              HStack {
                Text(self.error ?? "").padding().foregroundColor(.red)
                Spacer()
              }
              Divider()
            }
            ForEach(self.matchingItems.array, id:\.self) {
              searchText in
              VStack {
                HStack {
                  self.resultView(searchText).listRowInsets(EdgeInsets())
                  Spacer()
                }
                Divider()
              }
            }
            Spacer()
          }.frame(width: p.size.width)
        }.background(Color(NSColor.controlBackgroundColor)).frame(width: p.size.width, height: p.size.height)
      }
    }.frame(minWidth: 300, minHeight: 250).background(Color(.windowBackgroundColor))
  }
}
