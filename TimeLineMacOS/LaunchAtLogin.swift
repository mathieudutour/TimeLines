import Foundation
import ServiceManagement
import SwiftUI
import TimeLineSharedMacOS

public struct LaunchAtLogin {
  private static let id = "\(App.id)MacOS-launchagent"

  public static var isEnabled: Bool {
    get {
      guard let jobs = (SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]) else {
        return false
      }

      let job = jobs.first { $0["Label"] as! String == id }

      return job?["OnDemand"] as? Bool ?? false
    }
    set {
      SMLoginItemSetEnabled(id as CFString, newValue)
    }
  }
}

extension LaunchAtLogin {
  struct Toggle: View {
    @State private var launchAtLogin = isEnabled

    var body: some View {
      SwiftUI.Toggle(
        "Launch at Login",
        isOn: $launchAtLogin.onChange {
          isEnabled = $0
        }
      )
    }
  }
}
