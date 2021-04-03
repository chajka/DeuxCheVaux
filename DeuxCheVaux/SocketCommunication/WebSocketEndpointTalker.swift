//
//  WebSocketEndpointTalker.swift
//  DeuxCheVaux
//
//  Created by Я Чайка on 2021/04/03.
//  Copyright © 2021 Чайка. All rights reserved.
//

import Cocoa
import SwiftWebSocket

fileprivate let SubProtocol: String = "msg.nicovideo.jp#json"
fileprivate let StartWatching: String = "{\"type\":\"startWatching\",\"data\":{\"stream\":{\"quality\":\"abr\",\"limit\":\"super_high\",\"latency\":\"low\",\"chasePlay\":false},\"reconnect\":false}}"
fileprivate let Pong: String = "{\"type\":\"pong\"}"

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

public final class WebSocketEndpointTalker: NSObject {
		// MARK:   Class Variables
		// MARK: - Class Methods
		// MARK: - Properties
	public let url: URL

		// MARK: - Computed Properties
		// MARK: - Outlets
		// MARK: - Member Variables
	private weak var runLoop: RunLoop? = DeuxCheVaux.shared.runLoop
	private var endpoint: WebSocket
	private var keepSeatInterval: Int = 0

		// MARK: - Constructor / Destructor
	public init (url: URL) {
		self.url = url
		var request: URLRequest = URLRequest(url: self.url)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		if let runLoop: RunLoop = self.runLoop {
			endpoint = WebSocket(request: request, subProtocols: [SubProtocol], runLoop: runLoop)
		} else {
			endpoint = WebSocket(request: request, subProtocols: [SubProtocol])
		}// end optional binding check for runLoop
		endpoint.compression.on = true
		endpoint.allowSelfSignedSSL = true
	}// end init

		// MARK: - Overrides
		// MARK: - Actions
		// MARK: - Public Methods
		// MARK: - Private Methods
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
							let seat: Seat = try decoder.decode(Seat.self, from: json)
							weakSelf.keepSeatInterval = seat.data.keepIntervalSec
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
						break
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
				print(error.localizedDescription)
			}
		}
	}// end func setupSocketEventHandler

		// MARK: - Delegate / Protocol clients
}// end class WebSocketEndpointTalker
