//
//  GetPublicKey.swift
//  
//
//  Created by Julia Samol on 12.07.21.
//

import Foundation

struct GetPublicKeyResponse: Codable {
    let publicKey: [UInt8]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        publicKey = try [UInt8].decodeBase64(try container.decode(String.self, forKey: .publicKey))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(publicKey.encodeBase64(), forKey: .publicKey)
    }
    
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
    }
}
