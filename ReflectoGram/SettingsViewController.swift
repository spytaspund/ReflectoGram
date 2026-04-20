//
//  SettingsViewController.swift
//  ReflectoGram
//
//  Created by spytaspund tbf on 25.02.2026.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var serverField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        if let savedUrl = defaults.string(forKey: "serverUrl") {
            if serverField != nil {
                self.serverField.text = savedUrl
            }
        }
    }
    @IBAction func saveSettings(_ sender: Any) {
        let defaults = UserDefaults.standard
        let url = self.serverField.text ?? ""
        let cleanUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(cleanUrl, forKey: "serverUrl")
        defaults.synchronize()
    }
}
