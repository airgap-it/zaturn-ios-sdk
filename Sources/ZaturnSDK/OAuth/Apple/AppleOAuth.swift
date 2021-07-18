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
    
    func signIn(usingNonce nonce: String, completion: @escaping (Result<String, Swift.Error>) -> ()) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.nonce = nonce
        
        let delegate = createDelegate(completingWith: completion)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate
        authorizationController.performRequests()
    }
    
    private func createDelegate(completingWith completion: @escaping (Result<String, Swift.Error>) -> ()) -> AppleOAuthDelegate {
        let delegateID = UUID().uuidString
        let delegate = AppleOAuthDelegate { [weak self] result in
            do {
                defer {
                    self?.delegates.removeValue(forKey: delegateID)
                }
                
                switch result {
                case let .success(appleIDCredential):
                    guard let identityToken = appleIDCredential?.identityToken else {
                        throw Error.missingToken
                    }
                    guard let identityToken = String(data: identityToken, encoding: .utf8) else {
                        throw Error.tokenConversionFailed
                    }
                    completion(.success(identityToken))
                case let .failure(error):
                    throw error
                }
                
            } catch {
                completion(.failure(error))
            }
        }
        delegates[delegateID] = delegate
        
        return delegate
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case missingToken
        case tokenConversionFailed
    }
}
