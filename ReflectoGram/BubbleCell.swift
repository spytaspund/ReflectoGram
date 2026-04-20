import UIKit

func isiOS6() -> Bool {
    let version = (UIDevice.current.systemVersion as NSString).floatValue
    return version < 7.0
}

class BubbleCell: UITableViewCell {
    let legacyUI = isiOS6()
    var senderNameLabel = UILabel()
    var timeLabel = UILabel()
    var avatarImageView = UIImageView()
    var bubbleView = UIView()
    var isIncoming: Bool = true
    var isGroup: Bool = true
    var customBubbleWidth: CGFloat?
    
    func setupBaseUI() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        contentView.subviews.forEach { $0.removeFromSuperview() }
        bubbleView.subviews.forEach { $0.removeFromSuperview() }

        contentView.addSubview(avatarImageView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(senderNameLabel)
        bubbleView.addSubview(timeLabel)

        senderNameLabel.backgroundColor = .clear
        timeLabel.backgroundColor = .clear
        bubbleView.layer.cornerRadius = 12
        senderNameLabel.font = UIFont.boldSystemFont(ofSize: 12)
        avatarImageView.clipsToBounds = true // sussy, remove if it crashes
    }

    override func layoutSubviews() {
            super.layoutSubviews()
            let screenWidth = contentView.frame.width
            let maxBubbleWidth = screenWidth * 0.75
            let finalBubbleWidth = customBubbleWidth ?? maxBubbleWidth

            if isIncoming {
                var xPos: CGFloat
                if isGroup {
                    avatarImageView.isHidden = false
                    avatarImageView.frame = CGRect(x: 8, y: 8, width: 35, height: 35)
                    xPos = 50
                } else {
                    avatarImageView.isHidden = true
                    xPos = 10
                }
                bubbleView.frame = CGRect(x: xPos, y: 8, width: finalBubbleWidth, height: contentView.frame.height - 10)
                bubbleView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
                senderNameLabel.isHidden = !isGroup
            } else {
                avatarImageView.isHidden = true
                let xPos = screenWidth - finalBubbleWidth - 16
                bubbleView.frame = CGRect(x: xPos, y: 8, width: finalBubbleWidth, height: contentView.frame.height - 10)
                if legacyUI { bubbleView.backgroundColor = UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1.0) }
                else { bubbleView.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) }
                timeLabel.textColor = UIColor(white: 1, alpha: 0.85)
                senderNameLabel.isHidden = true
            }
            
            if legacyUI { avatarImageView.layer.cornerRadius = 12 }
            else { avatarImageView.layer.cornerRadius = 17.5 }
        }
}

class TextMessageCell: BubbleCell {
    var messageLabel = UILabel()
    
    override func setupBaseUI() {
        super.setupBaseUI()
        messageLabel.backgroundColor = .clear
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = NSTextAlignment.right
        timeLabel.textColor = UIColor(white: 0.5, alpha: 0.6)
        bubbleView.addSubview(messageLabel)
    }
    
    override func layoutSubviews() {
        let screenWidth = contentView.frame.width
        let maxBubbleWidth = screenWidth * 0.75
        let text = messageLabel.text ?? ""
        let textMaxWidth = maxBubbleWidth - 20
        let textSize = LayoutHelper.sizeForText(text, font: messageLabel.font, maxWidth: textMaxWidth)
        let senderSize = LayoutHelper.sizeForText(senderNameLabel.text ?? "User", font: messageLabel.font, maxWidth: textMaxWidth)
        let calcWidth = max(textSize.width + 40, 70, senderSize.width + 16)
    
        self.customBubbleWidth = min(calcWidth, maxBubbleWidth)
        super.layoutSubviews()
        
        let bW = bubbleView.frame.width
        let bH = bubbleView.frame.height
        
        senderNameLabel.frame = CGRect(x: 10, y: 8, width: bW - 16, height: 14)
        timeLabel.frame = CGRect(x: bW - 60, y: bH - 16, width: 50, height: 12)
        
        if isIncoming {
            if isGroup {
                if legacyUI { messageLabel.frame = CGRect(x: 10, y: 24, width: bW - 20, height: bH - 40) }
                else { messageLabel.frame = CGRect(x: 10, y: 16, width: bW - 20, height: bH - 35) }
            } else {
                if legacyUI { messageLabel.frame = CGRect(x: 10, y: 8, width: bW - 20, height: bH - 24) }
                else { messageLabel.frame = CGRect(x: 10, y: -2, width: bW - 20, height: bH - 16) }
            }
            messageLabel.textColor = UIColor(white: 0, alpha: 1)
        } else {
            messageLabel.frame = CGRect(x: 10, y: -2, width: bW - 20, height: bH - 16)
            messageLabel.textColor = UIColor(white: 1, alpha: 1)
        }
    }
}

