//
//  AboutCell.swift
//  ReflectoGram
//
//  Created by spytaspund tbf on 21.04.2026.
//

import Foundation
import UIKit
import QuartzCore

protocol ProfileMainCellDelegate: AnyObject {
    func didTapChatButton()
}

class ProfileMainCell: UITableViewCell {
    let legacyUI = isiOS6()
    weak var delegate: ProfileMainCellDelegate?
    var avatarImageView = UIImageView()
    var nameLabel = UILabel()
    var statusLabel = UILabel()
    var premiumImageView = UIImageView()
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
        nameLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(nameLabel)
        
        premiumImageView.contentMode = .scaleAspectFit
        premiumImageView.isHidden = true
        contentView.addSubview(premiumImageView)
        
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .gray
        contentView.addSubview(statusLabel)
        
        contentView.addSubview(buttonsContainer)
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?
            CGSize(width: size.width * heightRatio, height: size.height * heightRatio) :
            CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }

    func setupButtons(for type: String) {
        buttonsContainer.subviews.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        let buttonConfig: [(String, String)]
        
        switch type {
        case "channel":
            buttonConfig = [("Mute", "mute"), ("Discuss", "message"), ("Link", "paperplane")]
        case "group":
            buttonConfig = [("Chat", "message"), ("Mute", "mute"), ("Video", "phone")]
        default:
            buttonConfig = [("Chat", "message"), ("Call", "phone"), ("Mute", "mute")]
        }
        
        for config in buttonConfig {
            let btn = UIButton(type: .custom)
            btn.setTitle(config.0, for: .normal)
            btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.minimumScaleFactor = 0.8
            btn.contentHorizontalAlignment = .center
            
            if let icon = UIImage(named: config.1) {
                let scaledIcon = resizeImage(image: icon, targetSize: CGSize(width: 16, height: 16))
                btn.setImage(scaledIcon, for: .normal)
                btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            }
            btn.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
            btn.setTitleColor(.white, for: .normal)
            btn.tintColor = .white
            btn.layer.cornerRadius = 8
            btn.clipsToBounds = true
            
            if config.0 == "Chat" || config.0 == "Discuss" {
                btn.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)
            }
            
            buttonsContainer.addSubview(btn)
            actionButtons.append(btn)
        }
    }
    
    func setPremium(_ isPremium: Bool) {
        premiumImageView.isHidden = !isPremium
        if isPremium && premiumImageView.image == nil {
            premiumImageView.image = UIImage(named: "premium")
        }
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = contentView.frame.width
        
        avatarImageView.frame = CGRect(x: 16, y: 16, width: 70, height: 70)
        avatarImageView.layer.cornerRadius = legacyUI ? 10 : 35
        
        let textX = avatarImageView.frame.maxX + 16
        
        nameLabel.sizeToFit()
        let premiumSpace: CGFloat = premiumImageView.isHidden ? 0 : 24
        let maxNameWidth = w - textX - 16 - premiumSpace
        let actualNameWidth = min(nameLabel.frame.width, maxNameWidth)
        
        nameLabel.frame = CGRect(x: textX, y: 28, width: actualNameWidth, height: 24)
        
        if !premiumImageView.isHidden {
            premiumImageView.frame = CGRect(x: nameLabel.frame.maxX + 4, y: 30, width: 20, height: 20)
        }
        
        statusLabel.frame = CGRect(x: textX, y: nameLabel.frame.maxY + 2, width: w - textX - 16, height: 18)
        buttonsContainer.frame = CGRect(x: 16, y: avatarImageView.frame.maxY + 16, width: w - 32, height: 32)
        
        if !actionButtons.isEmpty {
            let spacing: CGFloat = 8
            let btnW = (buttonsContainer.frame.width - (spacing * CGFloat(actionButtons.count - 1))) / CGFloat(actionButtons.count)
            
            for (i, btn) in actionButtons.enumerated() {
                btn.frame = CGRect(x: CGFloat(i) * (btnW + spacing), y: 0, width: btnW, height: 32)
                if let grad = btn.layer.sublayers?.first as? CAGradientLayer {
                    grad.frame = btn.bounds
                }
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
    
    @objc func chatTapped() {
        delegate?.didTapChatButton()
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
