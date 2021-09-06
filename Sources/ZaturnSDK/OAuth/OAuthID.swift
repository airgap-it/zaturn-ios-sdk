//
//  OAuthID.swift
//  
//
//  Created by Julia Samol on 06.09.21.
//

import Foundation

public struct OAuthID {
    let accessToken: String?
    let expiresIn: Date?
    let idToken: String
    let scope: String?
    let tokenType: String?
    let refreshToken: String?
    let additional: [String: String]
    
    init(
        accessToken: String? = nil,
        expiresIn: Date? = nil,
        idToken: String,
        scope: String? = nil,
        tokenType: String? = nil,
        refreshToken: String? = nil,
        additional: [String: String] = [:]
    ) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.idToken = idToken
        self.scope = scope
        self.tokenType = tokenType
        self.refreshToken = refreshToken
        self.additional = additional
    }
}
