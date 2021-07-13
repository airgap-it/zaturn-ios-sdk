//
//  SodiumCrypto.swift
//  
//
//  Created by Julia Samol on 09.07.21.
//

import Foundation
import Clibsodium

struct SodiumCrypto: Crypto {
    func keyPair(from seed: Seed?) throws -> KeyPair {
        var publicKey = [UInt8](repeating: 0, count: crypto_box_publickeybytes())
        var privateKey = [UInt8](repeating: 0, count: crypto_box_secretkeybytes())
        
        let status = crypto_box_keypair(&publicKey, &privateKey)
        guard status == 0 else {
            throw Error.keyPairNotGenerated
        }
        
        return KeyPair(privateKey: privateKey, publicKey: publicKey)
    }
    
    func sessionKey(from privateKey: PrivateKey, and publicKey: PublicKey) throws -> SessionKey {
        guard privateKey.count == crypto_box_secretkeybytes() else {
            throw Error.invalidPrivateKey
        }
        
        guard publicKey.count == crypto_box_publickeybytes() else {
            throw Error.invalidPublicKey
        }
        
        var key = [UInt8](repeating: 0, count: crypto_box_beforenmbytes())
        
        let status = crypto_box_beforenm(&key, publicKey, privateKey)
        guard status == 0 else {
            throw Error.sessionKeyNotGenerated
        }
        
        return key
    }
    
    func encrypt(_ message: [UInt8], with sessionKey: SessionKey) throws -> [UInt8] {
        guard sessionKey.count == crypto_box_beforenmbytes() else {
            throw Error.invalidSessionKey
        }
        
        let nonce = randomBytes(length: crypto_box_noncebytes())
        var ciphertext = [UInt8](repeating: 0, count: message.count + crypto_box_macbytes())
        
        let status = crypto_box_easy_afternm(&ciphertext, message, UInt64(message.count), nonce, sessionKey)
        guard status == 0 else {
            throw Error.encryptionFailed
        }
        
        return nonce + ciphertext
    }
    
    func decrypt(_ message: [UInt8], with sessionKey: SessionKey) throws -> [UInt8] {
        guard sessionKey.count == crypto_box_beforenmbytes() else {
            throw Error.invalidSessionKey
        }
        
        let nonce = Array(message[0..<crypto_box_noncebytes()])
        let ciphertext = Array(message[crypto_box_noncebytes()...])
        var decrypted = [UInt8](repeating: 0, count: ciphertext.count - crypto_box_macbytes())
        let status = crypto_box_open_easy_afternm(&decrypted, ciphertext, UInt64(ciphertext.count), nonce, sessionKey)
        guard status == 0 else {
            throw Error.decryptionFailed
        }
        
        return decrypted
    }
    
    private func randomBytes(length: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: length)
        randombytes_buf(&bytes, length)
        
        return bytes
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case keyPairNotGenerated
        case sessionKeyNotGenerated
        
        case invalidPrivateKey
        case invalidPublicKey
        case invalidSessionKey
        
        case encryptionFailed
        case decryptionFailed
    }
}
