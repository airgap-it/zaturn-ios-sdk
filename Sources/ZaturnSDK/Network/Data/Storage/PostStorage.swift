//
//  PostStorage.swift
//  
//
//  Created by Julia Samol on 12.07.21.
//

import Foundation

struct StoreRecoveryPartRequest: Codable {
    let data: [UInt8]
    
    init(data: [UInt8]) {
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try [UInt8].decodeBase64(try container.decode(String.self, forKey: .data))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.encodeBase64(), forKey: .data)
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}

typealias StoreRecoveryPartResponse = String
