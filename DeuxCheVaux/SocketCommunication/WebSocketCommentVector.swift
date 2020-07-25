//
//  WebSocketCommentVector.swift
//  Charleston
//
//  Created by Я Чайка on 2020/07/15.
//  Copyright © 2020 Чайка. All rights reserved.
//

import Cocoa
import SwiftWebSocket

fileprivate let ThreadVersion: Int = 20061206
fileprivate let ServiceName: String = "LIVE"
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

public struct ThreadRequest: Codable {
	let version: Int
	let thread: String
	let service: String
	let user_id: String
	let res_from: Int
	let with_global: Int
	let scores: Int
	let nicoru: Int

	init(thread: String, uid: String, resFrom: Int) {
		version = ThreadVersion
		self.thread = thread
		self.service = ServiceName
		self.user_id = uid
		self.res_from = resFrom
		self.with_global = 1
		self.scores = 1
		self.nicoru = 1
	}
}// end struct ThreadRequest

public final class WebSocketCommentVector: NSObject {
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
