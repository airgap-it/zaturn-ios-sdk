//
//  AppleOAuthDelegate.swift
//  
//
//  Created by Julia Samol on 14.07.21.
//

import Foundation
import AuthenticationServices

class AppleOAuthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorizationAppleIDCredential?, Error>) -> ()
    
    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential?, Error>) -> ()) {
        self.completion = completion
    }
    
    // MARK: ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            completion(.success(appleIDCredential))
        default:
            completion(.success(nil))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    // MARK: ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: { $0.isKeyWindow })
        
        return keyWindow!
    }
}