class ImageMessageCell: BubbleCell {
    var photoView = UIImageView()
    var captionLabel = UILabel()
    var timeOverlayView = UIView()
    override func setupBaseUI() {
        super.setupBaseUI()
        
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.layer.cornerRadius = 8
        photoView.backgroundColor = .lightGray
        bubbleView.addSubview(photoView)
        
        captionLabel.backgroundColor = .clear
        captionLabel.numberOfLines = 0
        captionLabel.font = UIFont.systemFont(ofSize: 15)
        bubbleView.addSubview(captionLabel)
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        
        timeOverlayView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        timeOverlayView.layer.cornerRadius = 4
        timeOverlayView.isHidden = true
        bubbleView.addSubview(timeOverlayView)
        
        bubbleView.bringSubviewToFront(timeLabel)
    }

    override func layoutSubviews() {
        let screenWidth = contentView.frame.width
        self.customBubbleWidth = screenWidth * 0.75
        super.layoutSubviews()
        
        let bW = bubbleView.frame.width
        let bH = bubbleView.frame.height
        let padding: CGFloat = 4
        
        var topOffset: CGFloat = padding
        if isIncoming && isGroup {
            senderNameLabel.frame = CGRect(x: 10, y: 8, width: bW - 16, height: 14)
            topOffset = 29
        } else {
            senderNameLabel.frame = .zero
        }
        
        let hasCaption = !(captionLabel.text?.isEmpty ?? true)
        let captionHeight: CGFloat = hasCaption ? LayoutHelper.sizeForText(captionLabel.text ?? "", font: captionLabel.font, maxWidth: bW - 20).height : 0
        
        let photoHeight = bH - topOffset - captionHeight - (hasCaption ? 20 : padding)
        photoView.frame = CGRect(x: padding, y: topOffset, width: bW - (padding * 2), height: photoHeight)
        
        if hasCaption && isGroup && isIncoming { photoView.layer.cornerRadius = 4 }
        
        if hasCaption {
            captionLabel.isHidden = false
            captionLabel.frame = CGRect(x: 10, y: photoView.frame.maxY + 4, width: bW - 20, height: captionHeight)
            captionLabel.textColor = isIncoming ? .black : .white
            
            if legacyUI { timeLabel.frame = CGRect(x: bW - 48, y: bH - 16, width: 50, height: 12) }
            else { timeLabel.frame = CGRect(x: bW - 40, y: bH - 16, width: 50, height: 12) }
            timeLabel.textColor = isIncoming ? .gray : UIColor(white: 1, alpha: 0.8)
            timeOverlayView.isHidden = true
        } else {
            captionLabel.isHidden = true
            timeOverlayView.isHidden = false
            let timeW: CGFloat = 48
            let timeH: CGFloat = 16
            let timeX = bW - timeW - 8
            let timeY = photoView.frame.maxY - timeH - 4
            
            timeOverlayView.frame = CGRect(x: timeX, y: timeY, width: timeW, height: timeH)
            timeLabel.frame = timeOverlayView.frame
            timeLabel.textAlignment = .center
            timeLabel.textColor = .white
        }
    }
}

class StickerMessageCell: BubbleCell {
    var stickerImageView = UIImageView()
    var timeOverlayView = UIView()

    override func setupBaseUI() {
        super.setupBaseUI()
        bubbleView.backgroundColor = .clear
        
        stickerImageView.contentMode = .scaleAspectFit
        stickerImageView.backgroundColor = .clear
        bubbleView.addSubview(stickerImageView)
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = .center
        timeLabel.textColor = .white
        
        timeOverlayView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        timeOverlayView.layer.cornerRadius = 6
        bubbleView.addSubview(timeOverlayView)
        
        bubbleView.bringSubviewToFront(timeLabel)
        senderNameLabel.isHidden = true
    }

    override func layoutSubviews() {
        let stickerSize: CGFloat = 160
        self.customBubbleWidth = stickerSize
        
        super.layoutSubviews()
        bubbleView.backgroundColor = .clear
        
        stickerImageView.frame = bubbleView.bounds
        
        let timeW: CGFloat = 45
        let timeH: CGFloat = 16
        let timeX = stickerSize - timeW - 8
        let timeY = stickerSize - timeH - 8
        
        timeOverlayView.frame = CGRect(x: timeX, y: timeY, width: timeW, height: timeH)
        timeLabel.frame = timeOverlayView.frame
    }
}

