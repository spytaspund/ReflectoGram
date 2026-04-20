//
//  CryptoHelper.swift
//  ReflectoGram
//
//  Created by spytaspund on 07.02.2026.
//

import Foundation
import CommonCrypto

enum DecryptionError: Error {
    case invalidKeyOrIV
    case decryptionFailed
    case dataToStringFailed
}

class CryptoService {
    static func decrypt(data: Data, keyHex: String) throws -> Data {
        let ivSize = 16
        guard data.count > ivSize else { throw DecryptionError.decryptionFailed}
        
        let ivData = data.prefix(ivSize)
        let cipherText = data.dropFirst(ivSize)
        guard let keyData = Data(hexString: keyHex.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw DecryptionError.invalidKeyOrIV
        }
        let bufferSize = cipherText.count + kCCBlockSizeAES128
        var decryptedData = Data(count: bufferSize)
        var numBytesDecrypted: size_t = 0
        let status = decryptedData.withUnsafeMutableBytes { decryptedBytes in
            cipherText.withUnsafeBytes { encryptedBytes in
                ivData.withUnsafeBytes { ivBytes in
                    keyData.withUnsafeBytes { keyBytes in
                        CCCrypt(CCOperation(kCCDecrypt),
                                CCAlgorithm(kCCAlgorithmAES),
                                CCOptions(kCCOptionPKCS7Padding),
                                keyBytes.baseAddress, keyData.count,
                                ivBytes.baseAddress,
                                encryptedBytes.baseAddress, cipherText.count,
                                decryptedBytes.baseAddress, bufferSize,
                                &numBytesDecrypted)
                    }
                }
            }
        }
        guard status == kCCSuccess else {
            throw DecryptionError.decryptionFailed
        }
        return decryptedData.prefix(numBytesDecrypted)
    }
}
