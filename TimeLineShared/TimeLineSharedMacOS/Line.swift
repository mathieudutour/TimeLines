//
//  Line.swift
//  TimeLineSharedMacOS
//
//  Created by Mathieu Dutour on 04/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import CoreLocation
import Cocoa

public extension NSBezierPath {
  var cgPath: CGPath {
    let path = CGMutablePath()
    var points = [CGPoint](repeating: .zero, count: 3)

    for i in 0 ..< self.elementCount {
      let type = self.element(at: i, associatedPoints: &points)
      switch type {
      case .moveTo:
        path.move(to: points[0])
      case .lineTo:
        path.addLine(to: points[0])
      case .curveTo:
        path.addCurve(to: points[2], control1: points[0], control2: points[1])
      case .closePath:
        path.closeSubpath()
      default: break
      }
    }

    return path
  }

  func addLine(to point: CGPoint) {
    return self.line(to: point)
  }

  func addCurve(to point: CGPoint, controlPoint1 cp1: CGPoint, controlPoint2 cp2: CGPoint) {
    return self.curve(to: point, controlPoint1: cp1, controlPoint2: cp2)
  }
}

public class CustomLine: NSView {
  private var solar: Solar?

  var coordinate: CLLocationCoordinate2D? {
    didSet(oldValue) {
      solar = Solar(coordinate: coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
    }
  }
  var timezone: TimeZone?

  let lineWidth: CGFloat = 2
  let maxHeight: CGFloat = 25

  private let cal = Calendar(identifier: .gregorian)
  private let lineLayer = CAShapeLayer()
  private let circleLayer = CAShapeLayer()
  private let textLayer = CATextLayer()
  private var addedLayers = false

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }

