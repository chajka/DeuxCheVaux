//
//  WebSocketCommentVector.swift
//  Charleston
//
//  Created by Я Чайка on 2020/07/15.
//  Copyright © 2020 Чайка. All rights reserved.
//

import Cocoa
import SwiftWebSocket

final class WebSocketCommentVector: NSObject {
internal let heartbeatFormat: String = "https://watch.live.nicovideo.jp/api/heartbeat?v="
public typealias heartbeatCallback = (_ commentCount: Int, _ watcherCount: Int, _ ticket: String) -> Void

internal enum HeartbeatElement: String {
	case watch = "watchCount"
	case comment = "commentCount"
	case ticket = "ticket"
	
	static func ~= (lhs: HeartbeatElement, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=
	static func == (lhs: HeartbeatElement, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ==
}// end enum HeartbeatElement

		// MARK: Class variables
		// MARK: - Class methods
		// MARK: - Properties
		// MARK: - Member variables
		// MARK: - Constructor/Destructor
		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Internal methods
		// MARK: - Private methods
		// MARK: - Delegates
}// end WebSocketCommentVector
