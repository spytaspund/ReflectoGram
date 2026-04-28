//
//  LoginViewController.swift
//  ReflectoGram
//
//  Created by spytaspund on 13.02.2026.
//

import Foundation
import UIKit
import QuartzCore

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var serverAddressField: UITextField!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var buttonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fieldHeightConstraint: NSLayoutConstraint!
    
    var isReadyToExit = false
    var isFetchingQR = false
    var buttonGradient: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.groupTableViewBackground
        
        serverAddressField.delegate = self
        qrImageView.image = UIImage(named: "reflectogram")
        qrImageView.layer.cornerRadius = 16
        connectButton.titleLabel?.adjustsFontSizeToFitWidth = true
        connectButton.titleLabel?.minimumScaleFactor = 0.5
        connectButton.titleLabel?.lineBreakMode = .byClipping
        
        let defaults = UserDefaults.standard
        if let sUrl = defaults.string(forKey: "serverUrl") {
            serverAddressField.text = sUrl
            checkExistingSession()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupButtonStyle()
    }

    func setupButtonStyle() {
        if self.view.responds(to: #selector(getter: UIView.tintColor)) {
            // iOS 7+
            connectButton.backgroundColor = self.view.tintColor
            connectButton.setTitleColor(.white, for: .normal)
            connectButton.layer.cornerRadius = 8
            buttonGradient?.removeFromSuperlayer()
        } else {
            // iOS 6
            if buttonGradient == nil {
                buttonGradient = CAGradientLayer()
                buttonGradient?.colors = [
                    UIColor(red: 0.45, green: 0.70, blue: 0.98, alpha: 1.0).cgColor,
                    UIColor(red: 0.12, green: 0.45, blue: 0.88, alpha: 1.0).cgColor
                ]
                buttonGradient?.cornerRadius = 8
                buttonGradient?.borderColor = UIColor.darkGray.cgColor
                buttonGradient?.borderWidth = 1
                connectButton.layer.insertSublayer(buttonGradient!, at: 0)
                connectButton.setTitleColor(.black, for: .normal)
            }
            buttonGradient?.frame = connectButton.bounds
        }
    }

    @IBAction func connectButtonPressed(_ sender: Any) {
        handleAction()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        handleAction()
        return true
    }
    
    func handleAction() {
        if isReadyToExit {
            verifySessionAndExit()
            return
        }
        guard let url = serverAddressField.text, !url.isEmpty else { return }
        serverAddressField.resignFirstResponder()
        performConnection(urlString: url)
    }
    
    func verifySessionAndExit() {
        let defaults = UserDefaults.standard
        guard let serverUrl = defaults.string(forKey: "serverUrl"),
              let sessionId = defaults.string(forKey: "sessionId") else {
            return
        }
        
        connectButton.setTitle("...", for: .normal)
        connectButton.isEnabled = false
        
        let checkUrl = "\(serverUrl)/chats?session_id=\(sessionId)"
        guard let url = URL(string: checkUrl) else { return }
        
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: url), queue: .main) { [weak self] (response, data, error) in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                self.safeDismiss()
            } else {
                self.connectButton.setTitle("Exit", for: .normal)
                self.connectButton.isEnabled = true
            }
        }
    }

    func safeDismiss() { // ios 6 shenanigans
        if let window = UIApplication.shared.keyWindow,
           let rootVC = self.storyboard?.instantiateViewController(withIdentifier: "RootVC") {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = rootVC
            }, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func checkExistingSession() {
        let defaults = UserDefaults.standard
        guard let serverUrl = defaults.string(forKey: "serverUrl"),
              let sessionId = defaults.string(forKey: "sessionId") else { return }
        if isFetchingQR { return }

        let checkUrl = "\(serverUrl)/chats?session_id=\(sessionId)"
        guard let url = URL(string: checkUrl) else { return }
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: url), queue: .main) { [weak self] (response, data, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 403 {
                    self?.performConnection(urlString: serverUrl)
                } else if httpResponse.statusCode == 200 {
                    self?.safeDismiss()
                }
            }
        }
    }

    func performConnection(urlString: String) {
        if isFetchingQR { return }
        isFetchingQR = true
        var cleanUrl = urlString
        if !cleanUrl.hasPrefix("http") { cleanUrl = "http://" + cleanUrl }
        
        serverAddressField.isEnabled = false
        connectButton.isEnabled = false
        serverAddressField.alpha = 0.6
        connectButton.setTitle("...", for: .normal)
        
        let fullPath = "\(cleanUrl)/qr"
        guard let requestUrl = URL(string: fullPath) else {
            handleFailure()
            return
        }

        NSURLConnection.sendAsynchronousRequest(URLRequest(url: requestUrl), queue: .main) { [weak self] (response, data, error) in
            guard let self = self else { return }
            self.isFetchingQR = false
            
            if error != nil {
                self.handleFailure()
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let headers = httpResponse.allHeaderFields
                let sessionId = headers["x-session-id"] as? String
                let aesKey = headers["x-aes-key"] as? String
                
                if let sId = sessionId, let aKey = aesKey {
                    let defaults = UserDefaults.standard
                    defaults.set(sId, forKey: "sessionId")
                    defaults.set(aKey, forKey: "aesKey")
                    defaults.set(cleanUrl, forKey: "serverUrl")
                    defaults.synchronize()
                } else {
                    self.handleFailure()
                    return
                }
            }
            
            if let imageData = data, let image = UIImage(data: imageData) {
                UIView.transition(with: self.qrImageView, duration: 0.8, options: .transitionFlipFromRight, animations: {
                    self.qrImageView.image = image
                }, completion: nil)
                self.serverAddressField.isEnabled = false
                self.isReadyToExit = true
                self.connectButton.setTitle("Exit", for: .normal)
                self.connectButton.isEnabled = true
                //self.animateSuccessUI()
            } else {
                self.handleFailure()
            }
        }
    }
    
    func handleFailure() {
        DispatchQueue.main.async {
            self.isFetchingQR = false
            self.serverAddressField.isEnabled = true
            self.connectButton.isEnabled = true
            self.serverAddressField.alpha = 1.0
            self.connectButton.setTitle("Retry", for: .normal)
        }
    }
    
    // need to implement that later, pretty cool feature
    /*func animateSuccessUI() {
        isReadyToExit = true
        if let widthConst = buttonWidthConstraint {
            connectButton.removeConstraint(widthConst)
        }
        
        self.buttonLeadingConstraint.constant = 20
        self.buttonTrailingConstraint.constant = 20
        
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
            self.serverAddressField.alpha = 0.0
            
            self.view.layoutIfNeeded()
            self.buttonGradient?.frame = self.connectButton.bounds
            
        }, completion: { _ in
            self.connectButton.setTitle("Exit", for: .normal)
            self.connectButton.isEnabled = true
            self.serverAddressField.isHidden = true
        })
    }*/
}
