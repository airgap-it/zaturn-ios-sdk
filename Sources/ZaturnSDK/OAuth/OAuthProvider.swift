//
//  OAuthProvider.swift
//  
//
//  Created by Julia Samol on 14.07.21.
//

import Foundation

public enum OAuthProvider {
    case apple(AppleOAuthConfiguration = .init())
    case google(GoogleOAuthConfiguration)
}
