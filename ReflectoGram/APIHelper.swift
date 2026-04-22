//
//  APIHelper.swift
//  ReflectoGram
//
//  Created by spytaspund on 07.02.2026.
//

import Foundation
import UIKit

struct TgPrismData: Codable {
    let id: Int
    let message: String
    let sender: String
}

struct SeenOnline: Codable {
    let type: Int
    let seenOnline: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case type
        case seenOnline = "seen_online"
    }
}

struct ProfileChannel: Codable {
    let id: Int64
    let title: String
    let username: String?
}

struct ProfileMusic: Codable {
    let id: String
    let performer: String
    let title: String
    let duration: Int
}

struct ChatMember: Codable {
    let id: Int64
    let name: String
    let lastSeen: SeenOnline?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case lastSeen = "last_seen"
    }
}

struct Chat: Codable {
    let id: String
    let name: String
    let date: String
    let lastMessage: String
    let type: String
    
    let username: String?
    let bio: String?
    let phone: String?
    let isPremium: Bool
    let participantsCount: Int?
    
    let seenOnline: SeenOnline?
    let profileChannel: ProfileChannel?
    let profileMusic: [ProfileMusic]?
    let members: [ChatMember]?

    enum CodingKeys: String, CodingKey {
        case id, name, date, lastMessage, type, username, bio, phone
        case isPremium = "is_premium"
        case participantsCount = "participants_count"
        case seenOnline = "seen_online"
        case profileChannel = "profile_channel"
        case profileMusic = "profile_music"
        case members
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intID = try? container.decode(Int64.self, forKey: .id) { self.id = String(intID) }
        else if let strID = try? container.decode(String.self, forKey: .id) { self.id = strID }
        else { self.id = "0" }

        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Неизвестно"
        self.date = (try? container.decode(String.self, forKey: .date)) ?? ""
        self.lastMessage = (try? container.decode(String.self, forKey: .lastMessage)) ?? ""
        self.type = (try? container.decode(String.self, forKey: .type)) ?? "private"

        self.username = try? container.decode(String.self, forKey: .username)
        self.bio = try? container.decode(String.self, forKey: .bio)
        self.phone = try? container.decode(String.self, forKey: .phone)
        self.isPremium = (try? container.decode(Bool.self, forKey: .isPremium)) ?? false
        self.participantsCount = try? container.decode(Int.self, forKey: .participantsCount)
        
        self.seenOnline = try? container.decode(SeenOnline.self, forKey: .seenOnline)
        self.profileChannel = try? container.decode(ProfileChannel.self, forKey: .profileChannel)
        self.profileMusic = try? container.decode([ProfileMusic].self, forKey: .profileMusic)
        self.members = try? container.decode([ChatMember].self, forKey: .members)
    }
}

struct ChatsResponseContainer: Codable {
    let chats: [Chat]
}

enum MessageType: String, Codable {
    case text = "text"
    case image = "photo"
    case sticker = "sticker"
    case file = "file"
    case audio = "audio"
}

struct MediaInfo: Codable {
    let has_thumb: Bool?
    let emoji: String?
    let is_animated: Bool?
    let is_video: Bool?
    let duration: Int?
    let title: String?
    let performer: String?
    let question: String?
}

struct Message: Codable {
    let id: String
    let text: String?
    let date: String?
    let isOutgoing: Bool
    let type: MessageType
    let sender: String
    let senderID: String
    let mediaInfo: MediaInfo?
    let mediaToken: String?

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case date
        case isOutgoing = "is_outgoing"
        case type
        case sender
        case senderID = "senderID"
        case mediaInfo = "media_info"
        case mediaToken = "mediaToken"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = (try? container.decode(String.self, forKey: .type)) ?? "text"
        if let intID = try? container.decode(Int64.self, forKey: .id) {
            self.id = String(intID)
        } else {
            self.id = try container.decode(String.self, forKey: .id)
        }

        self.text = try? container.decode(String.self, forKey: .text)
        self.date = try? container.decode(String.self, forKey: .date)
        self.isOutgoing = (try? container.decode(Bool.self, forKey: .isOutgoing)) ?? false
        self.type = MessageType(rawValue: typeString) ?? .text
        self.sender = (try? container.decode(String.self, forKey: .sender)) ?? "Unknown"

        if let intSenderID = try? container.decode(Int64.self, forKey: .senderID) {
            self.senderID = String(intSenderID)
        } else {
            self.senderID = (try? container.decode(String.self, forKey: .senderID)) ?? "0"
        }

