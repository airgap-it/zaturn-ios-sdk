//
//  Array.swift
//  
//
//  Created by Julia Samol on 12.07.21.
//

import Foundation

extension Array {
    func unzip<T, U>() -> (Array<T>, Array<U>) where Element == (T, U) {
        var unzipped = ([T](), [U]())
        
        unzipped.0.reserveCapacity(count)
        unzipped.1.reserveCapacity(count)
        
        return reduce(into: unzipped) { acc, pair in
            acc.0.append(pair.0)
            acc.1.append(pair.1)
        }
    }
    
    func count(matching predicate: (Element) -> Bool) -> Int {
        reduce(0) { (acc, next) in acc + (predicate(next) ? 1 : 0) }
    }
    
    func forEachAsync<T>(
        with group: DispatchGroup = .init(),
        body: @escaping (Element, @escaping (T) -> ()) -> (),
        completion: @escaping ([T]) -> ()
    ) {
        forEachAsync(with: group, body: { element, _, elementCompletion in body(element, elementCompletion) }, completion: completion)
    }
    
    func forEachAsync<T>(
        with group: DispatchGroup = .init(),
        body: @escaping (Element, Int, @escaping (T) -> ()) -> (),
        completion: @escaping ([T]) -> ()
    ) {
        var results = [T?](repeating: nil, count: count)
        let queue = DispatchQueue(label: "ch.papers.zaturn-sdk", qos: .default, attributes: [], target: .global(qos: .default))
        
        for item in self.enumerated() {
            group.enter()
            body(item.element, item.offset) { value in
                queue.async {
                    results[item.offset] = value
                    group.leave()
                }
            }
        }
        
        group.notify(qos: .default, flags: [], queue: queue) {
            completion(results.compactMap { $0 })
        }
    }
}
