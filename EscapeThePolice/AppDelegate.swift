// AppDelegate.swift
import UIKit
import FirebaseCore

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Initialize Firebase here—after this point, all swizzling works
    FirebaseApp.configure()
    return true
  }
}
