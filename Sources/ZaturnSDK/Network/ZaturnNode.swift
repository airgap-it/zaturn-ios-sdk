//
//  ZaturnNode.swift
//  
//
//  Created by Julia Samol on 12.07.21.
//

import Foundation

struct ZaturnNode {
    let id: String
    private let http: HTTP
    
    init(id: String, http: HTTP) {
        self.id = id
        self.http = http
    }
    
    func publicKey(completion: @escaping (Result<PublicKey, Swift.Error>) -> ()) {
        http.get(at: "/public_key") { (result: Result<GetPublicKeyResponse, Swift.Error>) in
            guard let response = result.get(ifFailure: completion) else { return }
            let publicKey = response.publicKey
            
            completion(.success(publicKey))
        }
    }
    
    func store(recoveryParts parts: [[UInt8]], forID id: String, authorizedWith token: String, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        parts.forEachAsync(body: { part, offset, partCompletion in
            store(recoveryPart: part, forID: id, withOffset: offset, authroizedWith: token, completion: partCompletion)
        }, completion: { results in
            guard results.allSatisfy({ $0.isSuccess }) else {
                completion(.failure(self.getNodeError(from: results)))
                return
            }
            
            completion(.success(()))
        })
    }
    
    private func store(recoveryPart part: [UInt8], forID id: String, withOffset offset: Int, authroizedWith token: String, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        http.post(
            at: "/storage/\(id)-\(offset)",
            body: StoreRecoveryPartRequest(data: part),
            headers: [.authorization(token)]
        ) { (result: Result<StoreRecoveryPartResponse, Swift.Error>) in
            completion(result.map { _ in () })
        }
    }
    
    func check(numberOfRecoveryParts partsCount: Int, forID id: String, authorizedWith token: String, completion: @escaping ([Bool]) -> ()) {
        Array((0..<partsCount)).forEachAsync(body: { offset, partCompletion in
            check(forID: id, withOffset: offset, authorizedWith: token, completion: partCompletion)
        }, completion: completion)
    }
    
    private func check(forID id: String, withOffset offset: Int, authorizedWith token: String, completion: @escaping (Bool) -> ()) {
        http.head(
            at: "/storage/\(id)-\(offset)",
            headers: [.authorization(token)]
        ) { (result: Result<CheckRecoveryPartResponse, Swift.Error>) in
            completion(result.isSuccess)
        }
    }
    
    func retrieve(numberOfRecoveryParts partsCount: Int, forID id: String, authorizedWith token: String, completion: @escaping (Result<[[UInt8]], Swift.Error>) -> ()) {
        Array((0..<partsCount)).forEachAsync(body: { offset, partCompletion in
            retrieveRecoveryPart(forID: id, withOffset: offset, authorizedWith: token, completion: partCompletion)
        }, completion: { results in
            guard results.allSatisfy({ $0.isSuccess }) else {
                completion(.failure(self.getNodeError(from: results)))
                return
            }
            
            let parts = results.compactMap { try? $0.get() }
            completion(.success(parts))
        })
    }
    
    private func retrieveRecoveryPart(forID id: String, withOffset offset: Int, authorizedWith token: String, completion: @escaping (Result<[UInt8], Swift.Error>) -> ()) {
        http.get(
            at: "/storage/\(id)-\(offset)",
            headers: [.authorization(token)]
        ) { (result: Result<RetrieveRecoveryPartResponse, Swift.Error>) in
            guard let response = result.get(ifFailure: completion) else { return }
            let part = response.data
            
            completion(.success(part))
        }
    }
    
    private func getNodeError<T>(from results: [Result<T, Swift.Error>]) -> Error {
        let (offsets, errors) = results.enumerated()
            .map { (offset, result) in (offset, result.getError()) }
            .filter { (_, error) in error != nil }
            .unzip()
        
        return Error.nodeFailure(offsets, causedBy: errors.compactMap { $0 })
    }
    
    // MARK: Type
    
    enum Error: Swift.Error {
        case nodeFailure([Int], causedBy: [Swift.Error])
    }
}
