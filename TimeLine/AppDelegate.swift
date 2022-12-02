//
//  AppDelegate.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import UIKit
import CoreData
import TimeLineShared

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var container: NSManagedObjectContext?
  var watchHandler: WatchHandler?
  var state: RouteState?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    state = RouteState.shared
    container = CoreDataManager.shared.viewContext
    watchHandler = WatchHandler.shared

    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
}
