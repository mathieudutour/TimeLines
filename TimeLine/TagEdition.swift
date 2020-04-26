//
//  TagEdition.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 26/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared
import MapKit
import CoreLocation

struct TagEdition: View {
  private var tag: Tag?

  @State private var tagName: String
  @State private var color: UIColor

  private var colors: [Color] = {
    let hueValues = Array(0...359)

    return hueValues.map {
      Color(Tag.colorWithHue(CGFloat($0) / 359.0))
    }
  }()

  private let linearGradientWidth: CGFloat = 200

  init() {
    self.tag = RouteState.shared.editingTag

    _tagName = State(initialValue: tag?.name ?? "")
    _color = State(initialValue: tag?.color ?? Tag.randomColor())
  }

  var body: some View {
    NavigationView {
      List {
        Section {
          HStack {
            Text("Name")
            TextField("Family", text: $tagName)
              .multilineTextAlignment(.trailing)
              .frame(alignment: .trailing)
          }

          HStack {
            Text("Color")
            Circle().foregroundColor(Color(color)).frame(width: 16, height: 16)
            Spacer()
            LinearGradient(gradient: Gradient(colors: colors),
                           startPoint: .leading,
                           endPoint: .trailing)
              .frame(width: linearGradientWidth, height: 10)
              .cornerRadius(5)
              .shadow(radius: 8)
              .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({ value in
                  self.color = UIColor(
                    hue: min(max(value.location.x, 0), self.linearGradientWidth) / self.linearGradientWidth,
                    saturation: 1.0,
                    brightness: 1.0,
                    alpha: 1.0
                  )
                })
              )
          }

        }
      }
      .listStyle(GroupedListStyle())
      .resignKeyboardOnDragGesture()
      .navigationBarTitle(Text(tag == nil ? "New Tag" : "Edit Tag"))
      .navigationBarItems(leading: Button(action: back) {
          Text("Cancel")
        }, trailing: Button(action: {
          self.save()
        }) {
          Text("Save")
        }
        .disabled(!didUpdateTag() || !valid())
      )
    }.navigationViewStyle(StackNavigationViewStyle())
  }

  func back() {
    RouteState.shared.navigate(.tags)
  }

  func didChangeColor() -> Bool {
    return color != tag?.color
  }

  func didChangeName() -> Bool {
    return tagName.count > 0 && tagName != tag?.name
  }

  func didUpdateTag() -> Bool {
    return didChangeName() || didChangeColor()
  }

  func valid() -> Bool {
    return tagName.count > 0
  }

  func save() {
    if let tag = tag {
      tag.name = tagName
      let components = color.rgba
      tag.red = Double(components.red)
      tag.green = Double(components.green)
      tag.red = Double(components.red)
      CoreDataManager.shared.saveContext()
    } else {
      CoreDataManager.shared.createTag(
        name: tagName,
        color: color
      )
    }
    back()
  }
}

struct TagEdition_Previews: PreviewProvider {
  static var previews: some View {
    return TagEdition()
  }
}
