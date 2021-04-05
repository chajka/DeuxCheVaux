//
//  WebSocketEndpointTalker.swift
//  DeuxCheVaux
//
//  Created by Я Чайка on 2021/04/03.
//  Copyright © 2021 Чайка. All rights reserved.
//

import Cocoa
import SwiftWebSocket

fileprivate let StartWatching: String = "{\"type\":\"startWatching\",\"data\":{\"stream\":{\"quality\":\"abr\",\"limit\":\"super_high\",\"latency\":\"low\",\"chasePlay\":false},\"reconnect\":false}}"
fileprivate let Pong: String = "{\"type\":\"pong\"}"
fileprivate let KeepSeat: String = "{\"type\":\"keepSeat\"}"

fileprivate enum MessageKind: String {
	case seat = "seat"
	case akashic = "akashic"
	case stream = "stream"
	case room = "room"
	case serverTime = "serverTime"
	case statistics = "statistics"
	case schedule = "schedule"
	case ping = "ping"
	case disconnect = "disconnect"
	case reconnect = "reconnect"
	case postCommentResult = "postCommentResult"
	case tagUpdated = "tagUpdated"
}// end enum MessageKind

fileprivate struct MessageType: Codable {
	let type: String
}// end struct MessageType

fileprivate struct SeatData: Codable {
	let keepIntervalSec: Int
}// end struct SeatData

fileprivate struct Seat: Codable {
	let type: String
	let data: SeatData
}// end struct Seat

fileprivate struct StatData: Codable {
	let viewers: Int
	let comments: Int
	let adPoints: Int?
	let giftPoints: Int?
}// end struct StatData

fileprivate struct Statistics: Codable {
	let type: String
	let data: StatData
}// end struct Statistics

fileprivate struct PostCommentData: Codable {
	let text: String
	let vpos: Int
	let isAnonymous: Bool
	let color: String?
	let size: String?
	let position: String?
	let font: String?
}// end struct PostCommentData

fileprivate struct PostComment: Codable {
	let type: String
	let data: PostCommentData
}// end struct PostComment

public protocol HeartbeatDelegate: class {
	func heartbeat (viewer: Int, comments: Int, ad: Int?, gift: Int?)
}// end protocol heartbeatDelegate

public final class WebSocketEndpointTalker: NSObject {
		// MARK:   Class Variables
		// MARK: - Class Methods
		// MARK: - Properties
	public let url: URL
	public weak var delegate: HeartbeatDelegate?

		// MARK: - Computed Properties
		// MARK: - Outlets
		// MARK: - Member Variables
	private weak var runLoop: RunLoop? = DeuxCheVaux.shared.runLoop
	private var endpoint: WebSocket
	private var keepSeatInterval: Int = 30

	private var keepSeatTimer: DispatchSourceTimer? = nil

		// MARK: - Constructor / Destructor
	public init (url: URL) {
		self.url = url
		var request: URLRequest = URLRequest(url: self.url)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		if let runLoop: RunLoop = self.runLoop {
			endpoint = WebSocket(request: request, runLoop: runLoop)
		} else {
			endpoint = WebSocket(request: request)
		}// end optional binding check for runLoop
		endpoint.compression.on = true
		endpoint.allowSelfSignedSSL = true
	}// end init

	deinit {
		if let timer: DispatchSourceTimer = keepSeatTimer {
			timer.suspend()
			timer.cancel()
			keepSeatTimer = nil
		}// end optional binding check for keep seat timer
	}// end deinit

		// MARK: - Overrides
		// MARK: - Actions
		// MARK: - Public Methods
	public func open () {
		setupKeepSeatTimer()
		setupSocketEventHandler()
		endpoint.open()
	}// end open

	public func close () {
		endpoint.close()
	}// end close

	public func postComment (comment: String, vpos: Int, isAnoymous: Bool, color: String = "white", size: String = "medium", position: String = "naka", font: String = "defont") {
		let commentToPost: PostCommentData = PostCommentData(text: comment, vpos: vpos, isAnonymous: isAnoymous, color: color, size: size, position: position, font: font)
		let comment: PostComment = PostComment(type: "postComment", data: commentToPost)
		let encoder: JSONEncoder = JSONEncoder()
		do {
			let json: Data = try encoder.encode(comment)
			endpoint.send(data: json)
		} catch let error {
			print("post comment json encode error \(error.localizedDescription)")
		}// end do try - catch encode json
	}// end post comment

		// MARK: - Private Methods
	private func setupKeepSeatTimer () {
		keepSeatTimer = DispatchSource.makeTimerSource()
		if let timer: DispatchSourceTimer = keepSeatTimer {
			timer.setEventHandler { [weak self] in
				guard let weakSelf = self else { return }
				weakSelf.endpoint.send(text: KeepSeat)
			}// end event Handler
		}// end optional binding check for keep seat timer
	}// end func setupKeepSeatTimer

	private func setupSocketEventHandler () {
		endpoint.event.open = { [weak self] in
			guard let weakSelf = self else { return }
			weakSelf.endpoint.send(text: StartWatching)
		}// end open event

		endpoint.event.close = { (code: Int, reason: String, clean: Bool) in
			print("code: \(code), reason: \(reason), clean: \(clean)")
		}// end close event

		endpoint.event.error = { (error: Error) in
			print("error: \(error)")
		}// end error event

		endpoint.event.message = { [weak self] (message: Any) in
			guard let weakSelf = self, let json: Data = (message as? String)?.data(using: String.Encoding.utf8) else { return }
			let decoder: JSONDecoder = JSONDecoder()
			do {
				let messageType: MessageType = try decoder.decode(MessageType.self, from: json)
				if let type: MessageKind = MessageKind(rawValue: messageType.type) {
					switch type {
					case .seat:
						do {
							guard let timer: DispatchSourceTimer = weakSelf.keepSeatTimer else { return }
							let seat: Seat = try decoder.decode(Seat.self, from: json)
							weakSelf.keepSeatInterval = seat.data.keepIntervalSec
							timer.schedule(deadline: DispatchTime.now(), repeating: .seconds(weakSelf.keepSeatInterval), leeway: .milliseconds(10))
							timer.resume()
						} catch let error {
							print("seat decode error \(error.localizedDescription)")
						}
					case .akashic:
						break
					case .stream:
						break
					case .room:
						break
					case .serverTime:
						break
					case .statistics:
						do {
							let statistics: Statistics = try decoder.decode(Statistics.self, from: json)
							let stat: StatData = statistics.data
							if let delegate: HeartbeatDelegate = weakSelf.delegate {
								delegate.heartbeat(viewer: stat.viewers, comments: stat.comments, ad: stat.adPoints, gift: stat.giftPoints)
							}// end optional binding check for heartbeat delegate
						} catch let error {
							print("statistics decode error \(error.localizedDescription)")
						}// end do try - catch decode statistics json
					case .schedule:
						break
					case .ping:
						weakSelf.endpoint.send(text: Pong)
					case .disconnect:
						break
					case .reconnect:
						break
					case .postCommentResult:
						break
					case .tagUpdated:
						break
					}
				}// end optional binding check for MessageKind
				
			} catch let error {
				print("type json decode error \(error.localizedDescription)")
			}
		}
	}// end func setupSocketEventHandler

		// MARK: - Delegate / Protocol clients
}// end class WebSocketEndpointTalker
