//
//  TodayViewController.swift
//  TimeLine Widget
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import UIKit
import NotificationCenter
import SwiftUI
import TimeLineShared
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding {
  override func viewDidLoad() {
    super.viewDidLoad()

    extensionContext?.widgetLargestAvailableDisplayMode = .expanded

    self.preferredContentSize = CGSize(width: 0, height: CoreDataManager.shared.count() * (80 + 13))
  }

  func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {

    if activeDisplayMode == NCWidgetDisplayMode.compact {
      self.preferredContentSize = CGSize(width: maxSize.width, height: 80)
    } else {
      self.preferredContentSize = CGSize(width: maxSize.width, height: CGFloat(CoreDataManager.shared.count() * (80 + 13)))
    }
  }
        
  @IBSegueAction func addSwiftUIView(_ coder: NSCoder) -> UIViewController? {
    // Get the managed object context from the shared persistent container.
    let context = CoreDataManager.shared.viewContext

    // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
    // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
    let contentView = WidgetView()
      .environment(\.managedObjectContext, context)
      .background(Color.clear)

    let vc = UIHostingController(coder: coder, rootView: contentView)
    vc?.view.backgroundColor = .clear

    return vc
  }

  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    // Perform any setup necessary in order to update the view.

    // If an error is encountered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData

    completionHandler(NCUpdateResult.newData)
  }

}