class AudioMessageCell: BubbleCell {
    var coverImageView = UIImageView()
    var playButton = UIButton()
    var titleLabel = UILabel()
    var performerLabel = UILabel()
    var durationLabel = UILabel()
    var captionLabel = UILabel()

    override func setupBaseUI() {
        super.setupBaseUI()
        
        coverImageView.backgroundColor = .lightGray
        coverImageView.layer.cornerRadius = 6
        coverImageView.clipsToBounds = true
        bubbleView.addSubview(coverImageView)
        
        playButton.backgroundColor = UIColor(white: 0, alpha: 0.3)
        playButton.imageView?.image = UIImage(named: "paperplane")
        bubbleView.addSubview(playButton)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.backgroundColor = .clear
        bubbleView.addSubview(titleLabel)
        
        performerLabel.font = UIFont.systemFont(ofSize: 12)
        performerLabel.textColor = .darkGray
        performerLabel.backgroundColor = .clear
        bubbleView.addSubview(performerLabel)
        
        durationLabel.font = UIFont.systemFont(ofSize: 12)
        durationLabel.textColor = .gray
        durationLabel.backgroundColor = .clear
        bubbleView.addSubview(durationLabel)
        
        captionLabel.numberOfLines = 0
        captionLabel.font = UIFont.systemFont(ofSize: 15)
        captionLabel.backgroundColor = .clear
        bubbleView.addSubview(captionLabel)
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = NSTextAlignment.right
        timeLabel.textColor = UIColor(white: 0.5, alpha: 60)
    }

    override func layoutSubviews() {
        let screenWidth = contentView.frame.width
        let maxBubbleWidth = screenWidth * 0.75
        
        let infoX: CGFloat = 8 + 45 + 10
        let rightPadding: CGFloat = 45
        
        let maxAvailableTextWidth = maxBubbleWidth - infoX - rightPadding
        
        let titleW = LayoutHelper.sizeForText(titleLabel.text ?? "", font: titleLabel.font, maxWidth: maxAvailableTextWidth).width
        let performerW = LayoutHelper.sizeForText(performerLabel.text ?? "", font: performerLabel.font, maxWidth: maxAvailableTextWidth).width
        let captionW = LayoutHelper.sizeForText(captionLabel.text ?? "", font: captionLabel.font, maxWidth: maxBubbleWidth - 20).width
        
        let maxContentW = max(titleW, performerW)
        let calcWidthForAudio = infoX + maxContentW + rightPadding + 5 // +5 для страховки
        
        let calcWidth = max(max(calcWidthForAudio, captionW + 20), 180)
        
        self.customBubbleWidth = min(calcWidth, maxBubbleWidth)
        super.layoutSubviews()
        
        let bW = bubbleView.frame.width
        let bH = bubbleView.frame.height
        let padding: CGFloat = 8
        
        let topOffset: CGFloat = (isIncoming && isGroup) ? 25 : padding
        if isIncoming && isGroup {
            senderNameLabel.frame = CGRect(x: 10, y: 5, width: bW - 20, height: 15)
        }

        let coverSize: CGFloat = 45
        coverImageView.frame = CGRect(x: padding, y: topOffset, width: coverSize, height: coverSize)
        playButton.frame = coverImageView.frame
        playButton.layer.cornerRadius = coverSize / 2
        
        titleLabel.frame = CGRect(x: infoX, y: topOffset, width: bW - infoX - 40, height: 16)
        performerLabel.frame = CGRect(x: infoX, y: titleLabel.frame.maxY + 2, width: bW - infoX - 10, height: 14)
        durationLabel.frame = CGRect(x: bW - 40, y: topOffset + 1, width: 35, height: 14)

        let hasCaption = !(captionLabel.text?.isEmpty ?? true)
        if hasCaption {
            captionLabel.isHidden = false
            let captionH = LayoutHelper.sizeForText(captionLabel.text ?? "", font: captionLabel.font, maxWidth: bW - 20).height
            captionLabel.frame = CGRect(x: 10, y: coverImageView.frame.maxY + 8, width: bW - 20, height: captionH)
            captionLabel.textColor = isIncoming ? .black : .white
        } else {
            captionLabel.isHidden = true
        }

        timeLabel.frame = CGRect(x: bW - 60, y: bH - 16, width: 50, height: 12)
        timeLabel.textColor = isIncoming ? .gray : UIColor(white: 1, alpha: 0.8)
    }
}

class FileMessageCell: BubbleCell {
    var fileIconView = UIImageView()
    var fileNameLabel = UILabel()
    var fileMetaLabel = UILabel()
    var captionLabel = UILabel()

