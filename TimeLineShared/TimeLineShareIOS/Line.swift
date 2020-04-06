//
//  Line.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import UIKit
import SwiftUI
import CoreLocation

public class CustomLine: UIView {
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

    lineLayer.strokeColor = UIColor.label.cgColor
    lineLayer.fillColor = UIColor.clear.cgColor
    lineLayer.lineWidth = lineWidth
    lineLayer.position = CGPoint(x: 0, y: 0)

    circleLayer.strokeColor = UIColor.label.cgColor
    circleLayer.fillColor = UIColor.label.cgColor
    circleLayer.position = CGPoint(x: 0, y: 0)

    textLayer.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
    textLayer.foregroundColor = UIColor.label.cgColor
    textLayer.fontSize = 15
    textLayer.contentsScale = UIScreen.main.scale

    self.layer.addSublayer(lineLayer)
    self.layer.addSublayer(circleLayer)
    self.layer.addSublayer(textLayer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func draw(_ rect: CGRect) {
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
    let startHeight = height == maxHeight ? (frame.height - height) / 2 : lineWidth
    return CGRect(x: lineWidth, y: startHeight, width: length, height: height)
  }

  private func point(_ date: Date) -> CGFloat {
    let inTZ = dateInTimeZone(date)
    return CGFloat(inTZ.timeIntervalSince(cal.startOfDay(for: inTZ)) / (3600 * 24))
  }

  func createBezierPath() -> UIBezierPath {
    let frame = lineFrame()

    // create a new path
    let path = UIBezierPath()

    path.move(to: CGPoint(
      x: frame.origin.x,
      y: frame.origin.y + frame.height)
    )

    guard
      let solar = solar,
      let sunrise = solar.civilSunrise,
      let sunset = solar.civilSunset
    else {
      path.addLine(to: CGPoint(
        x: frame.origin.x + frame.width,
        y: frame.origin.y + frame.height)
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
      y: frame.origin.y + frame.height
    ))

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) / 2 + sunrisePoint),
        y: frame.origin.y
      ),
      controlPoint1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunrisePoint),
        y: frame.origin.y + frame.height
      ),
      controlPoint2: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) / 5 + sunrisePoint),
        y: frame.origin.y
      )
    )

    path.addCurve(
      to: CGPoint(
        x: frame.origin.x + frame.width * CGFloat(sunsetPoint),
        y: frame.origin.y + frame.height
      ),
      controlPoint1: CGPoint(
        x: frame.origin.x + frame.width * CGFloat((sunsetPoint - sunrisePoint) * 4 / 5 + sunrisePoint),
        y: frame.origin.y
      ),
      controlPoint2: CGPoint(
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

  func createCirclePath() -> UIBezierPath {
    return UIBezierPath(
      arcCenter: circlePosition(),
      radius: lineWidth * 1.5,
      startAngle: 0,
      endAngle: CGFloat(Double.pi * 2),
      clockwise: true
    )
  }

  func textPosition() -> CGRect {
    guard let string = textLayer.string as? String else {
      return .zero
    }
    let pos = circlePosition()
    let size = NSString(string: string).size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])

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
}

public struct Line: UIViewRepresentable {
  public var coordinate: CLLocationCoordinate2D?
  public var timezone: TimeZone?

  public init(coordinate: CLLocationCoordinate2D?, timezone: TimeZone?) {
    self.coordinate = coordinate
    self.timezone = timezone
  }

  public func makeUIView(context: Context) -> CustomLine {
    CustomLine(frame: .zero, timezone: timezone, coordinate: coordinate)
  }

  public func updateUIView(_ uiView: CustomLine, context: Context) {
    uiView.coordinate = coordinate
    uiView.timezone = timezone
    uiView.setNeedsDisplay()
  }
}

public struct Line_Previews: PreviewProvider {
  public static var previews: some View {
    Group {
      Line(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timezone: TimeZone(secondsFromGMT: 0)!)
      Line(coordinate: CLLocationCoordinate2D(latitude: 40, longitude: -74), timezone: TimeZone(secondsFromGMT: -4 * 3600)!)
      Line(coordinate: CLLocationCoordinate2D(latitude: 35, longitude: 140), timezone: TimeZone(secondsFromGMT: 9 * 3600)!)
      Line(coordinate: CLLocationCoordinate2D(latitude: 80, longitude: 80), timezone: TimeZone(secondsFromGMT: -8000)!)
    }
    .previewLayout(.fixed(width: 220, height: 80))
  }
}
