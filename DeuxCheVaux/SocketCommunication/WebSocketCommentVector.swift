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
fileprivate let SubProtocol: String = "msg.nicovideo.jp#json"
fileprivate let Ticket: String = "ticket"
fileprivate let Watch: String = "watch"
fileprivate let GetPostkey: String = "getpostkey"
fileprivate let Postkey = "postkey"
fileprivate let StartAfter: UInt64 = 1000 * 1000 * 1000
fileprivate let Minute: DispatchTimeInterval = DispatchTimeInterval.seconds(60)
fileprivate let HalfSecond: DispatchTimeInterval = DispatchTimeInterval.milliseconds(500)
fileprivate let DefaultLeeway: DispatchTimeInterval = DispatchTimeInterval.milliseconds(50)
internal let heartbeatFormat: String = "https://watch.live.nicovideo.jp/api/heartbeat?v="
internal let PostCommentURLPrefix: String = "https://api.cas.nicovideo.jp/v1/services/live/programs/"
internal let PostCommentURLSuffix: String = "comments"

fileprivate let MessageSeparators: CharacterSet = CharacterSet(charactersIn: "{\"} :")

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

public struct CommentRequest: Codable {
	let thread: ThreadRequest
}// end struct CommentRequest

struct CommentBody: Codable {
	let message: String
	let mail: String?
	let vpos: String
}// end RequestBody

public struct ThreadInfo: Codable {
	let resultcode: Int
	let thread: UInt64
	let last_res: Int
	let ticket: String
	let revision: Int
	let server_time: TimeInterval
}// end struct ThreadInfo

struct ThreadResult: Codable {
	let thread: ThreadInfo
}// end struct ThreadResult

public struct ChatElements: Codable {
	public let thread: UInt64
	public let vpos: TimeInterval
	public let no: Int
	public let user_id: String
	public let content: String
	public let date: TimeInterval
	public let date_usec: TimeInterval
	public let premium: Int?
	public let mail: String?
	public let anonymity: Int?
	public let score: Int?
	public let origin: String?
	public let locale: UserLanguage?
}// end struct ChatElement

struct ChatResult: Codable {
	let chat: ChatElements
}// end struct ChatResult

fileprivate enum ElementType: String {
	case thread
	case type
	case chat
	case chat_result
}// end enum elementName

public let Arena: String = "Arena"
internal let CommunityChannelPrefix = "c"

public protocol WebSocketCommentVectorDelegate: class  {
	func commentVector (commentVector vector: WebSocketCommentVector, didRecieveComment comment: ChatElements)
}// end protocol WebSocketCommentVectorDelegate

public final class WebSocketCommentVector: NSObject {
		// MARK: Class variables
		// MARK: - Class methods
		// MARK: - Properties
	public let url: URL
	public let roomLabel: String
	public private(set) weak var runLoop: RunLoop?
	public weak var delegate: WebSocketCommentVectorDelegate?

		// MARK: - Member variables
		// MARK: - Constructor/Destructor
		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Internal methods
		// MARK: - Private methods
		// MARK: - Delegates
}// end WebSocketCommentVector
