//
//  SSKRSecretSharing.swift
//  
//
//  Created by Julia Samol on 09.07.21.
//

import Foundation

struct SSKRSecretSharing: SecretSharing {   
    private static let maxSecretSize: Int = Int(UInt8.max)
    
    private static let minGroups: Int = 1
    private static let maxGroups: Int = 16
    
    private let shamir: Shamir
    
    init(shamir: Shamir = .init()) {
        self.shamir = shamir
    }
    
    func split(_ secret: [UInt8], into groups: [SecretSharingGroup], withThreshold threshold: Int) throws -> [[[UInt8]]] {
        guard secret.count <= SSKRSecretSharing.maxSecretSize else {
            throw Error.invalidSecretSize
        }
        
        guard (SSKRSecretSharing.minGroups...SSKRSecretSharing.maxGroups).contains(groups.count) else {
            throw Error.unsupportedGroupSize
        }
        
        guard threshold <= groups.count else {
            throw Error.invalidGroupThreshold
        }
        
        do {
            let identifier = UInt16.random(in: UInt16.min...UInt16.max)
            let shards = try shamir.split(secret, intoParts: groups.count, withThreshold: threshold)
            
            return try shards.enumerated().map { (index, shard) in
                let group = groups[index]
                let members = group.members
                let memberThreshold = group.memberThreshold
                
                return GroupShard(
                    identifier: identifier,
                    groupThreshold: threshold,
                    groupCount: groups.count,
                    groupIndex: index,
                    memberThreshold: memberThreshold,
                    members: try split(shard, intoMembers: members, withThreshold: memberThreshold)
                ).serialized()
            }
        } catch {
            throw Error.shamirError(error)
        }
    }
    
    func join(_ parts: [[[UInt8]]]) throws -> [UInt8] {
        let shards: [[UInt8]] = try parts.compactMap {
            guard let group = try GroupShard(from: $0) else {
                return nil
            }
            
            let members = group.members.sorted(by: { $0.memberIndex < $1.memberIndex }).map { $0.shareValue }
            return try shamir.join(members)
        }
        
        return try shamir.join(shards)
    }
    
    private func split(_ secret: [UInt8], intoMembers members: Int, withThreshold threshold: Int) throws -> [MemberShard] {
        let shares = try shamir.split(secret, intoParts: members, withThreshold: threshold)
        return shares.enumerated().map { (index, share) in MemberShard(memberIndex: index, shareValue: share) }
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case invalidSecretSize
        case unsupportedGroupSize
        case invalidGroupThreshold
        case shamirError(Swift.Error)
        case groupShardsMismatch
        case invalidReservedBit
    }
    
    struct MemberShard {
        let memberIndex: Int
        let shareValue: [UInt8]
        
        init(memberIndex: Int, shareValue: [UInt8]) {
            self.memberIndex = memberIndex
            self.shareValue = shareValue
        }
        
        init(from bytes: [UInt8]) {
            self.memberIndex = Int(bytes[0] & 0xf)
            self.shareValue = Array(bytes[1...])
        }
        
        func serialized() -> [UInt8] {
            let memberIndexMasked = memberIndex & 0xf
            return [UInt8(memberIndexMasked)] + shareValue
        }
    }
    
    struct GroupShard {
        let identifier: UInt16
        let groupThreshold: Int
        let groupCount: Int
        let groupIndex: Int
        let memberThreshold: Int
        let members: [MemberShard]
        
        init(identifier: UInt16, groupThreshold: Int, groupCount: Int, groupIndex: Int, memberThreshold: Int, members: [MemberShard]) {
            self.identifier = identifier
            self.groupThreshold = groupThreshold
            self.groupCount = groupCount
            self.groupIndex = groupIndex
            self.memberThreshold = memberThreshold
            self.members = members
        }
        
        init?(from bytes: [[UInt8]]) throws {
            guard let other = try bytes.map({
                let groupThreshold = (Int($0[2]) >> 4) + 1
                let groupCount = Int($0[2] & 0xf) + 1
                guard groupThreshold <= groupCount else {
                    throw Error.invalidGroupThreshold
                }
                
                let reserved = Int($0[4]) >> 4
                guard reserved == 0 else {
                    throw Error.invalidReservedBit
                }
                
                let identifier = (UInt16($0[0]) << 8) | UInt16($0[1])
                let groupIndex = Int($0[3]) >> 4
                let memberThreshold = Int($0[3] & 0xf) + 1
                let member = MemberShard(from: Array($0[4...]))
                
                return GroupShard(identifier: identifier, groupThreshold: groupThreshold, groupCount: groupCount, groupIndex: groupIndex, memberThreshold: memberThreshold, members: [member])
            }).flatten() else {
                return nil
            }
            
            self.init(from: other)
        }
        
        init(from other: GroupShard) {
            self.identifier = other.identifier
            self.groupThreshold = other.groupThreshold
            self.groupCount = other.groupCount
            self.groupIndex = other.groupIndex
            self.memberThreshold = other.memberThreshold
            self.members = other.members
        }
        
        func serialized() -> [[UInt8]] {
            members.map { member in
                let identifierMasked = identifier & 0xffff
                let groupThresholdMasked = (groupThreshold - 1) & 0xf
                let groupCountMasked = (groupCount - 1) & 0xf
                let groupIndexMasked = groupIndex & 0xf
                let memberThresholdMasked = (memberThreshold - 1) & 0xf
                let memberSerialized = member.serialized()
                
                return [
                    UInt8(identifierMasked >> 8),
                    UInt8(identifierMasked & 0xff),
                    UInt8((groupThresholdMasked << 4) | groupCountMasked),
                    UInt8((groupIndexMasked << 4) | memberThresholdMasked),
                ] + memberSerialized
            }
            
        }
        
        func matches(_ other: GroupShard) -> Bool {
            other.identifier == identifier && other.groupThreshold == groupThreshold && other.groupCount == groupCount && other.groupIndex == groupIndex && other.memberThreshold == memberThreshold
        }
        
        func copy(identifier: UInt16? = nil, groupThreshold: Int? = nil, groupCount: Int? = nil, groupIndex: Int? = nil, memberThreshold: Int? = nil, members: [MemberShard]? = nil) -> GroupShard {
            GroupShard(
                identifier: identifier ?? self.identifier,
                groupThreshold: groupThreshold ?? self.groupThreshold,
                groupCount: groupCount ?? self.groupCount,
                groupIndex: groupIndex ?? self.groupIndex,
                memberThreshold: memberThreshold ?? self.memberThreshold,
                members: members ?? self.members
            )
        }
    }
}

// MARK: Extensions

private extension Array where Element == SSKRSecretSharing.GroupShard {
    func flatten() throws -> SSKRSecretSharing.GroupShard? {
        guard let first = first else {
            return nil
        }
        
        return try self[1...].reduce(first) { (acc, next) in
            guard next.matches(acc) else {
                throw SSKRSecretSharing.Error.groupShardsMismatch
            }
            
            return acc.copy(members: acc.members + next.members)
        }
    }
}
