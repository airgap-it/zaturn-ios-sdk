//
//  ShamirFactory.swift
//  
//
//  Created by Julia Samol on 13.07.21.
//

import Foundation

struct ShamirCreator {
    private init() {}
    
    static func create() -> Shamir {
        #if COCOAPODS
            return CocoaPodsShamir()
        #else
            return SPMShamir()
        #endif
    }
}
