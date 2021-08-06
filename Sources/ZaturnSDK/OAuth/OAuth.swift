//
//  OAuth.swift
//  
//
//  Created by Julia Samol on 14.07.21.
//

import Foundation

struct OAuth {
    private var appleOAuth: AppleOAuth { .shared }
    private var googleOAuth: GoogleOAuth { .shared }
    
    func signIn(nonce: String, using provider: OAuthProvider, completion: @escaping (Result<String, Swift.Error>) -> ()) {
        switch provider {
        case let .apple(configuration):
            appleOAuth.signIn(with: configuration.requestedOperation, for: configuration.requestedScopes, usingNonce: nonce, completion: completion)
        case let .google(configuration):
            guard let viewController = configuration.viewController else {
                completion(.failure(Error.missingPresentingViewController))
                return
            }
            
            googleOAuth.signIn(
                withClientID: configuration.clientID,
                andServerClientID: configuration.serverClientID,
                forScopes: configuration.scopes,
                usingNonce: nonce,
                preseting: viewController,
                completion: completion
            )
        }
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case missingPresentingViewController
    }
}
