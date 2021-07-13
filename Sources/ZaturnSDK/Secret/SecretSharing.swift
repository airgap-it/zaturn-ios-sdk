//
//  SecretSharing.swift
//  
//
//  Created by Julia Samol on 09.07.21.
//

import Foundation

protocol SecretSharing {
    func split(_ secret: [UInt8], into groups: [SecretSharingGroup], withThreshold threshold: Int) throws -> [[[UInt8]]]
    func join(_ parts: [[[UInt8]]]) throws -> [UInt8]
}

struct SecretSharingGroup {
    let members: Int
    let memberThreshold: Int
}

enum SecretSharingError {
    
}
