//
//  Line.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 04/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import CoreLocation

#if os(iOS) || os(tvOS) || os(watchOS)
  import UIKit
  public typealias CPFont = UIFont
#elseif os(macOS)
  import Cocoa
  public typealias CPFont = NSFont
#endif

fileprivate let cal = Calendar(identifier: .gregorian)

fileprivate func dateInTimeZone(_ date: Date, _ timezone: TimeZone?) -> Date {
  return date.addingTimeInterval(TimeInterval(timezone?.diffInSecond() ?? 0))
}
fileprivate func point(_ date: Date, _ timezone: TimeZone?) -> CGFloat {
  let inTZ = dateInTimeZone(date, timezone)
  return CGFloat(inTZ.timeIntervalSince(cal.startOfDay(for: inTZ)) / (3600 * 24))
}

fileprivate let defaultLineWidth: CGFloat = 2
fileprivate let defaultMaxHeight: CGFloat = 25

fileprivate func circlePosition(frame: CGRect, timezone: TimeZone?, sunrise: Date?, sunset: Date?) -> CGPoint {
  let time = Date()

  let timePoint = point(time, timezone)

  guard
    let sunrise = sunrise,
    let sunset = sunset
  else {
    return CGPoint(
      x: frame.origin.x + frame.width * CGFloat(timePoint),
      y: frame.origin.y + frame.height
    )
  }

  let sunrisePoint = point(sunrise, timezone)
  let sunsetPoint = point(sunset, timezone)

  var y: CGFloat = frame.origin.y + frame.height

  if timePoint < sunsetPoint && timePoint > sunrisePoint {
    // find the position on the parabola
    let w = frame.width * (sunsetPoint - sunrisePoint)
    let x1 = frame.width * CGFloat(sunrisePoint)
    let c = y
    let b = -4 * frame.height / w
    let a = -b / w
    let x = frame.width * CGFloat(timePoint) - x1
    y = a * x * x + b * x + c
  }

  return CGPoint(
    x: frame.origin.x + frame.width * CGFloat(timePoint),
    y: y
  )
}

struct ParabolaLine: Shape {
  var timezone: TimeZone?
  var sunrise: Date?
  var sunset: Date?

  func path(in frame: CGRect) -> Path {
    var path = Path()

    path.move(to: CGPoint(
      x: frame.origin.x,
      y: frame.origin.y + frame.height)
    )

    guard
      let sunrise = sunrise,
      let sunset = sunset
    else {
      path.addLine(to: CGPoint(
        x: frame.origin.x + frame.width,
        y: frame.origin.y + frame.height)
      )

      return path
    }

    let sunrisePoint = point(sunrise, timezone)
    let sunsetPoint = point(sunset, timezone)

    path.addLine(to: CGPoint(
      x: frame.origin.x + frame.width * CGFloat(sunrisePoint),
      y: frame.origin.y + frame.height
    ))

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) / 2 + sunrisePoint),
        y: frame.origin.y
      ),
      control1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunrisePoint),
        y: frame.origin.y + frame.height
      ),
      control2: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) / 5 + sunrisePoint),
        y: frame.origin.y
      )
    )

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunsetPoint),
        y: frame.origin.y + frame.height
      ),
      control1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) * 4 / 5 + sunrisePoint),
        y: frame.origin.y
      ),
      control2: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunsetPoint),
        y: frame.origin.y + frame.height
      )
    )

    path.addLine(to: CGPoint(
      x: frame.origin.x + frame.width,
      y: frame.origin.y + frame.height)
    )

    return path
  }
}

struct CurrentTimeCircle: Shape {
  var timezone: TimeZone?
  var sunrise: Date?
  var sunset: Date?

  var lineWidth: CGFloat?

  func path(in frame: CGRect) -> Path {
    var path = Path()

    let pos = circlePosition(frame: frame, timezone: timezone, sunrise: sunrise, sunset: sunset)

    path.addArc(center: pos, radius: (lineWidth ?? defaultLineWidth) * 1.5, startAngle: Angle.zero, endAngle: Angle.degrees(360), clockwise: true)

    return path
  }
}

