//
//  AboutViewController.swift
//  ReflectoGram
//
//  Created by spytaspund tbf on 18.04.2026.
//

import Foundation
import UIKit

@objc(MainCell)
class MainCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var avatarImageView: UIImageView?
}

@objc(AboutViewController)
class AboutViewController: UITableViewController {
    var cachedChat: Chat?
    var fullChat: Chat?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BioCell")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chat = fullChat ?? cachedChat

        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as? MainCell {
                cell.titleLabel?.text = chat?.name
                return cell
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "BioCell", for: indexPath)
        cell.textLabel?.text = chat?.bio ?? "No info"
        return cell
    }
}
