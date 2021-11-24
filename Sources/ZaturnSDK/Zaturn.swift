import Foundation

public class Zaturn {
    private let nodes: [ZaturnNode]
    private let oAuth: OAuth
    private let crypto: Crypto
    private let secretSharing: SecretSharing
    private let shareConfiguration: ShareConfiguration
    
    public convenience init(nodes: [URL], configuredWith configuration: Configuration = .init()) throws {
        let nodes: [ZaturnNode] = try nodes.map {
            let urlString = "\($0.absoluteString)/\(Defaults.api)"
            guard let url = URL(string: urlString) else {
                throw Error.invalidURL(urlString)
            }
            let http = HTTP(baseURL: url)
            
            return ZaturnNode(id: $0.absoluteString, http: http)
        }
        let oAuth = OAuth()
        let crypto = SodiumCrypto()
        
        let secretSharing = SSKRSecretSharing()
        let shareConfiguration = ShareConfiguration(
            groups: min(nodes.count, Defaults.minGroups),
            groupThreshold: configuration.groupThreshold ?? min((nodes.count / 2) + 1, Defaults.minGroupThreshold),
            groupMembers: configuration.groupMembers ?? Defaults.minGroupMembers,
            groupMemberThreshold: configuration.groupMemberThreshold ?? Defaults.minGroupMemberThreshold
        )

        try shareConfiguration.validate()
        
        self.init(nodes: nodes, oAuth: oAuth, crypto: crypto, secretSharing: secretSharing, shareConfiguration: shareConfiguration)
    }
    
    init(nodes: [ZaturnNode], oAuth: OAuth, crypto: Crypto, secretSharing: SecretSharing, shareConfiguration: ShareConfiguration) {
        self.nodes = nodes
        self.oAuth = oAuth
        self.crypto = crypto
        self.secretSharing = secretSharing
        self.shareConfiguration = shareConfiguration
    }
    
    public func getNonce() throws -> String {
        try catchInternal {
            try getKeyPair().publicKey.encodeBase64()
        }
    }
    
    public func getOAuthToken(from provider: OAuthProvider, completion: @escaping (Result<OAuthID, Swift.Error>) -> ()) {
        do {
            oAuth.signIn(nonce: try getNonce(), using: provider) { result in
                completion(result.mapError { Error($0) })
            }
        } catch {
            completion(.failure(Error(error)))
        }
    }
    
    public func setupRecovery(forSecret secret: [UInt8], usingID id: String, authorizedWith token: String, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        do {
            let parts = try splitSecret(secret)
            storeRecoveryParts(parts, forID: id, authorizedWith: token) { result in
                completion(result.mapError { Error($0) })
            }
        } catch {
            completion(.failure(Error(error)))
        }
    }
    
    public func checkRecovery(forID id: String, authroizedWith token: String, completion: @escaping (Bool) -> ()) {
        checkRecoveryParts(forID: id, authorizedWith: token) { available in
            let groups = available
                .map { groupMembers in groupMembers.count(matching: { $0 }) }
                .count { $0 >= self.shareConfiguration.groupMemberThreshold }
            
            completion(groups >= self.shareConfiguration.groupThreshold)
        }
    }
    
