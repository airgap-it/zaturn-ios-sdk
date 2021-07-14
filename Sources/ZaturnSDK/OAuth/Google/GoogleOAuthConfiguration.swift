//
//  GoogleOAuthConfiguration.swift
//  
//
//  Created by Julia Samol on 14.07.21.
//

import Foundation
import UIKit

public struct GoogleOAuthConfiguration {
    let clientID: String
    let serverClientID: String
    weak var viewController: UIViewController?
    
    public init(clientID: String, serverClientID: String, viewController: UIViewController) {
        self.clientID = clientID
        self.serverClientID = serverClientID
        self.viewController = viewController
    }
}