struct CurrentTimeText: View {
  var timezone: TimeZone?
  var sunrise: Date?
  var sunset: Date?

  func getPosition(_ frame: CGRect, _ text: String?) -> CGRect {
    guard let string = text else {
      return .zero
    }
    let pos = circlePosition(frame: frame, timezone: timezone, sunrise: sunrise, sunset: sunset)
    let size = NSString(string: string).size(withAttributes: [NSAttributedString.Key.font: CPFont.systemFont(ofSize: 15)])

    var x = pos.x

    if x < frame.width / 2 {
      x = x - size.width
    }

    return CGRect(
      x: max(min(x, frame.width - size.width), 0),
      y: pos.y - 25,
      width: size.width + 5,
      height: size.height + 5
    )
  }

  var body: some View {
    let string = self.timezone?.prettyPrintCurrentTime() ?? ""
    return LineGeometryReader { p in
      VStack {
        HStack {
          Text(string)
            .offset(x: self.getPosition(p, string).origin.x, y: self.getPosition(p, string).origin.y)
          Spacer()
        }
        Spacer()
      }
    }
  }
}

struct LineGeometryReader<Content: View>: View {
  var lineWidth: CGFloat?
  var maxHeight: CGFloat?
  var content: (CGRect) -> Content

  func lineFrame(_ w: CGFloat, _ h: CGFloat) -> CGRect {
    let length = w - (lineWidth ?? defaultLineWidth) * 2
    let height = min(h - (lineWidth ?? defaultLineWidth) * 2, maxHeight ?? defaultMaxHeight)
    let startHeight = height == maxHeight ? (h - height) / 2 : (lineWidth ?? defaultLineWidth)
    return CGRect(x: lineWidth ?? defaultLineWidth, y: startHeight, width: length, height: height)
  }

  var body: some View {
    GeometryReader {
      p in
      self.content(self.lineFrame(p.size.width, p.size.height))
    }
  }
}

public struct Line: View {
  var coordinate: CLLocationCoordinate2D?
  var timezone: TimeZone?
  var lineWidth: CGFloat?
  var maxHeight: CGFloat?

  public init(coordinate: CLLocationCoordinate2D?, timezone: TimeZone?) {
    self.coordinate = coordinate
    self.timezone = timezone
  }

  public var body: some View {
    let solar = Solar(coordinate: coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))

    return LineGeometryReader { p in
      ZStack(alignment: .topLeading) {
        ParabolaLine(timezone: self.timezone, sunrise: solar?.civilSunrise, sunset: solar?.civilSunset).stroke(style: StrokeStyle(lineWidth: defaultLineWidth, lineCap: .round, lineJoin: .round))
        CurrentTimeCircle(timezone: self.timezone, sunrise: solar?.civilSunrise, sunset: solar?.civilSunset)
        CurrentTimeText(timezone: self.timezone, sunrise: solar?.civilSunrise, sunset: solar?.civilSunset)
      }
      .frame(width: p.width, height: p.height)
    }
  }
}

public struct Line_Previews: PreviewProvider {
  public static var previews: some View {
    Group {
      Line(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timezone: TimeZone(secondsFromGMT: 0)!)
      Line(coordinate: CLLocationCoordinate2D(latitude: 10, longitude: 10), timezone: TimeZone(secondsFromGMT: 3600)!)
      Line(coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 45), timezone: TimeZone(secondsFromGMT: 9200)!)
      Line(coordinate: CLLocationCoordinate2D(latitude: 45, longitude: -70), timezone: TimeZone(secondsFromGMT: -14000)!)
      Line(coordinate: CLLocationCoordinate2D(latitude: 80, longitude: 80), timezone: TimeZone(secondsFromGMT: -8000)!)
    }
    .previewLayout(.fixed(width: 300, height: 80))
  }
}
