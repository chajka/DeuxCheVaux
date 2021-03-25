//
//  WebSocketCommentVector.swift
//  Charleston
//
//  Created by Я Чайка on 2020/07/15.
//  Copyright © 2020 Чайка. All rights reserved.
//

import Cocoa
import SwiftWebSocket

fileprivate let ThreadVersion: String = "20061206"
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

public struct ChatElements: Codable {
	public let thread: String
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
	
	public static var logHeader: String {
		get {
			var message: String = String()

			message += "thread"
			message += ",vpos"
			message += ",no"
			message += ",user_id"
			message += ",content"
			message += ",date"
			message += ",date_usec"
			message += ",premium"
			message += ",mail"
			message += ",anonymity"
			message += ",score"
			message += ",origin"
			message += ",locale"

			return message
		}// end get
	}// end computed property log header

	public var logMessage: String {
		get {
			var message: String = String()

			message += "\(thread)"
			message += ",\(vpos)"
			message += ",\(no)"
			message += ",\(user_id)"
			message += ",\(content)"
			message += ",\(date)"
			message += ",\(date_usec)"
			message += ",\(String(describing: premium != nil ? premium! : 0))"
			message += ",\(mail ?? "")"
			message += ",\(anonymity ?? 0)"
			message += ",\(score ?? 0)"
			message += ",\(origin ?? "")"
			message += ",\(locale?.rawValue ?? UserLanguage.ja.rawValue)"

			return message
		}// end get
	}// end logmesage
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

public let Arena: String = "\u{30A2}\u{30EA}\u{30FC}\u{30CA}"
internal let CommunityChannelPrefix = "c"

public protocol WebSocketCommentVectorDelegate: class  {
	func commentVector (commentVector vector: WebSocketCommentVector, didRecieveComment comment: ChatElements, lastPastComment last: Bool)
}// end protocol WebSocketCommentVectorDelegate

public final class WebSocketCommentVector: NSObject {
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
	private let cookies: Array<HTTPCookie>
	private var ticket: String!
	private let baseTime: Date
	private let background: DispatchQueue = DispatchQueue(label: "tv.from.chajka.Charleston", qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 0), attributes: DispatchQueue.Attributes.concurrent)
	private var keepaliveTimer: DispatchSourceTimer? = nil

