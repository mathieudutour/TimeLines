//
//  TimeLineWidget.swift
//  Time Lines Widget
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import WidgetKit
import SwiftUI
import TimeLineShared
import CoreLocation

struct WidgetContact: Identifiable {
  let id: URL
  let name: String
  let timezone: TimeZone?
  let coordinate: CLLocationCoordinate2D
  let startTime: Date?
  let endTime: Date?

  var url: URL? {
    URL(string: "timelines://contact/\(id)")
  }
}

struct FavoriteContactsEntry: TimelineEntry {
  let date: Date
  let contacts: [WidgetContact]
}

struct FavoriteContactsProvider: TimelineProvider {
  func placeholder(in context: Context) -> FavoriteContactsEntry {
    FavoriteContactsEntry(date: Date(), contacts: [
      WidgetContact(
        id: URL(string: "timelines://placeholder")!,
        name: "Jane Doe",
        timezone: TimeZone(secondsFromGMT: TimeZone.autoupdatingCurrent.secondsFromGMT() - 9 * 3600),
        coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41),
        startTime: nil,
        endTime: nil
      )
    ])
  }

  func getSnapshot(in context: Context, completion: @escaping (FavoriteContactsEntry) -> Void) {
    let contacts = fetchFavoriteContacts()
    if context.isPreview && contacts.isEmpty {
      completion(placeholder(in: context))
    } else {
      completion(FavoriteContactsEntry(date: Date(), contacts: contacts))
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteContactsEntry>) -> Void) {
    let contacts = fetchFavoriteContacts()

    // one entry per 15 minutes so the lines and displayed times stay current,
    // then ask for a new timeline
    let now = Date()
    let entries = (0..<8).map { offset in
      FavoriteContactsEntry(date: now.addingTimeInterval(TimeInterval(offset) * 15 * 60), contacts: contacts)
    }

    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func fetchFavoriteContacts() -> [WidgetContact] {
    CoreDataManager.shared.fetch()
      .filter { $0.favorite }
      .map { contact in
        WidgetContact(
          id: contact.objectID.uriRepresentation(),
          name: contact.name ?? "",
          timezone: contact.timeZone,
          coordinate: contact.location,
          startTime: contact.startTime,
          endTime: contact.endTime
        )
      }
  }
}

struct ContactLineRow: View {
  let contact: WidgetContact
  let time: Date

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(contact.timezone?.prettyPrintTimeDiff() ?? "")
          .font(.caption)
          .foregroundColor(Color(UIColor.secondaryLabel))
        Text(contact.name)
          .font(.system(size: 22))
          .lineLimit(1)
      }

      Spacer()

      Line(
        coordinate: contact.coordinate,
        timezone: contact.timezone,
        startTime: contact.startTime,
        endTime: contact.endTime,
        time: time
      )
      .frame(width: 180, height: 56, alignment: .trailing)
      .offset(y: 18)
    }
  }
}

struct SmallContactView: View {
  let contact: WidgetContact
  let time: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(contact.timezone?.prettyPrintTimeDiff() ?? "")
        .font(.caption)
        .foregroundColor(Color(UIColor.secondaryLabel))
      Text(contact.name)
        .font(.system(size: 24))
        .lineLimit(2)
        .minimumScaleFactor(0.6)
      Spacer()
      Text(contact.timezone?.prettyPrintTime(time) ?? "")
        .font(.system(size: 28, weight: .light))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding()
  }
}

struct NoFavoriteView: View {
  var body: some View {
    Text("Mark some contacts as favorite in Time Lines to see them here.")
      .font(.caption)
      .foregroundColor(Color(UIColor.secondaryLabel))
      .multilineTextAlignment(.center)
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct TimeLineWidgetEntryView: View {
  @Environment(\.widgetFamily) var family

  var entry: FavoriteContactsEntry

  private var maxRows: Int {
    switch family {
    case .systemLarge: return 4
    default: return 2
    }
  }

  var body: some View {
    if entry.contacts.isEmpty {
      NoFavoriteView()
    } else if family == .systemSmall {
      SmallContactView(contact: entry.contacts[0], time: entry.date)
        .widgetURL(entry.contacts[0].url)
    } else {
      VStack(spacing: 0) {
        ForEach(entry.contacts.prefix(maxRows)) { contact in
          if let url = contact.url {
            Link(destination: url) {
              ContactLineRow(contact: contact, time: entry.date)
            }
          } else {
            ContactLineRow(contact: contact, time: entry.date)
          }
        }
      }
      .padding(.horizontal)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

extension View {
  // iOS 17 requires widgets to use the containerBackground API when built
  // with a modern SDK; a material also gives the widget a glassy look
  @ViewBuilder func widgetContainerBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(.ultraThinMaterial, for: .widget)
    } else {
      self
    }
  }
}

@main
struct TimeLineWidget: Widget {
  let kind: String = "TimeLineWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FavoriteContactsProvider()) { entry in
      TimeLineWidgetEntryView(entry: entry)
        .widgetContainerBackground()
    }
    .configurationDisplayName("Time Lines")
    .description("See the time lines of your favorite contacts.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct TimeLineWidget_Previews: PreviewProvider {
  static var previews: some View {
    TimeLineWidgetEntryView(
      entry: FavoriteContactsEntry(date: Date(), contacts: [
        WidgetContact(
          id: URL(string: "timelines://placeholder")!,
          name: "Jane Doe",
          timezone: TimeZone(secondsFromGMT: TimeZone.autoupdatingCurrent.secondsFromGMT() - 9 * 3600),
          coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41),
          startTime: nil,
          endTime: nil
        )
      ])
    )
    .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