    public func recover(forID id: String, authorizedWith token: String, completion: @escaping (Result<[UInt8], Swift.Error>) -> ()) {
        retrieveRecoveryParts(forID: id, authorizedWith: token) { parts in
            guard self.groupThresholdMet(for: parts) else {
                completion(.failure(self.getGroupThresholdNotMetError(from: parts)))
                return
            }
            
            do {
                let secret = try self.restoreSecret(from: parts)
                completion(.success(secret))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private var keyPair: KeyPair?
    private func getKeyPair() throws -> KeyPair {
        guard let keyPair = keyPair else {
            let newKeyPair = try crypto.keyPair()
            self.keyPair = newKeyPair
            
            return newKeyPair
        }
        
        return keyPair
    }
    
    private var sessionKeys: [String: SessionKey] = [:]
    private func getSessionKey(for node: ZaturnNode, completion: @escaping (Result<SessionKey, Swift.Error>) -> ()) {
        guard let sessionKey = sessionKeys[node.id] else {
            node.publicKey { result in
                guard let publicKey = result.get(ifFailure: completion) else { return }
                
                do {
                    let newSessionKey = try self.crypto.sessionKey(from: try self.getKeyPair().privateKey, and: publicKey)
                    self.sessionKeys[node.id] = newSessionKey
                    completion(.success(newSessionKey))
                } catch {
                    completion(.failure(error))
                }
            }
            return
        }
        
        completion(.success(sessionKey))
    }
    
    private func splitSecret(_ secret: [UInt8]) throws -> [[[UInt8]]] {
        try secretSharing.split(secret, into: (0..<shareConfiguration.groups).map { _ in
            SecretSharingGroup(members: shareConfiguration.groupMembers, memberThreshold: shareConfiguration.groupMemberThreshold)
        }, withThreshold: shareConfiguration.groupThreshold)
    }
    
    private func restoreSecret(from parts: [Result<[Result<[UInt8], Swift.Error>], Swift.Error>]) throws -> [UInt8] {
        let parts = parts.flatMapSuccess { $0.flatSuccess() }
        return try secretSharing.join(parts)
    }
    
    private func encryptParts(_ parts: [[UInt8]], for node: ZaturnNode, completion: @escaping (Result<[[UInt8]], Swift.Error>) -> ()) {
        getSessionKey(for: node) { result in
            guard let sessionKey = result.get(ifFailure: completion) else { return }
            
            do {
                let encrypted = try parts.map { try self.crypto.encrypt($0, with: sessionKey) }
                completion(.success(encrypted))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func decryptParts(_ parts: [Result<[UInt8], Swift.Error>], for node: ZaturnNode, completion: @escaping ([Result<[UInt8], Swift.Error>]) -> ()) {
        getSessionKey(for: node) { result in
            let decrypted: [Result<[UInt8], Swift.Error>] = parts.map { part in
                return part.mapOrCatch {
                    let sessionKey = try result.get()
                    return try self.crypto.decrypt($0, with: sessionKey)
                }
            }
            
            completion(decrypted)
        }
    }
    
    private func storeRecoveryParts(_ parts: [[[UInt8]]], forID id: String, authorizedWith token: String, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        Array(zip(nodes, parts)).forEachAsync(body: { nodeWithParts, singleCompletion in
            let (node, parts) = nodeWithParts
            self.encryptParts(parts, for: node) { result in
                guard let encrypted = result.get(ifFailure: singleCompletion) else { return }
                node.store(recoveryParts: encrypted, forID: id, authorizedWith: token, completion: singleCompletion)
            }
        }, completion: { (results: [Result<(), Swift.Error>]) in
            guard results.allSatisfy({ $0.isSuccess }) else {
                completion(.failure(self.getNodeError(from: results)))
                return
            }
            
            completion(.success(()))
        })
    }
    
    private func checkRecoveryParts(forID id: String, authorizedWith token: String, completion: @escaping ([[Bool]]) -> ()) {
        nodes.forEachAsync(body: { node, singleCompletion in
            node.check(numberOfRecoveryParts: self.shareConfiguration.groupMembers, forID: id, authorizedWith: token, completion: singleCompletion)
        }, completion: completion)
    }
    
    private func retrieveRecoveryParts(forID id: String, authorizedWith token: String, completion: @escaping ([Result<[Result<[UInt8], Swift.Error>], Swift.Error>]) -> ()) {
        nodes.forEachAsync(body: { node, singleCompletion in
            node.retrieve(numberOfRecoveryParts: self.shareConfiguration.groupMembers, forID: id, authorizedWith: token) { encrypted in
                self.decryptParts(encrypted, for: node) { decrypted in
                    guard self.groupMemberThresholdMet(for: decrypted) else {
                        singleCompletion(.failure(self.getMemberThresholdNotMetError(from: decrypted)))
                        return
                    }
                    singleCompletion(.success(decrypted))
                }
                
            }
        }, completion: completion)
    }
    
    private func groupThresholdMet(for parts: [Result<[Result<[UInt8], Swift.Error>], Swift.Error>]) -> Bool {
        parts.thresholdMet(shareConfiguration.groupThreshold)
    }
    
    private func groupMemberThresholdMet(for decrypted: [Result<[UInt8], Swift.Error>]) -> Bool {
        decrypted.thresholdMet(shareConfiguration.groupMemberThreshold)
    }
    
    private func getGroupThresholdNotMetError<T>(from results: [Result<T, Swift.Error>]) -> Swift.Error {
        let (offsets, errors) = extractErrorsAndOffsets(from: results)
        return Error.groupThresholdNotMet(offsets.map { nodes[$0].id }, causedBy: errors)
    }
    
    private func getMemberThresholdNotMetError<T>(from results: [Result<T, Swift.Error>]) -> Swift.Error {
        let (offsets, errors) = extractErrorsAndOffsets(from: results)
        return Error.memberThresholdNotMet(offsets, causedBy: errors)
    }
    
    private func getNodeError<T>(from results: [Result<T, Swift.Error>]) -> Swift.Error {
        let (offsets, errors) = extractErrorsAndOffsets(from: results)
        return Error.node(offsets.map { nodes[$0].id }, causedBy: errors)
    }
    
    // MARK: Types
    
    public struct Configuration {
        let groupThreshold: Int?
        let groupMembers: Int?
        let groupMemberThreshold: Int?
        
        public init(groupThreshold: Int? = nil, groupMembers: Int? = nil, groupMemberThreshold: Int? = nil) {
            self.groupThreshold = groupThreshold
            self.groupMembers = groupMembers
            self.groupMemberThreshold = groupMemberThreshold
        }
    }
    
    public enum Error: Swift.Error {
        case invalidURL(String)
        
        case groupThresholdExceeded
        case groupThresholdNotMet([String], causedBy: [Swift.Error])
        case memberThresholdExceeded
        case memberThresholdNotMet([Int], causedBy: [Swift.Error])
    
        case http(Int)
        case node([String], causedBy: [Swift.Error])
        case other(Swift.Error)
        
        init(_ error: Swift.Error) {
            guard let zaturnError = error as? Error else {
                switch error {
                case let HTTP.Error.http(code):
                    self = .http(code)
                default:
                    self = .other(error)
                }
                return
            }
            self = zaturnError
        }
    }
    
    struct ShareConfiguration {
        let groups: Int
        let groupThreshold: Int
        let groupMembers: Int
        let groupMemberThreshold: Int
        
        func validate() throws {
            guard groupThreshold <= groups else {
                throw Error.groupThresholdExceeded
            }
            guard groupMemberThreshold <= groupMembers else {
                throw Error.memberThresholdExceeded
            }
        }
    }
}

// MARK: Extensions

extension Array {
    func thresholdMet<T, E>(_ threshold: Int) -> Bool where Element == Result<T, E> {
        count(matching: { $0.isSuccess }) >= threshold
    }
}
