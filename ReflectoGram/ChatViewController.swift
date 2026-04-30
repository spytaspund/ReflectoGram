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
    var serverURL = ""
    var sessionID = ""
    var cryptoKey = ""
    
    var isLoading = false
    var canLoadMore = true
    let limit = 20
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let navBar = self.navigationController?.navigationBar {
            navBar.topItem?.title = "ReflectoGram"
        }
        
        let defaults = UserDefaults.standard
        guard let savedUrl = defaults.string(forKey: "serverUrl"),
              let savedId = defaults.string(forKey: "sessionId"),
              let savedKey = defaults.string(forKey: "aesKey") else {
            
            if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") {
                loginVC.modalPresentationStyle = .formSheet
                self.present(loginVC, animated: true, completion: nil)
            }
            return
        }
        
        self.serverURL = savedUrl
        self.sessionID = savedId
        self.cryptoKey = savedKey
        
        if chats.isEmpty {
            loadDataFromServer()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshChats), for: .valueChanged)
        self.tableView.addSubview(refreshControl)
        
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
    
    func loadDataFromServer(offsetDate: String? = nil) {
        guard !isLoading && canLoadMore else { return }
        isLoading = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        var urlString = "\(serverURL)/chats?session_id=\(sessionID)&limit=\(limit)"
        
        if let offset = offsetDate, !offset.isEmpty {
            if let encodedDate = (offset as NSString).addingPercentEscapes(using: String.Encoding.utf8.rawValue) {
                urlString += "&offsetDate=\(encodedDate)"
            }
        }
        
        APIHelper.shared.fetchChats(from: urlString, key: cryptoKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                switch result {
                case .success(let loadedChats):
                    if loadedChats.isEmpty {
                        self?.canLoadMore = false
                    }
                    else {
                        if offsetDate == nil {
                            self?.chats = loadedChats
                            CacheHelper.shared.saveChats(loadedChats)
                        }
                        else {
                            self?.chats.append(contentsOf: loadedChats)
                        }
                        self?.tableView.reloadData()
                        if loadedChats.count < self?.limit ?? 15 {
                            self?.canLoadMore = false
                        }
                    }
                case .failure(let error):
                    UIAlertView(title: "API Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell
        let chat = chats[indexPath.row]
        
        let formattedDate = DateHelper.shared.formatDate(chat.date ?? "2026-04-30T12:34:30+00:00")
            
        cell.titleLabel.text = chat.name
        cell.messageLabel.text = chat.lastMessage?.text ?? "No messages"
        cell.timeLabel.text = formattedDate
        
        let placeholder = (chat.type == "user") ? "reflectogram-person" : "reflectogram-group"
        let avatarUrl = "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(chat.id)&size=50"
        
        cell.avatarImageView.setRemoteImage(
            url: avatarUrl,
            cacheKey: "avatar_\(chat.id)",
            placeholder: placeholder
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= chats.count - 1 && !isLoading && canLoadMore {
            let lastChatDate = chats.last?.date
            loadDataFromServer(offsetDate: lastChatDate)
        }
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
    
    @objc func refreshChats(sender: UIRefreshControl) {
        canLoadMore = true
        loadDataFromServer(offsetDate: nil)
        sender.endRefreshing()
    }
}
