//
//  Catch.swift
//  
//
//  Created by Julia Samol on 12.07.21.
//

import Foundation

func catchInternal<T>(block: () throws -> T) throws -> T {
    do {
        return try block()
    } catch {
        throw Zaturn.Error(error)
    }
}
