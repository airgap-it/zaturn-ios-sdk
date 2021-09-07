//
//  AuthenticationServies.swift
//  
//
//  Created by Julia Samol on 06.09.21.
//

import Foundation
import AuthenticationServices

extension ASAuthorizationAppleIDCredential {
    func toOAuthID() throws -> OAuthID {
        guard let authorizationCode = authorizationCode else {
            throw Error.missingAuthorizationCode
        }
        
        guard let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw Error.authorizationCodeConversionFailed
        }
        
        guard let identityToken = identityToken else {
            throw Error.missingIdentityToken
        }
        guard let identityToken = String(data: identityToken, encoding: .utf8) else {
            throw Error.identityTokenConversionFailed
        }
        
        return OAuthID(
            accessToken: authorizationCode,
            idToken: identityToken,
            scope: authorizedScopes.map({ $0.rawValue }).joined(separator: " "),
            additional: [
                "givenName": fullName?.givenName,
                "middleName": fullName?.middleName,
                "familyName": fullName?.familyName,
                "email": email
            ].compactMapValues { $0 }
        )
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case missingAuthorizationCode
        case authorizationCodeConversionFailed
        
        case missingIdentityToken
        case identityTokenConversionFailed
    }
}
