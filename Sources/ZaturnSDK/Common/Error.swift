//
//  Error.swift
//  
//
//  Created by julia on 24.11.21.
//

import Foundation

func extractErrorsAndOffsets<T>(from results: [Result<T, Swift.Error>]) -> ([Int], [Swift.Error]) {
    let (offsets, errors) = results.enumerated()
        .map { (offset, result) in (offset, result.getError()) }
        .filter { (_, error) in error != nil }
        .unzip()
    
    return (offsets, errors.compactMap({ $0 }))
}
