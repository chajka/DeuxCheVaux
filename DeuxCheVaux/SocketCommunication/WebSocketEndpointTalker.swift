//
//  WebSocketEndpointTalker.swift
//  DeuxCheVaux
//
//  Created by Я Чайка on 2021/04/03.
//  Copyright © 2021 Чайка. All rights reserved.
//

import Cocoa
import Starscream

fileprivate let StartWatching: String = "{\"type\":\"startWatching\",\"data\":{\"reconnect\":false}}"
fileprivate let Pong: String = "{\"type\":\"pong\"}"
fileprivate let KeepSeat: String = "{\"type\":\"keepSeat\"}"
fileprivate let PostCommentType: String = "postComment"

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

fileprivate struct CurrentMS: Codable {
	let currentMs: String
}// end struct CurrentMS

fileprivate struct ServerTime: Codable {
	let type: String
	let data: CurrentMS
}// end struct ServerTime

fileprivate struct ScheduleData: Codable {
	let begin: String
	let end: String
}// end struct ScheduleData

fileprivate struct Schedule: Codable {
	let type: String
	let data: ScheduleData
}// end Schedule

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

fileprivate struct Reason: Codable {
	let reason: String
}// end struct Reason

fileprivate struct Disconnect: Codable {
	let type: String
	let data: Reason
}// end struct Disconnect

public enum DisconnectReason: String {
	case takeover = "TAKEOVER"
	case noPermission = "NO_PERMISSION"
	case endProgram = "END_PROGRAM"
	case pingTimeout = "PING_TIMEOUT"
	case tooManyConnections = "TOO_MANY_CONNECTIONS"
	case tooManyWatchings = "TOO_MANY_WATCHINGS"
	case crowded = "CROWDED"
	case maintenanceIn = "MAINTENANCE_IN"
	case serverTemporaryUnavailable = "SERVICE_TEMPORARILY_UNAVAILABLE"
}// end enum DisconnectReason

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

public protocol HeartbeatDelegate: AnyObject {
	func heartbeat (viewer: Int, comments: Int, ad: Int?, gift: Int?)
}// end protocol heartbeatDelegate

public typealias OpenEndpointHander = (_ websocketURI: URL, _ threadId: String, _ yourpostkey: String) -> Void

public final class WebSocketEndpointTalker: NSObject, WebSocketDelegate {
		// MARK:   Class Variables
		// MARK: - Class Methods
		// MARK: - Properties
	public let url: URL
	public weak var delegate: HeartbeatDelegate?

		// MARK: - Computed Properties
		// MARK: - Outlets
		// MARK: - Member Variables
	private var endpoint: WebSocket
	private var keepSeatInterval: Int = 30
	private var roomInfoHandler: OpenEndpointHander? = nil
	private var connecting: Bool = false

	private var keepSeatTimer: DispatchSourceTimer? = nil

		// MARK: - Constructor / Destructor
	public init (url: URL) {
		self.url = url
		var request: URLRequest = URLRequest(url: self.url)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		endpoint = WebSocket(request: request)
		super.init()
		endpoint.delegate = self
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
	public func open (handler: OpenEndpointHander? = nil) {
		connecting = true
		roomInfoHandler = handler
		setupKeepSeatTimer()
		endpoint.connect()
		endpoint.write(string: StartWatching)
	}// end open

	public func close () {
		connecting = false
		endpoint.disconnect()
	}// end close

	public func postComment (comment: String, vpos: Int, isAnonymous: Bool, color: String? = nil, size: String? = nil, position: String? = nil, font: String? = nil) {
		let commentToPost: PostCommentData = PostCommentData(text: comment, vpos: vpos, isAnonymous: isAnonymous, color: color, size: size, position: position, font: font)
		let comment: PostComment = PostComment(type: PostCommentType, data: commentToPost)
		let encoder: JSONEncoder = JSONEncoder()
		do {
			let json: Data = try encoder.encode(comment)
			if let postComment: String = String(data: json, encoding: .utf8) {
				endpoint.write(string: postComment)
			}// end optional binding check for json data convert to string
		} catch let error {
			print("post comment json encode error \(error.localizedDescription)")
		}// end do try - catch encode json
	}// end post comment

		// MARK: - Private Methods
	private func setupKeepSeatTimer () {
		keepSeatTimer = DispatchSource.makeTimerSource()
		if let timer: DispatchSourceTimer = keepSeatTimer {
			timer.setEventHandler {
				self.endpoint.write(string: KeepSeat)
			}// end event Handler
		}// end optional binding check for keep seat timer
	}// end func setupKeepSeatTimer

	private func processMessage (message: String) {
		guard let json: Data = message.data(using: String.Encoding.utf8) else { return }
		let decoder: JSONDecoder = JSONDecoder()
		do {
			let messageType: MessageType = try decoder.decode(MessageType.self, from: json)
			if let type: MessageKind = MessageKind(rawValue: messageType.type) {
				switch type {
				case .seat:
					do {
						guard let timer: DispatchSourceTimer = keepSeatTimer else { return }
						let seat: Seat = try decoder.decode(Seat.self, from: json)
						keepSeatInterval = seat.data.keepIntervalSec
						timer.schedule(deadline: DispatchTime.now(), repeating: .seconds(keepSeatInterval), leeway: .milliseconds(10))
						timer.resume()
					} catch let error {
						print("seat decode error \(error.localizedDescription)")
					}
				case .akashic:
					break
				case .stream:
					break
				case .room:
					do {
						let room: RoomInfo = try decoder.decode(RoomInfo.self, from: json)
						if let handler: OpenEndpointHander = roomInfoHandler {
							handler(URL(string: room.data.messageServer.uri)!, room.data.threadId, room.data.yourPostKey)
						}// end if Optional binding check for roomInfoHandler
					} catch let error {
						print("room decode error \(error.localizedDescription)")
					}
				case .serverTime:
					break
				case .statistics:
					do {
						let statistics: Statistics = try decoder.decode(Statistics.self, from: json)
						let stat: StatData = statistics.data
						if let delegate: HeartbeatDelegate = delegate {
							delegate.heartbeat(viewer: stat.viewers, comments: stat.comments, ad: stat.adPoints, gift: stat.giftPoints)
						}// end optional binding check for heartbeat delegate
					} catch let error {
						print("statistics decode error \(error.localizedDescription)")
					}// end do try - catch decode statistics json
				case .schedule:
					break
				case .ping:
					endpoint.write(string: Pong)
				case .disconnect:
					do {
						let message: Disconnect = try decoder.decode(Disconnect.self, from: json)
						print("Disconnect reason \(message.data.reason)")
					} catch let error {
						print("Disconnect decode error \(error.localizedDescription)")
					}// end do try - catch decode json
				case .reconnect:
					print("reconnect message from ws endpoint")
				case .postCommentResult:
					break
				case .tagUpdated:
					break
				}
			} else {
				print("incorrect type : \(message)")
			}// end optional binding check for MessageKind
			
		} catch let error {
			print("type json decode error \(error.localizedDescription)")
		}// end do try catch
	}// end processMessage

		// MARK: - Delegate / Protocol clients
	public func didReceive (event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
		switch event {
		case .connected (_):
			if (!connecting) {
				connecting = true
				endpoint.write(string: StartWatching)
			}
			break
		case .disconnected (_, _):
			if (connecting) {
				endpoint.connect()
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
				endpoint.connect()
			}// end if connectiing
			break
		case .error (let error):
			print("Websocket error: \(String(describing: error))")
			break
		case .peerClosed:
			break
		}// end switch by event
	}// end didReceive
}// end class WebSocketEndpointTalker