        self.mediaInfo = try? container.decode(MediaInfo.self, forKey: .mediaInfo)
        self.mediaToken = try? container.decode(String.self, forKey: .mediaToken)
    }
    // for testing purposes
    init(id: String, text: String?, date: String?, isOutgoing: Bool, type: MessageType, sender: String, senderID: String, mediaInfo: MediaInfo?, mediaToken: String?) {
        self.id = id
        self.text = text
        self.date = date
        self.isOutgoing = isOutgoing
        self.type = type
        self.sender = sender
        self.senderID = senderID
        self.mediaInfo = mediaInfo
        self.mediaToken = mediaToken
    }
}

struct MessagesResponseContainer: Codable {
    let messages: [Message]?
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            if let byte = UInt8(hexString[i..<j], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}

class APIHelper {
    static let shared = APIHelper()
    private let imageCache = NSCache<NSString, UIImage>()
    private init() { imageCache.countLimit = 50 }
    
    private func fetchAndDecode<T: Decodable>(urlString: String, keyHex: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: url), queue: .main) { response, data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let encryptedData = data else {
                completion(.failure(NSError(domain: "API", code: 204, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let decryptedData = try CryptoService.decrypt(data: encryptedData, keyHex: keyHex)
                let decodedObject = try JSONDecoder().decode(T.self, from: decryptedData)
                completion(.success(decodedObject))
            } catch {
                print("Parsing error (\(T.self)): \(error)")
                completion(.failure(error))
            }
        }
    }
    func fetchChats(from urlString: String, key: String, completion: @escaping (Result<[Chat], Error>) -> Void) {
        fetchAndDecode(urlString: urlString, keyHex: key) { (result: Result<ChatsResponseContainer, Error>) in
            switch result {
            case .success(let container):
                completion(.success(container.chats))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchAbout(from urlString: String, key: String, completion: @escaping (Result<Chat, Error>) -> Void) {
        fetchAndDecode(urlString: urlString, keyHex: key) { (result: Result<Chat, Error>) in
            completion(result)
        }
    }
    
    func fetchMessages(from urlString: String, key: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        fetchAndDecode(urlString: urlString, keyHex: key) { (result: Result<MessagesResponseContainer, Error>) in
            switch result {
            case .success(let container):
                if let messages = container.messages {
                    print("Success! Messages count: \(messages.count)")
                    completion(.success(messages))
                } else {
                    let error = NSError(domain: "API", code: 404, userInfo: [NSLocalizedDescriptionKey: "'messages' is empty"])
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchImage(urlString: String, cacheKey: String, category: CacheCategory, completion: @escaping (UIImage?) -> Void) {
        let nsKey = NSString(string: cacheKey)
        if let cached = imageCache.object(forKey: nsKey) {
            completion(cached)
            return
        }
        if let diskImage = CacheHelper.shared.getCachedImage(id: cacheKey, category: category) {
            imageCache.setObject(diskImage, forKey: nsKey)
            completion(diskImage)
            return
        }
        
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: url), queue: .main) { [weak self] _, data, _ in
            if let imageData = data, let image = UIImage(data: imageData) {
                CacheHelper.shared.saveImage(image: image, id: cacheKey, category: category)
                self?.imageCache.setObject(image, forKey: nsKey)
                completion(image)
            } else { completion(nil) }
        }
    }
}

extension UIImageView {
    func setAvatar(id: String, url: String) {
        self.image = UIImage(named: "reflectogram-person")
        self.accessibilityIdentifier = id
        APIHelper.shared.fetchImage(urlString: url, cacheKey: id, category: .avatar) { [weak self] image in
            if self?.accessibilityIdentifier == id { self?.image = image }
        }
    }
    func setMessagePhoto(messageId: String, url: String) {
        self.image = nil
        self.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        self.accessibilityIdentifier = messageId
        var spinner = self.viewWithTag(999) as? UIActivityIndicatorView
        if spinner == nil {
            spinner = UIActivityIndicatorView(style: .gray)
            spinner?.tag = 999
            spinner?.hidesWhenStopped = true
            spinner?.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            spinner?.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            if let spinner = spinner {
                self.addSubview(spinner)
            }
        }
        
        spinner?.startAnimating()
        let cacheKey = "msg_\(messageId)"
        APIHelper.shared.fetchImage(urlString: url, cacheKey: cacheKey, category: .thumb) { [weak self] image in
            if self?.accessibilityIdentifier == messageId {
                self?.backgroundColor = .clear
                self?.viewWithTag(999)?.removeFromSuperview()
                self?.image = image
            }
        }
    }
}
