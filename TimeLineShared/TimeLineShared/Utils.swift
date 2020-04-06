//
//  Utils.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 06/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import SystemConfiguration

struct System {
  static let osVersion: String = {
    let os = ProcessInfo.processInfo.operatingSystemVersion
    return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
  }()

  static let hardwareModel: String = {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    return String(cString: model)
  }()
}

private func escapeQuery(_ query: String) -> String {
  // From RFC 3986
  let generalDelimiters = ":#[]@"
  let subDelimiters = "!$&'()*+,;="

  var allowedCharacters = CharacterSet.urlQueryAllowed
  allowedCharacters.remove(charactersIn: generalDelimiters + subDelimiters)
  return query.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? query
}


extension Dictionary where Key: ExpressibleByStringLiteral, Value: ExpressibleByStringLiteral {
  var asQueryItems: [URLQueryItem] {
    map {
      URLQueryItem(
        name: escapeQuery($0 as! String),
        value: escapeQuery($1 as! String)
      )
    }
  }

  var asQueryString: String {
    var components = URLComponents()
    components.queryItems = asQueryItems
    return components.query!
  }
}

extension URLComponents {
  mutating func addDictionaryAsQuery(_ dict: [String: String]) {
    percentEncodedQuery = dict.asQueryString
  }
}

extension URL {
  func addingDictionaryAsQuery(_ dict: [String: String]) -> Self {
    var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
    components.addDictionaryAsQuery(dict)
    return components.url ?? self
  }
}

public struct App {
  public static let id = Bundle.main.bundleIdentifier!
  public static let name = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
  static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
  static let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
  static let versionWithBuild = "\(version) (\(build))"
  static let url = Bundle.main.bundleURL

  public static let isFirstLaunch: Bool = {
    let key = "SS_hasLaunched"

    if UserDefaults.standard.bool(forKey: key) {
      return false
    } else {
      UserDefaults.standard.set(true, forKey: key)
      return true
    }
  }()

  public static var feedbackPage: URL = {
    let metadata =
      """


      ---
      \(App.name) \(App.versionWithBuild) - \(App.id)
      macOS \(System.osVersion)
      \(System.hardwareModel)
      """

    let query: [String: String] = [
      "title": "[Feedback]",
      "body": metadata
    ]

    return URL(string: "https://github.com/mathieudutour/TimeLine/issues/new")!.addingDictionaryAsQuery(query)
  }()
}
