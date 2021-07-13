//
//  Crypto.swift
//  
//
//  Created by Julia Samol on 09.07.21.
//

import Foundation

protocol Crypto {
    func keyPair(from seed: Seed?) throws -> KeyPair
    func sessionKey(from privateKey: PrivateKey, and publicKey: PublicKey) throws -> SessionKey
    func encrypt(_ message: [UInt8], with sessionKey: SessionKey) throws -> [UInt8]
    func decrypt(_ message: [UInt8], with sessionKey: SessionKey) throws -> [UInt8]
}

extension Crypto {
    func keyPair() throws -> KeyPair {
        try keyPair(from: nil)
    }
}
