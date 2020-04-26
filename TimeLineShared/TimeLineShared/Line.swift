//
//  Line.swift
//  Time Lines Shared
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

fileprivate func pointFraction(_ date: Date?, _ timezone: TimeZone?) -> CGFloat? {
  guard let date = date else {
    return nil
  }
  let inTZ = date.inTimeZone(timezone)
  return CGFloat(inTZ.timeIntervalSince(cal.startOfDay(for: inTZ)) / (3600 * 24))
}

fileprivate let defaultLineWidth: CGFloat = 2
fileprivate let defaultMaxHeight: CGFloat = 25

fileprivate func pointInFrame(frame: CGRect, point: CGFloat, startPoint: CGFloat?, endPoint: CGFloat?) -> CGPoint {
  guard
    let startPoint = startPoint,
    let endPoint = endPoint
  else {
    return CGPoint(
      x: frame.origin.x + frame.width * CGFloat(point),
      y: frame.origin.y + frame.height
    )
  }

  var y: CGFloat = frame.origin.y + frame.height

  if point < endPoint && point > startPoint {
    // find the position on the parabola
    let w = frame.width * (endPoint - startPoint)
    let x1 = frame.width * CGFloat(startPoint)
    let c = y
    let b = -4 * frame.height / w
    let a = -b / w
    let x = frame.width * CGFloat(point) - x1
    y = a * x * x + b * x + c
  }

  return CGPoint(
    x: frame.origin.x + frame.width * CGFloat(point),
    y: y
  )
}

fileprivate func circlePosition(frame: CGRect, time: Date, timezone: TimeZone?, startTime: Date?, endTime: Date?) -> CGPoint {
  guard let timePoint = pointFraction(time, timezone) else {
    // that can't happen
    return CGPoint(x: 0, y: 0)
  }

  let startPoint = pointFraction(startTime, timezone)
  let endPoint = pointFraction(endTime, timezone)

  return pointInFrame(frame: frame, point: timePoint, startPoint: startPoint, endPoint: endPoint)
}

struct ParabolaLine: Shape {
  var timezone: TimeZone?
  var startTime: Date?
  var endTime: Date?

  func path(in frame: CGRect) -> Path {
    var path = Path()

    path.move(to: CGPoint(
      x: frame.origin.x,
      y: frame.origin.y + frame.height)
    )

    guard
      let startPoint = pointFraction(startTime, timezone),
      let endPoint = pointFraction(endTime, timezone)
    else {
      path.addLine(to: CGPoint(
        x: frame.origin.x + frame.width,
        y: frame.origin.y + frame.height)
      )

      return path
    }

    path.addLine(to: CGPoint(
      x: frame.origin.x + frame.width * CGFloat(startPoint),
      y: frame.origin.y + frame.height
    ))

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((endPoint - startPoint) / 2 + startPoint),
        y: frame.origin.y
      ),
      control1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(startPoint),
        y: frame.origin.y + frame.height
      ),
      control2: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((endPoint - startPoint) / 5 + startPoint),
        y: frame.origin.y
      )
    )

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(endPoint),
        y: frame.origin.y + frame.height
      ),
      control1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((endPoint - startPoint) * 4 / 5 + startPoint),
        y: frame.origin.y
      ),
      control2: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(endPoint),
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
  var now: Date
  var timezone: TimeZone?
  var startTime: Date?
  var endTime: Date?

  var lineWidth: CGFloat?

  func path(in frame: CGRect) -> Path {
    var path = Path()

    let pos = circlePosition(frame: frame, time: now, timezone: timezone, startTime: startTime, endTime: endTime)

    path.addArc(center: pos, radius: (lineWidth ?? defaultLineWidth) * 1.5, startAngle: Angle.zero, endAngle: Angle.degrees(360), clockwise: true)

    return path
  }
}

struct CurrentTimeText: View {
  var now: Date
  var timezone: TimeZone?
  var startTime: Date?
  var endTime: Date?

  private let font = CPFont.systemFont(ofSize: 18)

  func getSize(_ string: String) -> (height: CGFloat, exact: CGFloat, ceil: CGFloat, floor: CGFloat) {
    let size = NSString(string: string).size(withAttributes: [NSAttributedString.Key.font: font])

    return (size.height, size.width, ceil(size.width / 10) * 10, floor(size.width / 10) * 10)
  }

