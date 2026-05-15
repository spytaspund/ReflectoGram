//
//  ChatCell.swift
//  ReflectoGram
//
//  Created by spytaspund on 07.02.2026.
//
import UIKit

class ChatCell: UITableViewCell {
    
    let avatarImageView = UIImageView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let timeLabel = UILabel()
    let mediaIconView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        avatarImageView.backgroundColor = .lightGray
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        contentView.addSubview(avatarImageView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = .black
        contentView.addSubview(titleLabel)
        
        timeLabel.font = UIFont.systemFont(ofSize: 13)
        timeLabel.textColor = .darkGray
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)
        
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .gray
        messageLabel.numberOfLines = 2
        contentView.addSubview(messageLabel)
        
        mediaIconView.contentMode = .scaleAspectFit
        mediaIconView.isHidden = true
        mediaIconView.layer.cornerRadius = 8
        contentView.addSubview(mediaIconView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = contentView.frame.width
        let height = contentView.frame.height
        
        let isSmallScreen = width <= 320
        let sidePadding: CGFloat = isSmallScreen ? 10 : 20
        let avatarSize: CGFloat = 50
        let topPadding: CGFloat = 10
        
        avatarImageView.frame = CGRect(x: sidePadding, y: (height - avatarSize) / 2, width: avatarSize, height: avatarSize)
        
        let titleStartX = avatarImageView.frame.maxX + 12
        let timeWidth: CGFloat = 70
        timeLabel.frame = CGRect(x: width - timeWidth - sidePadding, y: topPadding + 2, width: timeWidth, height: 20)
        
        let titleWidth = width - titleStartX - timeWidth - sidePadding - 5
        
        let msgText = messageLabel.text ?? ""
        let hasMessage = !msgText.isEmpty
        
        if !hasMessage {
            titleLabel.frame = CGRect(x: titleStartX, y: (height - 22) / 2, width: titleWidth, height: 22)
            messageLabel.isHidden = true
            mediaIconView.isHidden = true
        } else {
            messageLabel.isHidden = false
            let textBlockHeight: CGFloat = 22 + 2 + 36
            let textTopY = (height - textBlockHeight) / 2
            
            titleLabel.frame = CGRect(x: titleStartX, y: textTopY, width: titleWidth, height: 22)
            
            let iconSize: CGFloat = 16
            let messageY = titleLabel.frame.maxY + 2
            let messageAvailableWidth = width - titleStartX - sidePadding - 5
            
            if !mediaIconView.isHidden {
                mediaIconView.frame = CGRect(x: titleStartX, y: messageY + 2, width: iconSize, height: iconSize)
                messageLabel.frame = CGRect(x: titleStartX + iconSize + 4, y: messageY, width: messageAvailableWidth - iconSize - 4, height: 36)
            } else {
                messageLabel.frame = CGRect(x: titleStartX, y: messageY, width: messageAvailableWidth, height: 36)
            }
        }
    }
}
