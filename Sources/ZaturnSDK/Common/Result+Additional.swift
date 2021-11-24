//
//  Result.swift
//  
//
//  Created by Julia Samol on 12.07.21.
//

import Foundation

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success(_):
            return true
        case .failure(_):
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    func get<T>(ifFailure completion: @escaping (Result<T, Failure>) -> ()) -> Success? {
        switch self {
        case let .success(value):
            return value
        case let .failure(error):
            completion(.failure(error))
            return nil
        }
    }
    
    func getError() -> Failure? {
        switch self {
        case .success(_):
            return nil
        case let .failure(error):
            return error
        }
    }
}

// MARK: Failure == Swift.Error

extension Result where Failure == Swift.Error {
    func mapOrCatch<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, Failure> {
        flatMap {
            do {
                return .success(try transform($0))
            } catch {
                return .failure(error)
            }
        }
    }
}
