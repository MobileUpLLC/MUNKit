//
//  Logger.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 13.05.2025.
//

import munkit
import os

public struct Logger: MUNLoggable {
    public init() {}

    public func log(type: OSLogType, _ message: String) {
        logger.log(level: type, "\(message)")
    }

    private let logger = os.Logger(subsystem: "MUNKit", category: "general")
}
