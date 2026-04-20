//
//  ChatViewController.swift
//  ReflectoGram
//
//  Created by spytaspund on 07.02.2026.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var chats: [Chat] = []
    var imageCache: [String: UIImage] = [:]
    var cryptoKey = ""
    var serverURL = ""
    var sessionID = ""
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let defaults = UserDefaults.standard
        let savedUrl = defaults.string(forKey: "serverUrl")
        let savedId = defaults.string(forKey: "sessionId")
        let savedKey = defaults.string(forKey: "aesKey")

        if savedUrl == nil || savedId == nil || savedKey == nil {
            if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") {
                loginVC.modalPresentationStyle = .formSheet
                loginVC.modalTransitionStyle = .coverVertical
                self.present(loginVC, animated: true, completion: nil)
            }
        } else {
            self.serverURL = savedUrl!
            self.sessionID = savedId!
            self.cryptoKey = savedKey!
            loadDataFromServer()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        if let cachedChats = CacheHelper.shared.getCachedChats() {
            self.chats = cachedChats
        }
        self.tableView.reloadData()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMessages" {
            if let destinationVC = segue.destination as? MessagesViewController,
               let indexPath = sender as? IndexPath {
                destinationVC.activeChat = chats[indexPath.row]
                destinationVC.cryptoKey = self.cryptoKey
                destinationVC.serverURL = self.serverURL
                destinationVC.sessionID = self.sessionID
            }
        }
    }
    func loadDataFromServer(){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        APIHelper.shared.fetchChats(from: "\(serverURL)/chats?session_id=\(sessionID)", key: cryptoKey) { [weak self] result in
            switch result {
            case .success(let loadedChats):
                CacheHelper.shared.saveChats(loadedChats)
                self?.chats = loadedChats
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                let alert = UIAlertView(title: "API Error",
                                        message: error.localizedDescription,
                                        delegate: nil,
                                        cancelButtonTitle: "OK")
                alert.show()
            }
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell
        let chat = chats[indexPath.row]
        
        cell.titleLabel.text = chat.name
        cell.messageLabel.text = chat.lastMessage
        cell.timeLabel.text = DateHelper.shared.formatDate(chat.date)
        
        if chat.type == "user" {
            cell.avatarImageView.image = UIImage(named: "reflectogram-person")
        } else {
            cell.avatarImageView.image = UIImage(named: "reflectogram-group")
        }
        
        let chatID = chat.id
        if let memoryImage = imageCache[chatID] {
            cell.avatarImageView.image = memoryImage
        } else if let diskImage = CacheHelper.shared.getCachedImage(id: chatID, category: .avatar) {
            imageCache[chatID] = diskImage
            cell.avatarImageView.image = diskImage
        } else {
            let urlString = "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(chatID)"
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            APIHelper.shared.fetchImage(urlString: urlString, cacheKey: chatID, category: .avatar) { [weak self] image in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if let image = image {
                        self?.imageCache[chatID] = image
                        cell.avatarImageView.image = image
                    }
                }
            }
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let mVC = self.storyboard?.instantiateViewController(withIdentifier: "MessagesVC") as? MessagesViewController else { return }
        let selectedChat = chats[indexPath.row]
        mVC.activeChat = selectedChat
        if let split = self.splitViewController, split.viewControllers.count > 1 {
            let nav = UINavigationController(rootViewController: mVC)
            split.viewControllers = [split.viewControllers[0], nav]
        } else {
            if let nav = self.navigationController {
                nav.pushViewController(mVC, animated: true)
            } else {
                self.present(mVC, animated: true, completion: nil)
            }
        }
    }
}
