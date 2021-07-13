//
//  Shamir.swift
//  
//
//  Created by Julia Samol on 09.07.21.
//

import Foundation

protocol Shamir {
    func split(_ secret: [UInt8], intoParts parts: Int, withThreshold threshold: Int) throws -> [[UInt8]]
    func join(_ parts: [[UInt8]]) throws -> [UInt8]
}
