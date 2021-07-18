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
    
    private init() {}
    
    func signIn(
        withClientID clientID: String,
        andServerClientID serverClientID: String,
        usingNonce nonce: String,
        preseting viewController: UIViewController,
        completion: @escaping (Result<String, Swift.Error>) -> ()
    ) {
        let configuration = GIDConfiguration(clientID: clientID, serverClientID: serverClientID, hostedDomain: nil, openIDRealm: nil, nonce: nonce)
        GIDSignIn.sharedInstance.signIn(with: configuration, presenting: viewController) { user, error in
            guard error == nil else {
                completion(.failure(Error.googleSignInError(error!)))
                return
            }
            
            guard let user = user else {
                completion(.failure(Error.missingUser))
                return
            }

            user.authentication.do(freshTokens: { authentication, error in
                guard error == nil else {
                    completion(.failure(Error.googleSignInError(error!)))
                    return
                }
                
                guard let idToken = authentication?.idToken else {
                    completion(.failure(Error.missingIDToken))
                    return
                }
                
                completion(.success(idToken))
            })
        }
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case googleSignInError(Swift.Error)
        
        case missingUser
        case missingIDToken
    }
}
