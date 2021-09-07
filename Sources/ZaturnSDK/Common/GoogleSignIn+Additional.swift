//
//  GoogleSignIn.swift
//  
//
//  Created by Julia Samol on 06.09.21.
//

import Foundation
#if COCOAPODS
import AdvancedGoogleSignIn
#else
import GoogleSignIn
#endif

extension GIDGoogleUser {
    func toOAuthID() throws -> OAuthID {
        guard let idToken = authentication.idToken else {
            throw Error.missingIdentityToken
        }
        
        return OAuthID(
            accessToken: authentication.accessToken,
            expiresIn: authentication.accessTokenExpirationDate,
            idToken: idToken,
            scope: grantedScopes?.joined(separator: " "),
            tokenType: "Bearer",
            refreshToken: authentication.refreshToken,
            additional: [
                "displayName": profile?.name,
                "givenName": profile?.givenName,
                "familyName": profile?.familyName
            ].compactMapValues { $0 }
        )
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case missingIdentityToken
    }
}
