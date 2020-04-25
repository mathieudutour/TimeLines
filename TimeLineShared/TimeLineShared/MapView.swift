/*
Copyright © 2020 Apple Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Abstract:
A view that hosts an `MKMapView`.
*/

import SwiftUI
import MapKit

class MapViewDelegate: NSObject, MKMapViewDelegate {}

public struct MapView {
  public var coordinate: CLLocationCoordinate2D
  public var span: Double

  private let delegate = MapViewDelegate()

  public init(coordinate: CLLocationCoordinate2D, span: Double = 0.02) {
    self.coordinate = coordinate
    self.span = span
  }

  func makeMapView() -> MKMapView {
    let view = MKMapView(frame: .zero)
    view.delegate = delegate
    return view
  }

  func updateMapView(_ uiView: MKMapView) {
      let coordSpan = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
      let region = MKCoordinateRegion(center: coordinate, span: coordSpan)
      uiView.setRegion(region, animated: true)
  }
}

#if os(iOS) || os(tvOS) || os(watchOS)
  extension MapView: UIViewRepresentable {
    public func makeUIView(context: Context) -> MKMapView {
      makeMapView()
    }

    public func updateUIView(_ uiView: MKMapView, context: Context) {
      updateMapView(uiView)
    }
  }
#elseif os(macOS)
  extension MapView: NSViewRepresentable {
    public func makeNSView(context: Context) -> MKMapView {
      makeMapView()
    }

    public func updateNSView(_ uiView: MKMapView, context: Context) {
      updateMapView(uiView)
    }
  }
#endif

struct MapView_Previews: PreviewProvider {
  static var previews: some View {
    return MapView(coordinate: CLLocationCoordinate2D(latitude: 34.011286, longitude: -116.166868))
  }
}