  init(frame: CGRect, timezone: TimeZone?, coordinate: CLLocationCoordinate2D?) {
    super.init(frame: frame)
    self.coordinate = coordinate
    self.timezone = timezone

    lineLayer.strokeColor = NSColor.labelColor.cgColor
    lineLayer.fillColor = NSColor.clear.cgColor
    lineLayer.lineWidth = lineWidth
    lineLayer.position = CGPoint(x: 0, y: 0)

    circleLayer.strokeColor = NSColor.labelColor.cgColor
    circleLayer.fillColor = NSColor.labelColor.cgColor
    circleLayer.position = CGPoint(x: 0, y: 0)

    textLayer.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
    textLayer.foregroundColor = NSColor.labelColor.cgColor
    textLayer.fontSize = 15

    textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func draw(_ rect: CGRect) {
    if let layer = self.layer, !addedLayers {
      addedLayers = true
      layer.addSublayer(lineLayer)
      layer.addSublayer(circleLayer)
      layer.addSublayer(textLayer)
    }

    lineLayer.path = createBezierPath().cgPath
    circleLayer.path = createCirclePath().cgPath

    textLayer.string = NSString(string: dateFormatter.string(from: dateInTimeZone(Date())))
    textLayer.frame = textPosition()
  }

  private func dateInTimeZone(_ date: Date) -> Date {
    return date.addingTimeInterval(TimeInterval(timezone?.diffInSecond() ?? 0))
  }

  private func lineFrame() -> CGRect {
    let length = frame.width - lineWidth * 2
    let height = min(frame.height - lineWidth * 2, maxHeight)
    let startHeight = height == maxHeight ? height / 2 : lineWidth
    return CGRect(x: lineWidth, y: startHeight, width: length, height: height)
  }

  private func point(_ date: Date) -> CGFloat {
    let inTZ = dateInTimeZone(date)
    return CGFloat(inTZ.timeIntervalSince(cal.startOfDay(for: inTZ)) / (3600 * 24))
  }

  func createBezierPath() -> NSBezierPath {
    let frame = lineFrame()

    // create a new path
    let path = NSBezierPath()

    path.move(to: CGPoint(
      x: frame.origin.x,
      y: frame.origin.y)
    )

    guard
      let solar = solar,
      let sunrise = solar.civilSunrise,
      let sunset = solar.civilSunset
    else {
      path.addLine(to: CGPoint(
        x: frame.origin.x + frame.width,
        y: frame.origin.y)
      )

      return path
    }

    let sunrisePoint = point(sunrise)
    let sunsetPoint = point(sunset)

    #if DEBUG
      print("sunrise: \(sunrise), sunset: \(sunset), sunrisePoint: \(sunrisePoint), sunsetPoint: \(sunsetPoint)")
    #endif

    path.addLine(to: CGPoint(
      x: frame.origin.x + frame.width * CGFloat(sunrisePoint),
      y: frame.origin.y
    ))

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) / 2 + sunrisePoint),
        y: frame.origin.y + frame.height
      ),
      controlPoint1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunrisePoint),
        y: frame.origin.y
      ),
      controlPoint2: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) / 5 + sunrisePoint),
        y: frame.origin.y + frame.height
      )
    )

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunsetPoint),
        y: frame.origin.y
      ),
      controlPoint1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) * 4 / 5 + sunrisePoint),
        y: frame.origin.y + frame.height
      ),
      controlPoint2: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunsetPoint),
        y: frame.origin.y
      )
    )

    path.addLine(to: CGPoint(
      x: frame.origin.x + frame.width,
      y: frame.origin.y)
    )

    return path
  }

  private func circlePosition() -> CGPoint {
    let frame = lineFrame()

    let time = Date()

    let timePoint = point(time)

    guard
      let solar = solar,
      let sunrise = solar.civilSunrise,
      let sunset = solar.civilSunset
    else {
      return CGPoint(
        x: frame.origin.x + frame.width * CGFloat(timePoint),
        y: frame.origin.y + frame.height
      )
    }

    let sunrisePoint = point(sunrise)
    let sunsetPoint = point(sunset)

    var y: CGFloat = frame.origin.y

    if timePoint < sunsetPoint && timePoint > sunrisePoint {
      // find the position on the parabola
      let w = frame.width * (sunsetPoint - sunrisePoint)
      let x1 = frame.origin.x + frame.width * CGFloat(sunrisePoint)
      let c = y
      let b = 4 * frame.height / w
      let a = -b / w
      let x = frame.width * CGFloat(timePoint) - x1
      y = a * x * x + b * x + c
    }

    return CGPoint(
      x: frame.origin.x + frame.width * CGFloat(timePoint),
      y: y
    )
  }

  func createCirclePath() -> NSBezierPath {
    let pos = circlePosition()
    let rect = CGRect(
      x: pos.x - lineWidth * 1.5, y: pos.y - lineWidth * 1.5,
      width: lineWidth * 3, height: lineWidth * 3
    )
    let path = NSBezierPath()
    path.appendOval(in: rect)
    return path
  }

  func textPosition() -> CGRect {
    guard let string = textLayer.string as? String else {
      return .zero
    }
    let pos = circlePosition()
    let size = NSString(string: string).size(withAttributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 15)])

    var x = pos.x

    if x < frame.width / 2 {
      x = x - size.width
    }

    return CGRect(
      x: max(min(x, frame.width - size.width), 0),
      y: pos.y,
      width: size.width + 5,
      height: size.height + 5
    )
  }
}

public struct Line: NSViewRepresentable {
  public var coordinate: CLLocationCoordinate2D?
  public var timezone: TimeZone?

  public func makeNSView(context: Context) -> CustomLine {
    let view = CustomLine(frame: .zero, timezone: timezone, coordinate: coordinate)
    view.wantsLayer = true
    return view
  }

  public func updateNSView(_ uiView: CustomLine, context: Context) {
    uiView.coordinate = coordinate
    uiView.timezone = timezone
    uiView.setNeedsDisplay(uiView.frame)
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
