//
//  MessagesViewController.swift
//  ReflectoGram
//

import Foundation
import UIKit

class MessagesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var messages: [Message] = []
    var activeChat: Chat?
    var serverURL = ""
    var sessionID = ""
    var cryptoKey = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: "TextMessageCell")
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: "ImageMessageCell")
        tableView.register(StickerMessageCell.self, forCellReuseIdentifier: "StickerMessageCell")
        tableView.register(FileMessageCell.self, forCellReuseIdentifier: "FileMessageCell")
        tableView.register(AudioMessageCell.self, forCellReuseIdentifier: "AudioMessageCell")
        
        let bgImageView = UIImageView(image: UIImage(named: "reflectogram-background"))
        bgImageView.contentMode = .scaleAspectFill
        tableView.backgroundView = bgImageView
        tableView.backgroundColor = .clear
        
        self.title = "Chat"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let defaults = UserDefaults.standard
        self.serverURL = defaults.string(forKey: "serverUrl") ?? ""
        self.sessionID = defaults.string(forKey: "sessionId") ?? ""
        self.cryptoKey = defaults.string(forKey: "aesKey") ?? ""

        if serverURL.isEmpty {
            if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") {
                self.present(loginVC, animated: true, completion: nil)
            }
        } else {
            setupTitleView(name: activeChat?.name ?? "Chat")
            loadMessages()
        }
    }

    func loadMessages() {
        guard let chatID = activeChat?.id else { return }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let url = "\(self.serverURL)/messages?chat_id=\(chatID)&session_id=\(self.sessionID)"
        APIHelper.shared.fetchMessages(from: url, key: cryptoKey) { [weak self] result in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let self = self else { return }
                
                switch result {
                case .success(let loadedMessages):
                    self.messages = Array(loadedMessages.reversed())
                    if let tv = self.tableView { tv.reloadData() }
                    self.scrollToBottom()
                case .failure(let error):
                    print("Fetch error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func scrollToBottom() {
        if !messages.isEmpty {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            if let tv = self.tableView { tv.scrollToRow(at: indexPath, at: .bottom, animated: false) }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.row]
        let isGroup = !(activeChat?.type == "user" || activeChat?.type == "channel")
        let isIncoming = !message.isOutgoing
        let text = message.text ?? ""
        
        let screenWidth = tableView.frame.width
        let maxBubbleWidth = screenWidth * 0.75
        
        var totalHeight: CGFloat = 10
        var bubbleHeight: CGFloat = 0
        
        let nameHeight: CGFloat = (isIncoming && isGroup) ? 20 : 0
        let bottomPadding: CGFloat = 10

        switch message.type {
        case .text:
            let textMaxWidth = maxBubbleWidth - 20 - 45
            let font = UIFont.systemFont(ofSize: 15)
            let textSize = LayoutHelper.sizeForText(text, font: font, maxWidth: textMaxWidth)
            
            bubbleHeight = max(textSize.height + nameHeight + 20, nameHeight + 35)
            
        case .image:
            let photoRatio: CGFloat = 0.6
            let photoHeight = maxBubbleWidth * photoRatio
            
            if !text.isEmpty {
                let capFont = UIFont.systemFont(ofSize: 15)
                let capHeight = LayoutHelper.sizeForText(text, font: capFont, maxWidth: maxBubbleWidth - 20).height
                bubbleHeight = photoHeight + nameHeight + capHeight + 35
            } else {
                bubbleHeight = photoHeight + nameHeight + 8
            }
            
        case .sticker:
            bubbleHeight = 160
            
        case .audio, .file:
            let baseHeight: CGFloat = 45 + 16
            if !text.isEmpty {
                let capFont = UIFont.systemFont(ofSize: 15)
                let capHeight = LayoutHelper.sizeForText(text, font: capFont, maxWidth: maxBubbleWidth - 20).height
                bubbleHeight = baseHeight + nameHeight + capHeight + 20
            } else {
                bubbleHeight = baseHeight + nameHeight + 10
            }
        }
        
        if isIncoming && isGroup {
            bubbleHeight = max(bubbleHeight, 40)
        }

        totalHeight += bubbleHeight + bottomPadding
        
        return totalHeight
    }
 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let isGroup = !(activeChat?.type == "user" || activeChat?.type == "channel")
        
        let identifier: String
        switch message.type {
        case .text:    identifier = "TextMessageCell"
        case .image:   identifier = "ImageMessageCell"
        case .sticker: identifier = "StickerMessageCell"
        case .file:    identifier = "FileMessageCell"
        case .audio:   identifier = "AudioMessageCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! BubbleCell
        
        cell.isIncoming = !message.isOutgoing
        cell.isGroup = isGroup
        cell.setupBaseUI()

        cell.senderNameLabel.text = message.sender
        cell.timeLabel.text = DateHelper.shared.formatDateMessage(message.date ?? "")
        
        if !message.isOutgoing && isGroup {
            cell.avatarImageView.setAvatar(id: message.senderID, url: "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(message.senderID)")
        }

        switch message.type {
        case .text:
            if let textCell = cell as? TextMessageCell {
                textCell.messageLabel.text = message.text
            }
        case .image:
            if let imgCell = cell as? ImageMessageCell {
                let url = "\(serverURL)/get_media?session_id=\(sessionID)&chat_id=\(activeChat?.id ?? "")&message_id=\(message.id)&token=\(message.mediaToken ?? "")&thumb"
                imgCell.photoView.setMessagePhoto(messageId: message.id, url: url)
                imgCell.captionLabel.text = message.text
            }
        case .sticker:
            if let stickCell = cell as? StickerMessageCell {
                let url = "\(serverURL)/get_media?session_id=\(sessionID)&chat_id=\(activeChat?.id ?? "")&message_id=\(message.id)&token=\(message.mediaToken ?? "")"
                stickCell.stickerImageView.setMessagePhoto(messageId: message.id, url: url)
            }
        case .file:
            if let fileCell = cell as? FileMessageCell {
                fileCell.fileIconView.image = UIImage(named: "document")
                fileCell.fileNameLabel.text = message.mediaInfo?.title ?? "Document"
                fileCell.fileMetaLabel.text = ".md"
            }
        case .audio:
            if let audioCell = cell as? AudioMessageCell {
                audioCell.captionLabel.text = message.text ?? ""
                audioCell.titleLabel.text = message.mediaInfo?.title ?? "Untitled"
                audioCell.performerLabel.text = message.mediaInfo?.performer ?? "Unknown"
                audioCell.durationLabel.text = "10:09"
                audioCell.coverImageView.image = UIImage(named: "audio")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        if let cell = tableView.cellForRow(at: indexPath) as? BubbleCell {
            if message.type != .text {
                self.didTapMedia(in: cell, message: message)
            }
        }
    }
    
    func didTapMedia(in cell: BubbleCell, message: Message) {
        guard let token = message.mediaToken, let chatID = activeChat?.id else { return }
        if let previewVC = self.storyboard?.instantiateViewController(withIdentifier: "MediaPreviewVC") as? MediaPreviewController {
            previewVC.mediaID = message.id
            let urlString = "\(serverURL)/get_media?session_id=\(sessionID)&token=\(token)&message_id=\(message.id)&chat_id=\(chatID)"
            
            previewVC.mediaURL = urlString
            previewVC.modalPresentationStyle = .fullScreen
            self.present(previewVC, animated: true, completion: nil)
        }
    }
    
    @objc func showAboutScreen() {
        if let aboutVC = self.storyboard?.instantiateViewController(withIdentifier: "AboutViewController") as? AboutViewController {
            aboutVC.cachedChat = self.activeChat
            let nav = UINavigationController(rootViewController: aboutVC)
            nav.modalPresentationStyle = .formSheet
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func setupTitleView(name: String) {
       let avatarSize: CGFloat = 30
       let spacing: CGFloat = 8
       let label = UILabel()
       label.text = name
       label.backgroundColor = .clear
       let version = UIDevice.current.systemVersion
       if version.hasPrefix("6") {
           label.textColor = UIColor(red: 0.24, green: 0.30, blue: 0.39, alpha: 1.0)
           label.font = UIFont.boldSystemFont(ofSize: 18)
           label.shadowColor = UIColor.white.withAlphaComponent(0.6)
           label.shadowOffset = CGSize(width: 0, height: 1)
       } else {
           label.font = UIFont.boldSystemFont(ofSize: 17)
           if #available(iOS 13.0, *) {
               label.textColor = .label
           } else {
               label.textColor = .black
           }
       }
       label.sizeToFit()
       let screenWidth = UIScreen.main.bounds.width
       let maxLabelWidth = screenWidth - 140
       let actualLabelWidth = min(label.frame.size.width, maxLabelWidth)
       label.frame = CGRect(x: avatarSize + spacing, y: 0, width: actualLabelWidth, height: 44)
       let totalWidth = avatarSize + spacing + actualLabelWidth
       let titleView = UIView(frame: CGRect(x: 0, y: 0, width: totalWidth, height: 44))
       let tap = UITapGestureRecognizer(target: self, action: #selector(showAboutScreen))
       titleView.backgroundColor = .clear
       titleView.isUserInteractionEnabled = true
       titleView.addGestureRecognizer(tap)
       let avatar = UIImageView(frame: CGRect(x: 0, y: 7, width: avatarSize, height: avatarSize))
       avatar.backgroundColor = .lightGray
       avatar.layer.cornerRadius = 15
       avatar.clipsToBounds = true
       avatar.isUserInteractionEnabled = false
       label.isUserInteractionEnabled = false
       //titleView.backgroundColor = UIColor.red.withAlphaComponent(0.1) // debug, pls remove later
       if let chatID = activeChat?.id {
           if let diskImage = CacheHelper.shared.getCachedImage(id: chatID, category: .avatar) {
               avatar.image = diskImage
           }
           else {
               avatar.image = UIImage(named: "reflectogram-group")
           }
       }
       
       titleView.addSubview(avatar)
       titleView.addSubview(label)
       titleView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
       self.navigationItem.titleView = titleView
   }
}