  func getPosition(_ frame: CGRect, _ text: String?) -> CGRect {
    guard let string = text else {
      return .zero
    }

    let pos = circlePosition(frame: frame, time: now, timezone: timezone, startTime: startTime, endTime: endTime)
    let stringSize = getSize(string)

    var x = pos.x
    var y = pos.y - 25

    var middle = frame.width / 2

    if
      let startTime = startTime,
      let endTime = endTime,
      let middleFraction = pointFraction(startTime.addingTimeInterval(endTime.timeIntervalSince(startTime) / 2), timezone)
    {
      middle = frame.width * middleFraction
    }

    if x < middle {
      if x < stringSize.ceil {
        let rightCorner = stringSize.ceil
        y = pointInFrame(
          frame: frame,
          point: rightCorner / frame.width,
          startPoint: pointFraction(startTime, timezone),
          endPoint: pointFraction(endTime, timezone)
        ).y - 20
      }
      x = x - stringSize.exact
    } else {
      if x > frame.width - stringSize.floor {
        let leftCorner = frame.width - stringSize.floor
        y = pointInFrame(
          frame: frame,
          point: leftCorner / frame.width,
          startPoint: pointFraction(startTime, timezone),
          endPoint: pointFraction(endTime, timezone)
        ).y - 20
      }
    }

    return CGRect(
      x: max(min(x, frame.width - stringSize.exact + 5), 0),
      y: y,
      width: stringSize.exact + 5,
      height: stringSize.height + 5
    )
  }

  var body: some View {
    let string = self.timezone?.prettyPrintTime(now) ?? ""
    return LineGeometryReader { p in
      VStack {
        HStack {
          Text(string)
            .font(Font(self.font as CTFont))
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
  @ObservedObject var currentTime = CurrentTime.shared

  var coordinate: CLLocationCoordinate2D?
  var timezone: TimeZone?
  var startTime: Date?
  var endTime: Date?

  var lineWidth: CGFloat?
  var maxHeight: CGFloat?

  public init(coordinate: CLLocationCoordinate2D?, timezone: TimeZone?, startTime: Date? = nil, endTime: Date? = nil) {
    self.coordinate = coordinate
    self.timezone = timezone
    self.startTime = startTime
    self.endTime = endTime
  }

  public var body: some View {
    let solar = coordinate != nil ? Solar(coordinate: coordinate!) : nil

    let start = startTime?.staticTime(timezone) ?? solar?.civilSunrise
    let end = endTime?.staticTime(timezone) ?? solar?.civilSunset

    let diff = Double(timezone?.diffInSecond() ?? 0) / (24 * 3600)

    return LineGeometryReader { p in
      ZStack(alignment: .topLeading) {
        ParabolaLine(timezone: self.timezone, startTime: start, endTime: end)
          .stroke(style: StrokeStyle(lineWidth: defaultLineWidth, lineCap: .round, lineJoin: .round))
        CurrentTimeCircle(now: self.currentTime.now, timezone: self.timezone, startTime: start, endTime: end)
        CurrentTimeText(now: self.currentTime.now, timezone: self.timezone, startTime: start, endTime: end)
      }
      .frame(width: p.width, height: p.height)
      .gesture(
        DragGesture()
        .onChanged { value in
          self.currentTime.customTime(Date.fractionOfToday(Double(value.location.x / p.width) - diff))
        }
      )
      .gesture(
        TapGesture()
        .onEnded { value in
          self.currentTime.releaseCustomTime()
        },
        including: self.currentTime.customTime ? .all : .subviews
      )
    }
  }
}

public struct Line_Previews: PreviewProvider {
  public static var previews: some View {
    Group {
      Line(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timezone: TimeZone(secondsFromGMT: 0), startTime: Date(timeIntervalSince1970: 16000))
      Line(coordinate: CLLocationCoordinate2D(latitude: 10, longitude: 10), timezone: TimeZone(secondsFromGMT: 3600))
      Line(coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 45), timezone: TimeZone(secondsFromGMT: 9200))
      Line(coordinate: CLLocationCoordinate2D(latitude: 45, longitude: -70), timezone: TimeZone(secondsFromGMT: -14000))
      Line(coordinate: CLLocationCoordinate2D(latitude: 80, longitude: 80), timezone: TimeZone(secondsFromGMT: -8000))
    }
    .previewLayout(.fixed(width: 300, height: 80))
  }
}
