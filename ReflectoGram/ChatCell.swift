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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = contentView.frame.width
        
        avatarImageView.frame = CGRect(x: 10, y: 10, width: 50, height: 50) // x -- padding
        timeLabel.frame = CGRect(x: width - 90, y: 12, width: 80, height: 20) // x -- - 80 - padding
        
        let titleWidth = width - avatarImageView.frame.maxX - timeLabel.frame.width // padding * 3
        titleLabel.frame = CGRect(x: avatarImageView.frame.maxX + 10, y: 10, width: titleWidth, height: 22) // x -- avatar... + padding
        
        let messageWidth = width - avatarImageView.frame.maxX - 20 // padding * 2
        messageLabel.frame = CGRect(x: avatarImageView.frame.maxX + 10, y: titleLabel.frame.maxY + 2, width: messageWidth, height: 36) // x -- avatar... + padding
    }
}
