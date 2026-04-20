//
//  AppDelegate.swift
//  ReflectoGram
//
//  Created by spytaspund on 07.02.2026.
//

import Foundation
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootVC = storyboard.instantiateInitialViewController() else {
            print("ERROR: No VC found in Storyboard")
            return true
        }
        if let splitVC = rootVC as? UISplitViewController {
            splitVC.delegate = self
        }
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        return true
    }
}
extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
