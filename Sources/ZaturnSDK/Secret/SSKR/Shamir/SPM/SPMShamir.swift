//
//  SPMShamir.swift
//  
//
//  Created by Julia Samol on 13.07.21.
//

import Foundation
#if !COCOAPODS
    import ShamirSecretShare

    struct SPMShamir: Shamir {
        func split(_ secret: [UInt8], intoParts parts: Int, withThreshold threshold: Int) throws -> [[UInt8]] {
            guard parts > 1 else {
                return [secret]
            }
            
            let secret = try Secret(data: .init(secret), threshold: threshold, shares: parts)
            let share = try secret.split()
            
            return share.map { Array([UInt8]($0.data)[1...]) }
        }
        
        func join(_ parts: [[UInt8]]) throws -> [UInt8] {
            guard parts.count != 1 else {
                return parts[0]
            }
            
            let shares = try parts.enumerated().map { (index, part) in try Secret.Share(data: .init([UInt8(index + 1)] + part)) }
            let combined = try Secret.combine(shares: shares)
            
            return [UInt8](combined)
        }
    }
#endif
