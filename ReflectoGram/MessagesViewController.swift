//
//  MessagesViewController.swift
//  ReflectoGram
//

import Foundation
import UIKit

class MessagesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputContainerHeightConstraint: NSLayoutConstraint!
    var isSmallScreen: Bool { return UIScreen.main.bounds.height <= 480 }
    let minInputHeight: CGFloat = 48.0
    let maxInputHeight: CGFloat = 120.0
    var keyboardHeight: CGFloat = 0.0
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
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        
        messageTextView.delegate = self
        messageTextView.layer.cornerRadius = 6
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor.lightGray.cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.layer.cornerRadius = 6
        sendButton.titleLabel?.numberOfLines = 1
        sendButton.titleLabel?.lineBreakMode = .byClipping
        sendButton.titleLabel?.adjustsFontSizeToFitWidth = true
        sendButton.titleLabel?.minimumScaleFactor = 0.8
        
        if isiOS6() {
            let containerGradient = CAGradientLayer()
            containerGradient.name = "inputGradient"
            containerGradient.colors = [
                UIColor(white: 0.22, alpha: 1.0).cgColor,
                UIColor(white: 0.05, alpha: 1.0).cgColor
            ]
            let topBorder = CALayer()
            topBorder.backgroundColor = UIColor(white: 0.4, alpha: 0.8).cgColor
            topBorder.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 1.0)
            
            inputContainerView.layer.insertSublayer(containerGradient, at: 0)
            inputContainerView.layer.addSublayer(topBorder)
            
            let btnGradient = CAGradientLayer()
            btnGradient.name = "buttonGradient"
            btnGradient.colors = [
                UIColor(red: 0.45, green: 0.70, blue: 0.98, alpha: 1.0).cgColor,
                UIColor(red: 0.12, green: 0.45, blue: 0.88, alpha: 1.0).cgColor
            ]
            btnGradient.cornerRadius = 8
            sendButton.layer.insertSublayer(btnGradient, at: 0)
            sendButton.layer.borderColor = UIColor(red: 0.0, green: 0.2, blue: 0.5, alpha: 1.0).cgColor
            sendButton.layer.borderWidth = 1.0
        }
        
        self.title = "Chat"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layers = inputContainerView.layer.sublayers {
            for layer in layers where layer.name == "inputGradient" {
                layer.frame = inputContainerView.bounds
            }
        }

        if let btnLayers = sendButton.layer.sublayers {
            for layer in btnLayers where layer.name == "buttonGradient" {
                layer.frame = sendButton.bounds
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let defaults = UserDefaults.standard
        self.serverURL = defaults.string(forKey: "serverUrl") ?? ""
        self.sessionID = defaults.string(forKey: "sessionId") ?? ""
        self.cryptoKey = defaults.string(forKey: "aesKey") ?? ""

        if serverURL.isEmpty {
            return
        } else {
            setupTitleView(name: activeChat?.name ?? "Chat")
            loadMessages()
        }
    }

    func loadMessages() {
        guard let chatID = activeChat?.id else { return }
        if let cached = CacheHelper.shared.getCachedMessages(forChatID: "\(chatID)") {
            self.messages = Array(cached.reversed())
            self.tableView.reloadData()
            self.scrollToBottom()
        }

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = "\(self.serverURL)/messages?chat_id=\(chatID)&session_id=\(self.sessionID)"
        
        APIHelper.shared.fetchMessages(from: url, key: cryptoKey) { [weak self] result in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let self = self else { return }
                
                switch result {
                case .success(let loadedMessages):
                    CacheHelper.shared.saveMessages(loadedMessages, forChatID: "\(chatID)")
                    
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
        let text = message.text
        
        let screenWidth = tableView.frame.width
        let maxBubbleWidth = screenWidth * 0.75
        
        var totalHeight: CGFloat = 10
        var bubbleHeight: CGFloat = 0
        
        let nameHeight: CGFloat = (isIncoming && isGroup) ? 20 : 0
        let bottomPadding: CGFloat = 10

        switch message.type {
        case "photo":
            let photoRatio: CGFloat = 0.6
            let photoHeight = maxBubbleWidth * photoRatio
            
            if !text.isEmpty {
                let capFont = UIFont.systemFont(ofSize: 15)
                let capHeight = LayoutHelper.sizeForText(text, font: capFont, maxWidth: maxBubbleWidth - 20).height
                bubbleHeight = photoHeight + nameHeight + capHeight + 35
            } else {
                bubbleHeight = photoHeight + nameHeight + 8
            }
            
        case "sticker":
            bubbleHeight = 160
            
        case "audio", "file":
            let baseHeight: CGFloat = 45 + 16
            if !text.isEmpty {
                let capFont = UIFont.systemFont(ofSize: 15)
                let capHeight = LayoutHelper.sizeForText(text, font: capFont, maxWidth: maxBubbleWidth - 20).height
                bubbleHeight = baseHeight + nameHeight + capHeight + 20
            } else {
                bubbleHeight = baseHeight + nameHeight + 10
            }
        default: // text
            let textMaxWidth = maxBubbleWidth - 20 - 45
            let font = UIFont.systemFont(ofSize: 15)
            let textSize = LayoutHelper.sizeForText(text, font: font, maxWidth: textMaxWidth)
            
            bubbleHeight = max(textSize.height + nameHeight + 20, nameHeight + 35)
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
        case "photo":   identifier = "ImageMessageCell"
        case "sticker": identifier = "StickerMessageCell"
        case "file":    identifier = "FileMessageCell"
        case "audio":   identifier = "AudioMessageCell"
        default:        identifier = "TextMessageCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! BubbleCell
        cell.delegate = self
        cell.isIncoming = !message.isOutgoing
        cell.isGroup = isGroup
        cell.setupBaseUI()

        cell.senderNameLabel.text = message.sender
        cell.timeLabel.text = DateHelper.shared.formatDateMessage(message.date)
        
        if !message.isOutgoing && isGroup {
            let avatarUrl = "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(message.senderId)&size=35"
            cell.avatarImageView.setRemoteImage(url: avatarUrl, cacheKey: "avatar_\(message.senderId)", placeholder: "reflectogram-person")
        }

        switch message.type {
        case "photo":
            if let imgCell = cell as? ImageMessageCell {
                let url = "\(serverURL)/get_media?session_id=\(sessionID)&chat_id=\(activeChat?.id ?? 0)&message_id=\(message.id)&token=\(message.mediaToken ?? "")&thumb"
                imgCell.photoView.setRemoteImage(url: url, cacheKey: "thumb_\(message.id)", placeholder: "placeholder")
                imgCell.captionLabel.text = message.text
            }
        case "sticker":
            if let stickCell = cell as? StickerMessageCell {
                let url = "\(serverURL)/get_media?session_id=\(sessionID)&chat_id=\(activeChat?.id ?? 0)&message_id=\(message.id)&token=\(message.mediaToken ?? "")"
                stickCell.stickerImageView.setRemoteImage(url: url, cacheKey: "sticker_\(message.id)", placeholder: "placeholder")
            }
        case "file":
            if let fileCell = cell as? FileMessageCell {
                let url = "\(serverURL)/get_media?session_id=\(sessionID)&chat_id=\(activeChat?.id ?? 0)&message_id=\(message.id)&token=\(message.mediaToken ?? "")&thumb"
                fileCell.fileIconView.setRemoteImage(url: url, cacheKey: "thumb_\(message.id)", placeholder: "placeholder")
                fileCell.fileNameLabel.text = message.mediaInfo?.title ?? "Document"
                fileCell.fileMetaLabel.text = ".something"
            }
        case "audio":
            if let audioCell = cell as? AudioMessageCell {
                let url = "\(serverURL)/get_media?session_id=\(sessionID)&chat_id=\(activeChat?.id ?? 0)&message_id=\(message.id)&token=\(message.mediaToken ?? "")&thumb"
                audioCell.coverImageView.setRemoteImage(url: url, cacheKey: "thumb_\(message.id)", placeholder: "placeholder")
                audioCell.captionLabel.text = message.text
                audioCell.titleLabel.text = message.mediaInfo?.title ?? "Untitled"
                audioCell.performerLabel.text = message.mediaInfo?.performer ?? "Unknown"
                if let durationInt = message.mediaInfo?.duration {
                    audioCell.durationLabel.text = DateHelper.shared.formatDuration(durationInt)
                } else {
                    audioCell.durationLabel.text = "0:00"
                }
            }
        default:
            if let textCell = cell as? TextMessageCell {
                textCell.messageLabel.text = message.text
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        if let cell = tableView.cellForRow(at: indexPath) as? BubbleCell {
            if message.type != "text" {
                self.didTapMedia(in: cell, message: message)
            }
        }
    }
    
    func didTapMedia(in cell: BubbleCell, message: Message) {
        guard let token = message.mediaToken, let chatID = activeChat?.id else { return }
        if let previewVC = self.storyboard?.instantiateViewController(withIdentifier: "MediaPreviewVC") as? MediaPreviewController {
            previewVC.mediaID = "\(message.id)"
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
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        let keyboardFrame = frameValue.cgRectValue
        let convertedFrame = view.convert(keyboardFrame, from: nil)
        let height = view.bounds.height - convertedFrame.origin.y
        
        self.keyboardHeight = height
        inputContainerBottomConstraint.constant = height
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.scrollToBottom()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        inputContainerBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func updateInputHeight() {
        let fixedWidth = messageTextView.frame.size.width
        var newHeight: CGFloat = minInputHeight
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        if isiOS6() {
            newHeight = messageTextView.contentSize.height
            if isPad { newHeight += 16 }
        } else {
            let newSize = messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: 9999.0))
            newHeight = ceil(newSize.height) + (isPad ? 20 : 16)
        }
        
        if newHeight < minInputHeight { newHeight = minInputHeight }
        let actualMaxHeight = isPad ? maxInputHeight * 1.5 : maxInputHeight
        
        if newHeight > actualMaxHeight {
            newHeight = actualMaxHeight
            messageTextView.isScrollEnabled = true
        } else {
            messageTextView.isScrollEnabled = false
        }
        
        if inputContainerHeightConstraint.constant != newHeight {
            inputContainerHeightConstraint.constant = newHeight
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
                self.scrollToBottom()
            }
        }
    }
    
    @objc func sendButtonTapped() {
        guard let text = messageTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let chatID = activeChat?.id else { return }
        
        let messageText = text
        messageTextView.text = ""
        updateInputHeight()
        sendButton.isEnabled = false
        
        APIHelper.shared.sendMessage(text: messageText, chatID: "\(chatID)", sessionID: sessionID, serverURL: serverURL, keyHex: cryptoKey) { [weak self] success in
            guard let self = self else { return }
            self.sendButton.isEnabled = true
            self.loadMessages()
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
       avatar.setRemoteImage(url: "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(activeChat?.id ?? 0)&size=70", cacheKey: "avatar_\(activeChat?.id ?? 0)", placeholder: "reflectogram-group")
       titleView.addSubview(avatar)
       titleView.addSubview(label)
       titleView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
       self.navigationItem.titleView = titleView
   }
}

extension MessagesViewController: BubbleCellDelegate {
    func didTapAvatar(in cell: BubbleCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let message = messages[indexPath.row]
        let tempChat = Chat(id: message.senderId, name: message.sender)
        if let previewVC = self.storyboard?.instantiateViewController(withIdentifier: "AboutViewController") as? AboutViewController {
            previewVC.cachedChat = tempChat
            let nav = UINavigationController(rootViewController: previewVC)
            nav.modalPresentationStyle = .formSheet
            self.present(nav, animated: true, completion: nil)
        }
    }
}

extension MessagesViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateInputHeight()
    }
}