		// MARK: - Constructor/Destructor
	public init (url: URL, thread: String, program: String, uid: String, lang: UserLanguage, baseTime: Date, room: String, cookie: Array<HTTPCookie>) {
		self.url = url
		self.thread = thread
		self.program = program
		userIdentifier = uid
		userLanguage = lang
		cookies = cookie
		self.baseTime = baseTime
		runLoop = DeuxCheVaux.shared.runLoop
		let roomPrefix: Substring = room.prefix(1)
		let prefix = String(roomPrefix)
		roomLabel = prefix == CommunityChannelPrefix ? Arena : room
		var request: URLRequest = URLRequest(url: self.url)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookie)
		for cookie: HTTPCookie in cookies {
			if cookie.name == UserSessionName {
				request.addValue(cookie.value, forHTTPHeaderField: NicoSessionHeaderKey)
			}// end if found niconico user_session
		}// end foreach
		let userAgent: String = DeuxCheVaux.shared.userAgent
		request.addValue(userAgent, forHTTPHeaderField: UserAgentKey)
		if let runLoop: RunLoop = self.runLoop {
			socket = WebSocket(request: request, subProtocols: [SubProtocol], runLoop: runLoop)
		} else {
			socket = WebSocket(request: request, subProtocols: [SubProtocol])
		}
		socket.compression.on = true
		socket.allowSelfSignedSSL = true
	}// end init

	deinit {
		cleanupKeepAliveTimer()
	}// end deinit

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
	public func open (history: Int) {
		setupSocketEventHandler(history: history)
		socket.open()
		keepaliveTimer = setupKeepAliveTimer()
		keepaliveTimer?.resume()
	}// end open

	public func close () {
		cleanupKeepAliveTimer()
		socket.close()
	}// end close

	public func comment (comment: String, commands: Array<String>) {
		guard let baseURL: URL = URL(string: PostCommentURLPrefix) else { return }
		let postCommentURL = baseURL.appendingPathComponent(program, isDirectory: true).appendingPathComponent(PostCommentURLSuffix)
		let vpos: Int = -100 * Int(baseTime.timeIntervalSinceNow)
		let config = URLSessionConfiguration.default
		let session = URLSession(configuration: config)
		var request = URLRequest(url: postCommentURL)
		if !cookies.isEmpty {
			let cookiesForHeader = HTTPCookie.requestHeaderFields(with: cookies)
			request.allHTTPHeaderFields = cookiesForHeader
		}// end if have cookies
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		request.httpMethod = HTTPMethod.post.rawValue
		let mail: String? = commands.count > 0 ? commands.joined(separator: " ") : nil
		let body: CommentBody = CommentBody(message: comment, command: mail, vpos: String(vpos))
		if let json: Data = try? JSONEncoder().encode(body) {
			request.httpBody = json
			let task: URLSessionDataTask = session.dataTask(with: request)
			task.resume()
		}// end optional binding check for make json data
	}// end comment

	public func heartbeat (_ callback: @escaping heartbeatCallback) {
		guard let heartbeatURL = URL(string: (heartbeatFormat + program)) else { return }
		let config = URLSessionConfiguration.default
		let session = URLSession(configuration: config)
		var req = URLRequest(url: heartbeatURL)
		if !cookies.isEmpty {
			let cookiesForHeader = HTTPCookie.requestHeaderFields(with: cookies)
			req.allHTTPHeaderFields = cookiesForHeader
		}// end if have cookies
		
		let task: URLSessionDataTask = session.dataTask(with: req) { (dat, res, err) in
			guard let data = dat else { return }
			do {
				let heartbeat = try XMLDocument(data: data, options: XMLNode.Options.documentTidyXML)
				let heartbeatStatus = heartbeat.rootElement()?.attribute(forName: "status")
				if heartbeatStatus?.stringValue == "ok" {
					guard let children = heartbeat.children?.last?.children else { return }
					var watch: Int = 0
					var comment: Int = 0
					var ticket: String = ""
					for child: XMLNode in children {
						guard let name = child.name else { break }
						switch name {
							case .watch:
								guard let watchCount = child.stringValue else { break }
								watch = Int(watchCount)!
							case .comment:
								guard let commentCount = child.stringValue else { break }
								comment = Int(commentCount)!
							case .ticket:
								guard let ticketString = child.stringValue else { break }
								ticket = ticketString
							default:
								break
						}// end switch child
					}// end foreach children
					callback(watch, comment, ticket)
				}// end if hertbeat status is OK
			} catch {
				callback(-1, -1, "")
			}// end try - catch
		}// end completion handler
		task.resume()
	}// end function heartbeat

		// MARK: - Internal methods
		// MARK: - Private methods
	private func setupSocketEventHandler (history: Int) {
		socket.event.open = { [weak self] in
			guard let weakSelf = self else { return }
			let threadData: ThreadRequest = ThreadRequest(thread: weakSelf.thread, uid: weakSelf.userIdentifier, resFrom: history)
			let commentRequest: CommentRequest = CommentRequest(thread: threadData)
			do {
				let json: Data = try JSONEncoder().encode(commentRequest)
				if let request: String = String(data: json, encoding: .utf8) {
					weakSelf.socket.send(text: "[\(request)]")
				}
			} catch let error {
				print(error.localizedDescription)
			}
		}// end open event

		socket.event.close = { (code: Int, reason: String, clean: Bool) in
			print("code: \(code), reason: \(reason), clean: \(clean)")
		}// end close event

		socket.event.error = { (error: Error) in
			print("error: \(error)")
		}// end error event

		socket.event.message = { [weak self] (message: Any) in
			guard let weakSelf = self, let text: NSString = message as? NSString, let json: Data = (message as? String)?.data(using: String.Encoding.utf8) else { return }
			let decoder: JSONDecoder = JSONDecoder()
			let messageType: String? = text.components(separatedBy: MessageSeparators).compactMap{ $0 != "" ? $0 : nil }.first
			if let messageType: String = messageType, let type: ElementType = ElementType(rawValue: messageType) {
				switch type {
				case .thread:
					do {
						let info: ThreadResult = try decoder.decode(ThreadResult.self, from: json)
						weakSelf.ticket = info.thread.ticket
						if let last_res: Int = info.thread.last_res {
							weakSelf.lastRes = last_res > 1 ? last_res - 1 : last_res
						} else {
							weakSelf.lastRes = 0
						}// end optional binding check for last_res
					} catch let error {
						Swift.print("Error: \(error.localizedDescription),\nDroped \(message)")
					}// end do try - catch decode json
				case .chat:
					do {
						let chat: ChatResult = try decoder.decode(ChatResult.self, from: json)
						let last: Bool = weakSelf.lastRes == chat.chat.no
						weakSelf.delegate?.commentVector(commentVector: weakSelf, didRecieveComment: chat.chat, lastPastComment: last)
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
		}// end message event
	}// end setupSocketEventHandler

	private func setupKeepAliveTimer () -> DispatchSourceTimer {
		let keepAlive: DispatchSourceTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.strict, queue: background)
		keepAlive.setEventHandler() { [weak self] in
			guard let weakSelf = self else { return }
			weakSelf.socket.ping("{\"content\":\"rs:0\"}")
			weakSelf.socket.ping("{\"content\":\"ps:0\"}")
			weakSelf.socket.send(text: "")
			weakSelf.socket.ping("{\"content\":\"pf:0\"}")
			weakSelf.socket.ping("{\"content\":\"rf:0\"}")
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

		// MARK: - Delegates
}// end WebSocketCommentVector
