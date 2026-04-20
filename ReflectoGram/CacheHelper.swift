import Foundation
import UIKit

enum CacheCategory {
    case avatar
    case thumb
    case full
    case messages
}

class CacheHelper {
    static let shared = CacheHelper()
    private let fileManager = FileManager.default
    
    private var documentsPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    private var avatarsPath: String { (documentsPath as NSString).appendingPathComponent("avatars") }
    private var messagesPath: String { (documentsPath as NSString).appendingPathComponent("messages") }
    private var thumbPath: String { (documentsPath as NSString).appendingPathComponent("media/thumb") }
    private var fullPath: String { (documentsPath as NSString).appendingPathComponent("media/full") }
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        let paths = [avatarsPath, messagesPath, thumbPath, fullPath]
        for path in paths {
            if !fileManager.fileExists(atPath: path) {
                do {
                    try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("CACHE ERROR: Can't create folder at \(path)")
                }
            }
        }
    }

    private func getPath(for category: CacheCategory, id: String) -> String {
        let folder: String
        switch category {
        case .avatar: folder = avatarsPath
        case .thumb: folder = thumbPath
        case .full: folder = fullPath
        case .messages: folder = messagesPath
        }
        
        let fileName = category == .messages ? "msg_\(id).json" : "\(id).png"
        return (folder as NSString).appendingPathComponent(fileName)
    }

    func saveImage(image: UIImage, id: String, category: CacheCategory) {
        DispatchQueue.global(priority: .low).async {
            if let data = image.pngData() {
                let filePath = self.getPath(for: category, id: id)
                (data as NSData).write(toFile: filePath, atomically: true)
            }
        }
    }
    
    func getCachedImage(id: String, category: CacheCategory) -> UIImage? {
        let filePath = getPath(for: category, id: id)
        if fileManager.fileExists(atPath: filePath) {
            return UIImage(contentsOfFile: filePath)
        }
        return nil
    }

    func saveMessages(_ messages: [Message], forChatID chatID: String) {
        let path = getPath(for: .messages, id: chatID)
        saveObject(messages, toPath: path)
    }
    
    func getCachedMessages(forChatID chatID: String) -> [Message]? {
        let path = getPath(for: .messages, id: chatID)
        return loadObject(fromPath: path)
    }

    func saveChats(_ chats: [Chat]) {
        let path = (documentsPath as NSString).appendingPathComponent("cached_chats.json")
        saveObject(chats, toPath: path)
    }
    
    func getCachedChats() -> [Chat]? {
        let path = (documentsPath as NSString).appendingPathComponent("cached_chats.json")
        return loadObject(fromPath: path)
    }
    
    private func saveObject<T: Encodable>(_ object: T, toPath path: String) {
        DispatchQueue.global(priority: .low).async {
            do {
                let data = try JSONEncoder().encode(object)
                (data as NSData).write(toFile: path, atomically: true)
            } catch { print("CACHE ERROR: \(error)") }
        }
    }
    
    private func loadObject<T: Decodable>(fromPath path: String) -> T? {
        guard fileManager.fileExists(atPath: path) else { return nil }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode(T.self, from: data)
        } catch { return nil }
    }
}
