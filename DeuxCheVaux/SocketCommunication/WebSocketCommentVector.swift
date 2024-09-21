//
//  WebSocketCommentVector.swift
//  Charleston
//
//  Created by Я Чайка on 2020/07/15.
//  Copyright © 2020 Чайка. All rights reserved.
//

import Cocoa
import Starscream

fileprivate let ThreadVersion: String = "20061206"
fileprivate let ServiceName: String = "LIVE"
fileprivate let SubProtocolHeader: String = "Sec-WebSocket-Protocol"
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
	let version: String
	let thread: String
	let service: String
	let user_id: String
	let res_from: Int
	let with_global: Int
	let nicoru: Int

	init(thread: String, uid: String, resFrom: Int) {
		version = ThreadVersion
		self.thread = thread
		self.service = ServiceName
		self.user_id = uid
		self.res_from = resFrom
		self.with_global = 1
		self.nicoru = 1
	}
}// end struct ThreadRequest

public struct CommentRequest: Codable {
	let thread: ThreadRequest
}// end struct CommentRequest

struct CommentBody: Codable {
	let message: String
	let command: String?
	let vpos: String
}// end RequestBody

public struct ThreadInfo: Codable {
	let resultcode: Int
	let thread: String
	let last_res: Int?
	let ticket: String
	let revision: Int
	let server_time: TimeInterval
}// end struct ThreadInfo

struct ThreadResult: Codable {
	let thread: ThreadInfo
}// end struct ThreadResult

fileprivate enum ElementType: String {
	case thread
	case type
	case chat
	case chat_result
}// end enum elementName

public let Arena: String = "\u{30A2}\u{30EA}\u{30FC}\u{30CA}"
internal let CommunityChannelPrefix = "c"

public protocol WebSocketCommentVectorDelegate: AnyObject  {
	func commentVector (commentVector vector: WebSocketCommentVector, didRecieveComment comment: ChatElements, lastPastComment last: Bool)
}// end protocol WebSocketCommentVectorDelegate

public final class WebSocketCommentVector: NSObject, WebSocketDelegate {
		// MARK: Class variables
		// MARK: - Class methods
		// MARK: - Properties
	public let url: URL
	public var lastRes: Int!
	public let roomLabel: String
	public private(set) weak var runLoop: RunLoop?
	public weak var delegate: WebSocketCommentVectorDelegate?

