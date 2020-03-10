//
// Copyright © 2019 Dmitry Rybakov. All rights reserved.
    

import Foundation

// Mark:- String constants
extension String {
    static let sharedGroupName = "group.com.application.test"
    static let broadcastRoomIDKey = "broadcastRoomID"
}

extension String {
    static var broadcastRandomRoomID: String {
        "broadcast_\(Int.random(in: 1 ... 1000))"
    }
}
