//
//  GoogleOAuth.swift
//  
//
//  Created by Julia Samol on 14.07.21.
//

import Foundation
import UIKit
#if COCOAPODS
import AdvancedGoogleSignIn
#else
import GoogleSignIn
#endif

struct GoogleOAuth {
    static let shared: GoogleOAuth = .init()
    
    private var basicScopes: Set<Scope> { Set([.openID, .email, .profile]) }
    
    private init() {}
    
    func signIn(
        withClientID clientID: String,
        andServerClientID serverClientID: String,
        forScopes scopes: [String],
        usingNonce nonce: String,
        preseting viewController: UIViewController,
        completion: @escaping (Result<OAuthID, Swift.Error>) -> ()
    ) {
        // As of 6.0.0, only basic profile scopes (i.e. "openid", "email" and "profile") are requested with an initial `GIDSignIn#signIn` call.
        // Other scopes have to be requested separately after a successful sign-in with an additional `GIDSignIn#addScopes` call.
        // This behaviour, however, has been a subject of discussion (https://github.com/google/GoogleSignIn-iOS/issues/23) and may change in future releases.
        let advancedScopes = scopes.filter { basicScopes.contains($0) }
        let configuration = GIDConfiguration(clientID: clientID, serverClientID: serverClientID, hostedDomain: nil, openIDRealm: nil, nonce: nonce)
        
        GIDSignIn.sharedInstance.signIn(with: configuration, presenting: viewController) { user, error in
            guard error == nil else {
                completion(.failure(Error.googleSignInError(error!)))
                return
            }
            
            guard advancedScopes.count == 0 else {
                self.requestAdvancedScopes(advancedScopes, presenting: viewController, completion: completion)
                return
            }
            
            guard let user = user else {
                completion(.failure(Error.missingUser))
                return
            }
            
            self.getID(from: user, completion: completion)
        }
    }
    
    private func requestAdvancedScopes(
        _ scopes: [String],
        presenting viewController: UIViewController,
        completion: @escaping (Result<OAuthID, Swift.Error>) -> ()
    ) {
        GIDSignIn.sharedInstance.addScopes(scopes, presenting: viewController) { user, error in
            guard error == nil else {
                completion(.failure(Error.googleSignInError(error!)))
                return
            }
            
            guard let user = user else {
                completion(.failure(Error.missingUser))
                return
            }
            
            self.getID(from: user, completion: completion)
        }
    }
    
    private func getID(from user: GIDGoogleUser, completion: @escaping (Result<OAuthID, Swift.Error>) -> ()) {
        user.authentication.do(freshTokens: { authentication, error in
            guard error == nil else {
                completion(.failure(Error.googleSignInError(error!)))
                return
            }
            
            do {
                let id = try user.toOAuthID()
                completion(.success(id))
            } catch {
                completion(.failure(error))
            }
        })
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case googleSignInError(Swift.Error)
        
        case missingUser
    }
    
    enum Scope: String {
        case openID = "openid"
        case email = "email"
        case profile = "profile"
    }
}

// MARK: Extensions

extension Set where Element == GoogleOAuth.Scope {
    func contains(_ element: String) -> Bool {
        contains(where: { $0.rawValue == element })
    }
}
