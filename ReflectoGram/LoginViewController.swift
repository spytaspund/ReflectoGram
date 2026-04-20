//
//  LoginViewController.swift
//  ReflectoGram
//
//  Created by spytaspund on 13.02.2026.
//

import Foundation
import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var serverAddressField: UITextField!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var connectButton: UIButton!
    
    var isReadyToExit = false
    var isFetchingQR = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.groupTableViewBackground
        
        let defaults = UserDefaults.standard
        let sUrl = defaults.string(forKey: "serverUrl") ?? nil
        
        if sUrl != nil {
            serverAddressField.text = sUrl
            checkExistingSession()
        }
    }

    @IBAction func connectButtonPressed(_ sender: Any) {
        if isReadyToExit {
            self.dismiss(animated: true, completion: nil)
            if let rootVC = self.storyboard?.instantiateViewController(withIdentifier: "RootVC") {
                self.present(rootVC, animated: true, completion: nil)
            }
            return
        }
        guard let url = serverAddressField.text, !url.isEmpty else { return }
        performConnection(urlString: url)
    }
    
    func checkExistingSession() {
        let defaults = UserDefaults.standard
        guard let serverUrl = defaults.string(forKey: "serverUrl"),
              let sessionId = defaults.string(forKey: "sessionId") else {
            return
        }
        if isFetchingQR { return }

        let checkUrl = "\(serverUrl)/api/check_session?session_id=\(sessionId)"
        guard let url = URL(string: checkUrl) else { return }
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: url), queue: .main) { [weak self] (response, data, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    self?.performConnection(urlString: serverUrl)
                } else if httpResponse.statusCode == 200 {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    func performConnection(urlString: String) {
        if isFetchingQR { return }
        isFetchingQR = true
        var cleanUrl = urlString
        if !cleanUrl.hasPrefix("http") {
            cleanUrl = "http://" + cleanUrl
        }
        serverAddressField.isEnabled = false
        connectButton.isEnabled = false
        serverAddressField.alpha = 0.6
        
        let fullPath = "\(cleanUrl)/qr"
        guard let requestUrl = URL(string: fullPath) else { return }
        let request = URLRequest(url: requestUrl)

        print("LOGIN: Requesting QR at \(fullPath)...")

        NSURLConnection.sendAsynchronousRequest(request, queue: .main) { [weak self] (response, data, error) in
            guard let self = self else { return }
            if let httpResponse = response as? HTTPURLResponse {
                let headers = httpResponse.allHeaderFields
                let sessionId = headers["x-session-id"] as? String
                let aesKey = headers["x-aes-key"] as? String
                if let sId = sessionId, let aKey = aesKey {
                    let defaults = UserDefaults.standard
                    defaults.set(sId, forKey: "sessionId")
                    defaults.set(aKey, forKey: "aesKey")
                    defaults.synchronize()
                }
            }
            if let imageData = data, let image = UIImage(data: imageData) {
                self.qrImageView.image = image
                self.isReadyToExit = true
                self.connectButton.isEnabled = true
                self.connectButton.setTitle("Exit", for: .normal)
                UserDefaults.standard.set(cleanUrl, forKey: "serverUrl")
                UserDefaults.standard.synchronize()
            } else {
                self.resetUI()
            }
        }
    }
    func resetUI() {
        DispatchQueue.main.async {
            self.serverAddressField.isEnabled = true
            self.connectButton.isEnabled = true
            self.serverAddressField.alpha = 1.0
            self.connectButton.setTitle("Connect", for: .normal)
        }
    }
}