    override func setupBaseUI() {
        super.setupBaseUI()
        
        fileIconView.backgroundColor = .lightGray
        fileIconView.layer.cornerRadius = 6
        fileIconView.clipsToBounds = true
        bubbleView.addSubview(fileIconView)
        
        
        fileNameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        fileNameLabel.backgroundColor = .clear
        bubbleView.addSubview(fileNameLabel)
        
        fileMetaLabel.font = UIFont.systemFont(ofSize: 12)
        fileMetaLabel.textColor = .darkGray
        fileMetaLabel.backgroundColor = .clear
        bubbleView.addSubview(fileMetaLabel)
        
        captionLabel.numberOfLines = 0
        captionLabel.font = UIFont.systemFont(ofSize: 15)
        captionLabel.backgroundColor = .clear
        bubbleView.addSubview(captionLabel)
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = NSTextAlignment.right
        timeLabel.textColor = UIColor(white: 0.5, alpha: 60)
    }

    override func layoutSubviews() {
        let screenWidth = contentView.frame.width
        let maxBubbleWidth = screenWidth * 0.75
        
        let infoX: CGFloat = 8 + 45 + 10 // Отступ + иконка + отступ
        let maxAvailableTextWidth = maxBubbleWidth - infoX - 10
        
        // Считаем ширину имени файла и меты
        let fileW = LayoutHelper.sizeForText(fileNameLabel.text ?? "", font: fileNameLabel.font, maxWidth: maxAvailableTextWidth).width
        let metaW = LayoutHelper.sizeForText(fileMetaLabel.text ?? "", font: fileMetaLabel.font, maxWidth: maxAvailableTextWidth).width
        let captionW = LayoutHelper.sizeForText(captionLabel.text ?? "", font: captionLabel.font, maxWidth: maxBubbleWidth - 20).width
        
        let maxContentW = max(fileW, metaW)
        let calcWidthForFile = infoX + maxContentW + 20 // +20 для маргинов
        
        let calcWidth = max(max(calcWidthForFile, captionW + 20), 160) // Минимум 160 для файла
        self.customBubbleWidth = min(calcWidth, maxBubbleWidth)
        
        super.layoutSubviews()
        
        let bW = bubbleView.frame.width
        let bH = bubbleView.frame.height
        let padding: CGFloat = 8
        
        let topOffset: CGFloat = (isIncoming && isGroup) ? 25 : padding
        if isIncoming && isGroup {
            senderNameLabel.frame = CGRect(x: 10, y: 5, width: bW - 20, height: 15)
        }

        let coverSize: CGFloat = 45
        fileIconView.frame = CGRect(x: padding, y: topOffset, width: coverSize, height: coverSize)
        
        fileNameLabel.frame = CGRect(x: infoX, y: topOffset, width: bW - infoX - 8, height: 16)
        fileMetaLabel.frame = CGRect(x: infoX, y: fileNameLabel.frame.maxY + 2, width: bW - infoX - 10, height: 14)

        let hasCaption = !(captionLabel.text?.isEmpty ?? true)
        if hasCaption {
            captionLabel.isHidden = false
            let captionH = LayoutHelper.sizeForText(captionLabel.text ?? "", font: captionLabel.font, maxWidth: bW - 20).height
            captionLabel.frame = CGRect(x: 10, y: fileIconView.frame.maxY + 8, width: bW - 20, height: captionH)
            captionLabel.textColor = isIncoming ? .black : .white
        } else {
            captionLabel.isHidden = true
        }

        timeLabel.frame = CGRect(x: bW - 60, y: bH - 16, width: 50, height: 12)
        timeLabel.textColor = isIncoming ? .gray : UIColor(white: 1, alpha: 0.8)
    }
}

struct LayoutHelper {
    static func sizeForText(_ text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
        let textToMeasure = text.isEmpty ? " " : text
        let nsText = textToMeasure as NSString
        let constraintRect = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        
        if isiOS6() {
            // Если компилируешь старым Xcode, где это доступно:
            // return nsText.size(withFont: font, constrainedToSize: constraintRect, lineBreakMode: .byWordWrapping)
            
            // Если Xcode новый и sizeWithFont не компилится, используем хак через UILabel:
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: maxWidth, height: .greatestFiniteMagnitude))
            label.numberOfLines = 0
            label.font = font
            label.text = textToMeasure
            label.sizeToFit()
            return label.frame.size
        } else {
            let boundingBox = nsText.boundingRect(with: constraintRect,
                                                  options: .usesLineFragmentOrigin,
                                                  attributes: [NSAttributedString.Key.font: font],
                                                  context: nil)
            return CGSize(width: ceil(boundingBox.width), height: ceil(boundingBox.height))
        }
    }
}
