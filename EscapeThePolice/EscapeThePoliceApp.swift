// EscapeThePoliceApp.swift
import SwiftUI

@main
struct EscapeThePoliceApp: App {
  // Connect your AppDelegate for swizzling
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
        MainView()
    }
  }
}
