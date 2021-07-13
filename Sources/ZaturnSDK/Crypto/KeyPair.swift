//
//  KeyPair.swift
//  
//
//  Created by Julia Samol on 09.07.21.
//

import Foundation

typealias Seed = [UInt8]

typealias PrivateKey = [UInt8]
typealias PublicKey = [UInt8]
typealias SessionKey = [UInt8]

struct KeyPair {
    let privateKey: PrivateKey
    let publicKey: PublicKey
}
