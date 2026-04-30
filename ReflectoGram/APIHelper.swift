//
//  APIHelper.swift
//  ReflectoGram
//
//  Created by spytaspund on 07.02.2026.
//

import Foundation
import UIKit

struct SeenOnline: Codable {
    let type: Int
    let seenOnline: Int
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
}

struct MediaInfo: Codable {
    let hasThumb: Bool?
    let fileName: String?
    let mimeType: String?
    let size: Int?
    let emoji: String?
    let isAnimated: Bool?
    let isVideo: Bool?
    let duration: Int?
    let title: String?
    let performer: String?
}

struct Message: Codable {
    let id: Int
    let sender: String
    let senderId: Int64
    let text: String
    let date: String
    let isOutgoing: Bool
    let type: String
    let mediaToken: String?
    let hasMedia: Bool
    let mediaInfo: MediaInfo?
}

struct ProfileChannel: Codable {
    let id: Int64
    let title: String
    let username: String?
    let subsCount: Int
    let lastPost: Message?
}

struct Chat: Codable {
    let id: Int64
    let name: String
    let type: String
    let date: String?
    let lastMessage: Message?
    let unreadCount: Int?
    
    let username: String?
    let bio: String?
    let phone: String?
    let isPremium: Bool?
    let seenOnline: SeenOnline?
    let profileChannel: ProfileChannel?
    let profileMusic: [ProfileMusic]?
    let members: [ChatMember]?
    
    // for MessagesVC
    init(id: Int64, name: String) {
        self.id = id
        self.name = name
        self.type = "user"
        self.date = nil
        self.lastMessage = nil
        self.unreadCount = nil
        self.username = nil
        self.bio = nil
        self.phone = nil
        self.isPremium = nil
        self.seenOnline = nil
        self.profileChannel = nil
        self.profileMusic = nil
        self.members = nil
    }
}

struct ChatsResponseContainer: Codable {
    let chats: [Chat]
}

struct MessagesResponseContainer: Codable {
    let messages: [Message]
}

struct SendMessageResponse: Codable {
    let status: String
    let id: Int?
    let date: String?
    let error: String?
}

enum ImageCategory {
    case avatar
    case thumb
    case albumCover
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
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // uncomment if snake case somehow sneaks in
        // decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

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
            case .success(let container): completion(.success(container.chats))
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    func fetchMessages(from urlString: String, key: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        fetchAndDecode(urlString: urlString, keyHex: key) { (result: Result<MessagesResponseContainer, Error>) in
            switch result {
            case .success(let container): completion(.success(container.messages))
            case .failure(let error): completion(.failure(error))
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
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: url), queue: .main) { [weak self] response, data, error in
            let httpResponse = response as? HTTPURLResponse
            if error == nil, let statusCode = httpResponse?.statusCode, statusCode == 200,
               let imageData = data, let image = UIImage(data: imageData) {
                CacheHelper.shared.saveImage(image: image, id: cacheKey, category: category)
                self?.imageCache.setObject(image, forKey: nsKey)
                completion(image)
            } else {
                if let code = httpResponse?.statusCode { print("Image download failed with code: \(code)") }
                completion(nil)
            }
        }
    }
    
    func fetchAbout(from urlString: String, key: String, completion: @escaping (Result<Chat, Error>) -> Void) {
        fetchAndDecode(urlString: urlString, keyHex: key) { (result: Result<Chat, Error>) in
            completion(result)
        }
    }
    
    func sendMessage(text: String, chatID: String, sessionID: String, serverURL: String, keyHex: String, completion: @escaping (Result<SendMessageResponse, Error>) -> Void) {
        let urlString = "\(serverURL)/send_message?chat_id=\(chatID)&session_id=\(sessionID)"
        guard let url = URL(string: urlString) else { return }
        
        let payload = ["text": text]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let encryptedData = try? CryptoService.encrypt(data: jsonData, keyHex: keyHex) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = encryptedData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: .main) { response, data, error in
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
                let responseObj = try self.decoder.decode(SendMessageResponse.self, from: decryptedData)
                completion(.success(responseObj))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension UIImageView {
    func setRemoteImage(url: String, cacheKey: String, placeholder: String, useSpinner: Bool = false) {
        self.image = UIImage(named: placeholder)
        self.accessibilityIdentifier = cacheKey
        let spinnerTag = 999
        if useSpinner {
            if self.viewWithTag(spinnerTag) == nil {
                let s = UIActivityIndicatorView(style: .gray)
                s.tag = spinnerTag
                s.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                s.startAnimating()
                self.addSubview(s)
            }
        }

        var category: CacheCategory = .full
        if cacheKey.hasPrefix("avatar") { category = .avatar }
        else if cacheKey.hasPrefix("thumb") { category = .thumb }
        else if cacheKey.hasPrefix("cover") || cacheKey.hasPrefix("audio") { category = .albumCover }

        APIHelper.shared.fetchImage(urlString: url, cacheKey: cacheKey, category: category) { [weak self] downloadedImage in
            guard self?.accessibilityIdentifier == cacheKey else { return }
            if useSpinner { self?.viewWithTag(spinnerTag)?.removeFromSuperview() }
            if let img = downloadedImage {
                self?.image = img
            }
        }
    }
}
