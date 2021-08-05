//
//  AppleOAuthConfiguration.swift
//  
//
//  Created by Julia Samol on 05.08.21.
//

import Foundation
import AuthenticationServices

public struct AppleOAuthConfiguration {
    let requestedOperation: ASAuthorization.OpenIDOperation?
    let requestedScopes: [ASAuthorization.Scope]
    
    public init(requestedOperation: ASAuthorization.OpenIDOperation? = nil, requestedScopes: [ASAuthorization.Scope] = []) {
        self.requestedOperation = requestedOperation
        self.requestedScopes = requestedScopes
    }
}
