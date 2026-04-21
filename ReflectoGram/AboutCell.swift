//
//  AboutCell.swift
//  ReflectoGram
//
//  Created by spytaspund tbf on 21.04.2026.
//

import Foundation
import UIKit
import QuartzCore

class ProfileMainCell: UITableViewCell {
    let legacyUI = isiOS6()
    
    var avatarImageView = UIImageView()
    var nameLabel = UILabel()
    var statusLabel = UILabel()
    var buttonsContainer = UIView()
    var actionButtons: [UIButton] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func setupUI() {
        self.backgroundColor = legacyUI ? .white : .clear
        self.selectionStyle = .none
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        contentView.addSubview(avatarImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarImageView.addGestureRecognizer(tapGesture)
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        contentView.addSubview(nameLabel)
        
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .gray
        contentView.addSubview(statusLabel)
        
        contentView.addSubview(buttonsContainer)
    }
    
    func setupButtons(titles: [String]) {
        buttonsContainer.subviews.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        
        for title in titles {
            let btn = UIButton(type: .custom)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            
            if legacyUI {
                btn.setTitleColor(.white, for: .normal)
                btn.setTitleColor(.lightGray, for: .highlighted)
                
                let gradient = CAGradientLayer()
                gradient.frame = CGRect(x: 0, y: 0, width: 70, height: 32)
                gradient.colors = [
                    UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1).cgColor,
                    UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1).cgColor
                ]
                gradient.cornerRadius = 4
                gradient.borderWidth = 0.5
                gradient.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
                btn.layer.insertSublayer(gradient, at: 0)
                btn.clipsToBounds = true
            } else {
                btn.setTitleColor(.systemBlue, for: .normal)
            }
            
            buttonsContainer.addSubview(btn)
            actionButtons.append(btn)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = contentView.frame.width
        
        avatarImageView.frame = CGRect(x: 16, y: 16, width: 70, height: 70)
        avatarImageView.layer.cornerRadius = legacyUI ? 10 : 35
        
        let textX = avatarImageView.frame.maxX + 16
        nameLabel.frame = CGRect(x: textX, y: 28, width: w - textX - 16, height: 24)
        statusLabel.frame = CGRect(x: textX, y: nameLabel.frame.maxY + 2, width: w - textX - 16, height: 18)
        buttonsContainer.frame = CGRect(x: 16, y: avatarImageView.frame.maxY + 16, width: w - 32, height: 32)
        
        let spacing: CGFloat = 8
        let btnW = (buttonsContainer.frame.width - (spacing * CGFloat(actionButtons.count - 1))) / CGFloat(actionButtons.count)
        
        for (i, btn) in actionButtons.enumerated() {
            btn.frame = CGRect(x: CGFloat(i) * (btnW + spacing), y: 0, width: btnW, height: 32)
            if let grad = btn.layer.sublayers?.first as? CAGradientLayer {
                grad.frame = btn.bounds
            }
        }
    }

    @objc func avatarTapped() {
        let spin = CAKeyframeAnimation(keyPath: "transform.rotation.y")
        spin.values = [0, Double.pi * 2, Double.pi * 4, Double.pi * 6]
        spin.keyTimes = [0, 0.3, 0.7, 1.0]
        spin.timingFunctions = [CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)]
        spin.duration = 1.2
        avatarImageView.layer.add(spin, forKey: "spin")
    }
}

class MusicProfileCell: UITableViewCell {
    let legacyUI = isiOS6()
    
    var coverImageView = UIImageView()
    var titleLabel = UILabel()
    var artistAlbumLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator
        
        coverImageView.backgroundColor = .lightGray
        coverImageView.layer.cornerRadius = 6
        coverImageView.clipsToBounds = true
        contentView.addSubview(coverImageView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        
        artistAlbumLabel.font = UIFont.systemFont(ofSize: 13)
        artistAlbumLabel.textColor = .gray
        artistAlbumLabel.backgroundColor = .clear
        contentView.addSubview(artistAlbumLabel)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let coverSize: CGFloat = 50
        let padding: CGFloat = 10
        
        coverImageView.frame = CGRect(x: 16, y: padding, width: coverSize, height: coverSize)
        
        let textX = coverImageView.frame.maxX + 12
        let textW = contentView.frame.width - textX - 8
        
        titleLabel.frame = CGRect(x: textX, y: 14, width: textW, height: 20)
        artistAlbumLabel.frame = CGRect(x: textX, y: titleLabel.frame.maxY + 2, width: textW, height: 16)
    }
}

class ChannelProfileCell: UITableViewCell {
    var avatarImageView = UIImageView()
    var nameLabel = UILabel()
    var subLabel = UILabel()
    var lastMessageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.backgroundColor = .clear
        contentView.addSubview(nameLabel)
        
        subLabel.font = UIFont.systemFont(ofSize: 12)
        subLabel.textColor = .gray
        subLabel.backgroundColor = .clear
        contentView.addSubview(subLabel)
        
        lastMessageLabel.font = UIFont.systemFont(ofSize: 13)
        lastMessageLabel.textColor = .darkGray
        lastMessageLabel.backgroundColor = .clear
        contentView.addSubview(lastMessageLabel)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let avatarSize: CGFloat = 50
        avatarImageView.frame = CGRect(x: 16, y: 10, width: avatarSize, height: avatarSize)
        avatarImageView.layer.cornerRadius = isiOS6() ? 6 : 25
        
        let textX = avatarImageView.frame.maxX + 12
        let textW = contentView.frame.width - textX - 10
        
        subLabel.frame = CGRect(x: textX, y: 10, width: textW, height: 14)
        nameLabel.frame = CGRect(x: textX, y: subLabel.frame.maxY, width: textW, height: 18)
        lastMessageLabel.frame = CGRect(x: textX, y: nameLabel.frame.maxY + 2, width: textW, height: 16)
    }
}

class InfoDetailCell: UITableViewCell {
    var titleLabel = UILabel()
    var detailLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = isiOS6() ? UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1) : .systemBlue
        titleLabel.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        
        detailLabel.font = UIFont.systemFont(ofSize: 16)
        detailLabel.numberOfLines = 0
        detailLabel.backgroundColor = .clear
        contentView.addSubview(detailLabel)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = contentView.frame.width
        
        titleLabel.frame = CGRect(x: 16, y: 8, width: w - 32, height: 16)
        let detailY = titleLabel.frame.maxY + 4
        detailLabel.frame = CGRect(x: 16, y: detailY, width: w - 32, height: contentView.frame.height - detailY - 8)
    }
}
