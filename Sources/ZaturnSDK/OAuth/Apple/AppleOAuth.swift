//
//  AppleOAuth.swift
//  
//
//  Created by Julia Samol on 14.07.21.
//

import Foundation
import AuthenticationServices

class AppleOAuth {
    static let shared: AppleOAuth = .init()
    
    private var delegates: [String: AppleOAuthDelegate] = [:]
    
    private init() {}
    
    func signIn(
        with requestedOperation: ASAuthorization.OpenIDOperation?,
        for requestedScopes: [ASAuthorization.Scope],
        usingNonce nonce: String,
        completion: @escaping (Result<OAuthID, Swift.Error>) -> ()
    ) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        let request = appleIDProvider.createRequest()
        if let requestedOperation = requestedOperation {
            request.requestedOperation = requestedOperation
        }
        request.requestedScopes = requestedScopes
        request.nonce = nonce
        
        let delegate = createDelegate(completingWith: completion)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate
        authorizationController.performRequests()
    }
    
    private func createDelegate(completingWith completion: @escaping (Result<OAuthID, Swift.Error>) -> ()) -> AppleOAuthDelegate {
        let delegateID = UUID().uuidString
        let delegate = AppleOAuthDelegate { [weak self] result in
            do {
                defer {
                    self?.delegates.removeValue(forKey: delegateID)
                }
                
                guard let id = try result.get()?.toOAuthID() else {
                    throw Error.missingAppleID
                }
                 
                completion(.success(id))
            } catch {
                completion(.failure(error))
            }
        }
        delegates[delegateID] = delegate
        
        return delegate
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case missingAppleID
    }
}