		// MARK: - Member variables
	private let socket: WebSocket
	private let thread: String
	private let program: String
	private let userIdentifier: String
	private let userLanguage: UserLanguage
	private var ticket: String!
	private let baseTime: Date
	private var history: Int = 0
	private var connecting: Bool = false
	private let background: DispatchQueue = DispatchQueue(label: "tv.from.chajka.Charleston", qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 0), attributes: DispatchQueue.Attributes.concurrent)
	private var keepaliveTimer: DispatchSourceTimer? = nil

		// MARK: - Constructor/Destructor
	public init (url: URL, thread: String, program: String, uid: String, lang: UserLanguage, baseTime: Date, room: String) {
		self.url = url
		self.thread = thread
		self.program = program
		userIdentifier = uid
		userLanguage = lang
		self.baseTime = baseTime
		runLoop = DeuxCheVaux.shared.runLoop
		let roomPrefix: Substring = room.prefix(1)
		let prefix = String(roomPrefix)
		roomLabel = prefix == CommunityChannelPrefix ? Arena : room
		var request: URLRequest = URLRequest(url: self.url)
		do {
			request.addValue(try TokenManager.shared.getUserSession(for: uid), forHTTPHeaderField: NicoSessionHeaderKey)
		} catch let error {
			print("Comment Vector User session failed \(error.localizedDescription)")
		}
		let userAgent: String = DeuxCheVaux.shared.userAgent
		request.addValue(userAgent, forHTTPHeaderField: UserAgentKey)
		request.addValue(SubProtocol, forHTTPHeaderField: SubProtocolHeader)
		socket = WebSocket(request: request)
		super.init()
		socket.delegate = self
	}// end init

	deinit {
		cleanupKeepAliveTimer()
	}// end deinit

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
	public func open (history: Int) {
		self.history = history
		connecting = true
		socket.connect()
		keepaliveTimer = setupKeepAliveTimer()
		keepaliveTimer?.resume()
	}// end open

	public func close () {
		connecting = false
		cleanupKeepAliveTimer()
		socket.disconnect()
	}// end close

		// MARK: - Internal methods
		// MARK: - Private methods
	private func setupKeepAliveTimer () -> DispatchSourceTimer {
		let keepAlive: DispatchSourceTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.strict, queue: background)
		keepAlive.setEventHandler() { [weak self] in
			guard let weakSelf = self else { return }
			weakSelf.socket.write(ping: "{\"content\":\"rs:0\"}".data(using: .utf8)!)
			weakSelf.socket.write(ping: "{\"content\":\"ps:0\"}".data(using: .utf8)!)
			weakSelf.socket.write(string: "")
			weakSelf.socket.write(ping: "{\"content\":\"pf:0\"}".data(using: .utf8)!)
			weakSelf.socket.write(ping: "{\"content\":\"rf:0\"}".data(using: .utf8)!)
		}// end event handler closure

		keepAlive.schedule(deadline: DispatchTime(uptimeNanoseconds: StartAfter), repeating: Minute, leeway: DefaultLeeway)

		return keepAlive
	}// end setupKeepAliveTimer

	private func cleanupKeepAliveTimer () {
		if let timer: DispatchSourceTimer = keepaliveTimer {
			if !timer.isCancelled {
				timer.suspend()
				timer.cancel()
			}// end if timer is worked
		}// end optional binding check of keep alive timer
	}// end cleanupKeepAliveTimer

	private func processMessage (message: String) {
		let text: NSString = message as NSString
		guard let json: Data = (message as String).data(using: String.Encoding.utf8) else { return }
		let decoder: JSONDecoder = JSONDecoder()
		let messageType: String? = text.components(separatedBy: MessageSeparators).compactMap{ $0 != "" ? $0 : nil }.first
		if let messageType: String = messageType, let type: ElementType = ElementType(rawValue: messageType) {
			switch type {
			case .thread:
				do {
					let info: ThreadResult = try decoder.decode(ThreadResult.self, from: json)
					ticket = info.thread.ticket
					if let last_res: Int = info.thread.last_res {
						lastRes = last_res
					} else {
						lastRes = 0
					}// end optional binding check for last_res
				} catch let error {
					Swift.print("Error: \(error.localizedDescription),\nDroped \(message)")
				}// end do try - catch decode json
			case .chat:
				do {
					let chat: ChatResult = try decoder.decode(ChatResult.self, from: json)
					let last: Bool = lastRes == chat.chat.no
					delegate?.commentVector(commentVector: self, didRecieveComment: chat.chat, lastPastComment: last)
				} catch let error {
					Swift.print("Error: \(error.localizedDescription),\nDroped \(message)")
				}
			case .chat_result:
				break
			case .type:
				break
			}// end switch case by message type
		} else {
			Swift.print("Droped \(message)")
		}// end optional binding check of known element or not.
	}// end processMessage

		// MARK: - Delegates
	public func didReceive (event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
		switch event {
		case .connected (_):
			let threadData: ThreadRequest = ThreadRequest(thread: thread, uid: userIdentifier, resFrom: history)
			let commentRequest: CommentRequest = CommentRequest(thread: threadData)
			do {
				let json: Data = try JSONEncoder().encode(commentRequest)
				if let request: String = String(data: json, encoding: .utf8) {
					socket.write(string: "\(request)")
					history = 0
				}
			} catch let error {
				print(error.localizedDescription)
			}
			break
		case .disconnected (_, _):
			if (connecting) {
				socket.connect()
			}// end if connectiing
			break
		case .text (let text):
			processMessage(message: text)
			break
		case .binary (_):
			break
		case .ping (_):
			break
		case .pong (_):
			break
		case .viabilityChanged (_):
			break
		case .reconnectSuggested (_):
			break
		case .cancelled:
			if (connecting) {
				socket.connect()
			}// end if connectiing
			break
		case .error (let error):
			print("Websocket error: \(String(describing: error))")
			break
		case .peerClosed:
			break
		}// end switch by event

	}// end didReceive
}// end WebSocketCommentVector
