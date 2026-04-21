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
        case main
        case music(title: String, artist: String)
        case channel(name: String, subs: Int)
        case phone(String)
        case bio(String)
        case username(String)
        case member(String)
    }
    
    var tableSections: [[ProfileRow]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // need to fix it cuz it covers nav and tab bar
        /*if isiOS6() {
            self.tableView.backgroundView = nil
            self.tableView.backgroundColor = UIColor(patternImage: UIImage(named: "reflectogram-background") ?? UIImage())
        }*/
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
    
    func buildTableData() {
        tableSections.removeAll()
        let chat = fullChat ?? cachedChat
        tableSections.append([.main])
        var mediaSection: [ProfileRow] = []
        mediaSection.append(.music(title: "Curse of the crystal skull", artist: "Dr. Steel"))
        mediaSection.append(.channel(name: "Private channel", subs: 10000))
        tableSections.append(mediaSection)
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
    }
    
    func loadProfileData() {
        let userID = cachedChat?.id ?? "me"
        APIHelper.shared.fetchAbout(from: "\(serverURL)/about?session_id=\(sessionID)&user_id=\(userID)", key: cryptoKey) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let chat):
                self.fullChat = chat
                self.setTitle(name: self.fullChat?.name ?? "User")
                self.buildTableData()
                self.tableView.reloadData()

            case .failure(let error):
                print("Error loading profile: \(error)")
                let alert = UIAlertView(title: "API Error", message: "Failed to load profile", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
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
        if section == 0 { return nil }
        if section == 1 { return "Media" }
        if section == 2 { return "Info" }
        if section == 3 { return "Members" }
        return nil
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
        case .main:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as! ProfileMainCell
            cell.nameLabel.text = chat?.name ?? "User"
            cell.statusLabel.text = "online"
            cell.setupButtons(titles: ["Chat", "Call", "Mute"])
            cell.avatarImageView.setAvatar(id: userID, url: "\(serverURL)/avatar?session_id=\(sessionID)&user_id=\(userID)")
            return cell
            
        case .music:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell", for: indexPath) as! MusicProfileCell
            cell.coverImageView.image = UIImage(named: "placeholder")
            cell.titleLabel.text = "Curse of the crystal skull"
            cell.artistAlbumLabel.text = "Dr. Steel"
            return cell
            
        case .channel:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelProfileCell
            cell.nameLabel.text = "Private channel"
            cell.subLabel.text = "10K subscribers"
            cell.lastMessageLabel.text = "Latest post about iOS development"
            cell.avatarImageView.image = UIImage(named: "reflectogram-group")
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
            
        case .member(let name):
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCell", for: indexPath)
            cell.textLabel?.text = name
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell.backgroundColor = isiOS6() ? .white : .clear
            return cell
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
