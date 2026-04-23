//
//  AboutViewController.swift
//  ReflectoGram
//
//  Created by spytaspund tbf on 18.04.2026.
//

import Foundation
import UIKit

class AboutViewController: UITableViewController {
    var cachedChat: Chat?
    var fullChat: Chat?
    var serverURL: String = ""
    var sessionID: String = ""
    var cryptoKey: String = ""
    var userID: String = ""
    
    enum ProfileRow {
        case main(status: String, isPremium: Bool)
        case music(musicID: String, userID: String, title: String, artist: String)
        case channel(name: String, username: String?, channelID: Int64)
        case phone(String)
        case bio(String)
        case username(String)
        case member(name: String, status: String)
    }
    
    var tableSections: [[ProfileRow]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // need to fix it cuz it covers nav and tab bar
        /*if isiOS6() {
            self.tableView.backgroundView = nil
            self.tableView.backgroundColor = UIColor(patternImage: UIImage(named: "reflectogram-background") ?? UIImage())
        }*/
        let doneButton = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(dismissProfile))
        self.navigationItem.rightBarButtonItem = doneButton
        
        userID = cachedChat?.id ?? "me"
        self.tableView.register(ProfileMainCell.self, forCellReuseIdentifier: "MainCell")
        self.tableView.register(MusicProfileCell.self, forCellReuseIdentifier: "MusicCell")
        self.tableView.register(ChannelProfileCell.self, forCellReuseIdentifier: "ChannelCell")
        self.tableView.register(InfoDetailCell.self, forCellReuseIdentifier: "InfoCell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StandardCell")
    }
    
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
            loadProfileData()
        }
    }
    
    @objc func dismissProfile() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func buildTableData() {
        tableSections.removeAll()
        let chat = fullChat ?? cachedChat
        
        let mainStatus = formatStatus(chat?.seenOnline)
        tableSections.append([.main(status: mainStatus, isPremium: chat?.isPremium ?? false)])
        
        var mediaSection: [ProfileRow] = []
        if let channel = chat?.profileChannel {
            mediaSection.append(.channel(name: channel.title, username: channel.username, channelID: channel.id))
        }
        if let music = chat?.profileMusic, !music.isEmpty {
            for track in music {
                mediaSection.append(.music(musicID: track.id, userID: self.userID, title: track.title, artist: track.performer))
            }
        }
        if !mediaSection.isEmpty {
            tableSections.append(mediaSection)
        }
        
        var infoSection: [ProfileRow] = []
        if let phone = chat?.phone, !phone.isEmpty {
            infoSection.append(.phone(phone))
        }
        if let bio = chat?.bio, !bio.isEmpty {
            infoSection.append(.bio(bio))
        }
        if let username = chat?.username, !username.isEmpty {
            infoSection.append(.username(username))
        }
        if !infoSection.isEmpty {
            tableSections.append(infoSection)
        }
        
        var membersSection: [ProfileRow] = []
        if let members = chat?.members, !members.isEmpty {
            for member in members {
                let memberStatus = formatStatus(member.lastSeen)
                membersSection.append(.member(name: member.name, status: memberStatus))
            }
        }
        if !membersSection.isEmpty {
            tableSections.append(membersSection)
        }
    }
    
    func formatStatus(_ status: SeenOnline?) -> String {
        guard let status = status else { return "offline" }
        
        switch status.type {
        case 0: return "online"
        case 1: return "last seen recently"
        case 2: return "last seen within a week"
        case 3: return "last seen within a month"
        case 4:
            guard let timestamp = status.seenOnline, timestamp > 0 else { return "offline" }
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy 'at' HH:mm"
            return "last seen \(formatter.string(from: date))"
        default: return "offline"
        }
    }
    
    func loadProfileData() {
        let userID = cachedChat?.id ?? "me"
        
        if let cachedAbout = CacheHelper.shared.getCachedAbout(forUserID: userID) {
            self.fullChat = cachedAbout
            self.buildTableData()
            self.tableView.reloadData()
        }
        
        APIHelper.shared.fetchAbout(from: "\(serverURL)/about?session_id=\(sessionID)&user_id=\(userID)", key: cryptoKey) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chat):
                self.fullChat = chat
                CacheHelper.shared.saveAbout(chat, forUserID: userID)
                
                self.setTitle(name: self.fullChat?.name ?? "User")
                self.buildTableData()
                self.tableView.reloadData()
            case .failure(let error):
                print("Error loading profile: \(error)")
            }
        }
    }
    
    func setTitle(name: String){
        if let parentNC = self.tabBarController?.navigationController {
            parentNC.navigationBar.topItem?.title = name
        } else {
            self.tabBarController?.navigationItem.title = name
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < tableSections.count else { return nil }
        guard let firstItem = tableSections[section].first else { return nil }
        
        switch firstItem {
        case .main: return nil
        case .music, .channel: return "Media"
        case .phone, .bio, .username: return "Info"
        case .member: return "Members"
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSections[section].count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //if section == 0 { return 0.0 }
        if let title = self.tableView(tableView, titleForHeaderInSection: section), !title.isEmpty { return 29.0 }
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chat = fullChat ?? cachedChat
        let rowType = tableSections[indexPath.section][indexPath.row]
                
        switch rowType {
        case .main(let status, let isPremium):
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as! ProfileMainCell
            cell.nameLabel.text = isPremium ? "⭐️ \(chat?.name ?? "User")" : (chat?.name ?? "User")
            cell.statusLabel.text = status
            cell.statusLabel.textColor = (status == "online") ? .blue : .gray
            cell.setupButtons(titles: ["Chat", "Call", "Mute"])
            cell.avatarImageView.setAvatar(id: userID, url: "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(userID)")
            return cell
            
        case .music(let musicID, let userID, let title, let artist):
            let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell", for: indexPath) as! MusicProfileCell
            cell.coverImageView.setTrackCover(musicId: musicID, userId: userID, serverURL: self.serverURL, sessionID: self.sessionID)
            cell.titleLabel.text = title
            cell.artistAlbumLabel.text = artist
            return cell
            
        case .channel(let name, let username, let channelID):
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelProfileCell
            cell.nameLabel.text = name
            cell.subLabel.text = username ?? "channel"
            cell.lastMessageLabel.text = ""
            cell.avatarImageView.setAvatar(id: "\(channelID)", url: "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(userID)")
            return cell
            
        case .phone:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as! InfoDetailCell
            cell.titleLabel.text = "mobile"
            if let phone = chat?.phone { cell.detailLabel.text = "+\(phone)" }
            return cell
            
        case .bio:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as! InfoDetailCell
            cell.titleLabel.text = "bio"
            cell.detailLabel.text = chat?.bio
            return cell
            
        case .username:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as! InfoDetailCell
            cell.titleLabel.text = "username"
            cell.detailLabel.text = chat?.username
            return cell
            
        case .member(let name, let status):
            var cell = tableView.dequeueReusableCell(withIdentifier: "MemberSubtitleCell")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MemberSubtitleCell")
            }
            cell?.textLabel?.text = name
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 16)
            
            cell?.detailTextLabel?.text = status
            cell?.detailTextLabel?.textColor = (status == "online") ? .blue : .gray
            
            cell?.backgroundColor = isiOS6() ? .white : .clear
            return cell!
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = tableSections[indexPath.section][indexPath.row]
        
        switch rowType {
        case .main:
            // No buttons -  102 (need to check). Yes buttons — 150.
            return 150
            
        case .music, .channel:
            return 70
            
        case .phone, .username:
            return 60
            
        case .bio:
            let w = tableView.frame.width - 32
            let font = UIFont.systemFont(ofSize: 16)
            let textHeight = LayoutHelper.sizeForText(fullChat?.bio ?? "", font: font, maxWidth: w).height
            return textHeight + 32
            
        case .member:
            return 50
        }
    }
}
