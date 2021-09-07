//
//  OAuthID.swift
//  
//
//  Created by Julia Samol on 06.09.21.
//

import Foundation

public struct OAuthID: Codable {
    public let accessToken: String?
    public let expiresIn: Date?
    public let idToken: String
    public let scope: String?
    public let tokenType: String?
    public let refreshToken: String?
    public let additional: [String: String]
    
    public init(
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
