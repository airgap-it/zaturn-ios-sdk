//
//  Base64.swift
//  
//
//  Created by Julia Samol on 12.07.21.
//

import Foundation

extension Array where Element == UInt8 {
    static func decodeBase64(_ string: String) throws -> [UInt8] {
        guard let data = Data(base64Encoded: string) else {
            throw Error.invalidBase64String
        }
        
        return [UInt8](data)
    }
    
    func encodeBase64() -> String {
        Data(self).base64EncodedString()
    }
    
    enum Error: Swift.Error {
        case invalidBase64String
    }
}
