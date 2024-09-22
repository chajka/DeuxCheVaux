//
//  ProtobufCommentVector.swift
//  Charleston
//
//  Created by Чайка on 2024/09/10.
//  Copyright © 2024 Чайка. All rights reserved.
//

import Cocoa

fileprivate let At: String = "at"
fileprivate let Now: String = "now"
fileprivate let Query: String = "?"
fileprivate let ParmConcat: String = "="
fileprivate let Empty: String = ""

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
	public let locale: UserLanguage?
	
	public static var logHeader: String {
		get {
			var message: String = String()

			message += "\"thread\""
			message += ",\"vpos\""
			message += ",\"no\""
			message += ",\"user_id\""
			message += ",\"content\""
			message += ",\"date\""
			message += ",\"date_usec\""
			message += ",\"premium\""
			message += ",\"mail\""
			message += ",\"anonymity\""
			message += ",\"locale\""

			return message
		}// end get
	}// end computed property log header

	public var logMessage: String {
		get {
			var message: String = String()

			message += "\"\(thread)\""
			message += ",\"\(vpos)\""
			message += ",\"\(no)\""
			message += ",\"\(user_id)\""
			message += ",\"\(content.replacingOccurrences(of: "\"", with: "\"\""))\""
			message += ",\"\(date)\""
			message += ",\"\(date_usec)\""
			message += ",\"\(String(describing: premium != nil ? premium! : 0))\""
			message += ",\"\(mail ?? "")\""
			message += ",\"\(anonymity ?? 0)\""
			message += ",\"\(locale?.rawValue ?? UserLanguage.ja.rawValue)\""

			return message
		}// end get
	}// end logmesage
}// end struct ChatElement

struct ChatResult: Codable {
	let chat: ChatElements
}// end struct ChatResult

public protocol ProtobufCommentVectorDelegate: AnyObject {
	func commentVector (commentVector vector: ProtobufCommentVector, didRecieveComment comment: ChatElements)
}// end protocol ProtobufCommentVectorDelegate

public final class ProtobufCommentVector: NSObject, URLSessionDataDelegate {
		// MARK: Static properties
		// MARK: - Class Method
		// MARK: - Outlets
		// MARK: - Properties
	public weak var delegate: ProtobufCommentVectorDelegate?

		// MARK: - Member variables
	private let viewURI: String
	private let streams: BinaryStream = BinaryStream(data: Data())
	private let messages: BinaryStream = BinaryStream(data: Data())
	private var nextAt: String = Now
	private var connecting: Bool = true
	private var first: Bool = true
	private let config: URLSessionConfiguration = URLSessionConfiguration.default
	private var viewSession: URLSession?
	private var segmentSession: URLSession?

		// MARK: - Constructor/Destructor
	public init (viewURI: String) {
		self.viewURI = viewURI
		self.config.timeoutIntervalForRequest = 20
		self.config.timeoutIntervalForResource = 40
	}// end init

		// MARK: - Override
		// MARK: - Actions
	public func stop () {
		connecting = false
	}

		// MARK: - Public methods
	public func start () {
		viewSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
		segmentSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
		let url = URL(string: viewURI + Query + At + ParmConcat + Now)!
		Task {
			do {
				var request: URLRequest = URLRequest(url: url)
				let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
				var result: (data: Data, resp: URLResponse) = try await session.data(for: request)
				streams.addBuffer(data: result.data)
				let chunk = streams.read().next()
				let entry: Dwango_Nicolive_Chat_Service_Edge_ChunkedEntry = try Dwango_Nicolive_Chat_Service_Edge_ChunkedEntry(serializedBytes: Data(chunk!))
				nextAt = String(format: "%ld", entry.next.at)
				var nextURL: URL = URL(string: viewURI + Query + At + ParmConcat + nextAt)!
				while (connecting) {
					request = URLRequest(url: nextURL)
					result = try await session.data(for: request)
					streams.addBuffer(data: result.data)
					for chunk in streams.read() {
						nextAt = parseChunk(dat: chunk)
					}
					nextURL = URL(string: viewURI + Query + At + ParmConcat + nextAt)!
					first = false
				}
			} catch let error {
				print(error.localizedDescription)
			}
		}
	}// end start

	public func close () {
		
	}

		// MARK: - Private methods
	private func parseChunk (dat: [UInt8]) -> String {
		do {
			let data: Data = Data(dat)
			let entry: Dwango_Nicolive_Chat_Service_Edge_ChunkedEntry = try Dwango_Nicolive_Chat_Service_Edge_ChunkedEntry(serializedBytes: data)
			if (first && entry.backward.segment.uri != Empty) {
				loadBackword(uri: entry.backward.segment.uri)
			} else if (first && entry.previous.uri != Empty) {
				loadSegment(uri: entry.previous.uri)
			} else if (entry.segment.uri != Empty) {
				loadSegment(uri: entry.segment.uri)
			} else if (entry.next.at != 0) {
				return String(format: "%ld", entry.next.at)
			}
		} catch let error {
			print(error.localizedDescription)
		}// end do try catch
		return nextAt
	}// end func parseChunk

	private func loadSegment (uri: String) {
		Task {
			let url = URL(string: uri)!
			let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
			let request: URLRequest = URLRequest(url: url)
			do {
				let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
				if result.data.count > 3 { messages.addBuffer(data: result.data) }
				for mes in messages.read() {
					let message: Dwango_Nicolive_Chat_Service_Edge_ChunkedMessage = try Dwango_Nicolive_Chat_Service_Edge_ChunkedMessage(serializedBytes: mes)
					if (message.meta.origin.chat.liveID != 0) {
						let element: ChatElements = parseMessage(message: message)
						delegate?.commentVector(commentVector: self, didRecieveComment: element)
					}// end if garbage message
				}
			} catch let error {
				print("Error parse ChunkedMessage:")
				print(error.localizedDescription)
			}
		}// end Task
	}// end func loadPrevious

	private func loadBackword (uri: String) {
		Task {
			let url = URL(string: uri)!
			let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
			let request: URLRequest = URLRequest(url: url)
			do {
				let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
				let comments: Dwango_Nicolive_Chat_Service_Edge_PackedSegment = try Dwango_Nicolive_Chat_Service_Edge_PackedSegment(serializedBytes: result.data)
				for comment in comments.messages {
					let element: ChatElements = parseMessage(message: comment)
					delegate?.commentVector(commentVector: self, didRecieveComment: element)
				}
				
			} catch let error {
				print(error.localizedDescription)
			}
		}
	}// end func loadBackword

	private func parseMessage (message: Dwango_Nicolive_Chat_Service_Edge_ChunkedMessage) -> ChatElements {
		let thread: String = String(format: "%lld", message.meta.origin.chat.liveID)
		var user_id: String = message.message.chat.rawUserID != 0 ? String(format: "%ld", message.message.chat.rawUserID) : message.message.chat.hashedUserID
		let vpos: TimeInterval = TimeInterval(message.message.chat.vpos)
		let no: Int = Int(message.message.chat.no)
		let date: TimeInterval = TimeInterval(message.meta.at.seconds)
		let date_usec: TimeInterval = TimeInterval(message.meta.at.nanos)
		let annonimity: Int = message.message.chat.rawUserID == 0 ? 1 : 0
		var content: String = ""
		var premium: Int = 0
		if (message.message.chat.content != Empty) {
			content = message.message.chat.content
			premium = message.message.chat.accountStatus == .premium ? 1 : 0
		} else if (message.state.marquee.display.operatorComment.content != Empty) {
			content = message.state.marquee.display.operatorComment.content
			premium = 2
		} else if (message.message.simpleNotification.emotion != Empty) {
			content = message.message.simpleNotification.emotion
			premium = 3
		} else if (message.message.simpleNotification.ichiba != Empty) {
			content = message.message.simpleNotification.ichiba
			premium = 3
		} else if (message.message.simpleNotification.programExtended != Empty) {
			content = message.message.simpleNotification.programExtended
			premium = 3
		} else if (message.message.gift.itemName != Empty) {
			content = message.message.gift.itemName
			if (message.message.gift.advertiserUserID != 0) {
				user_id = String(format: "%ld", message.message.gift.advertiserUserID)
			}
			premium = 3
		} else if (message.message.nicoad.v1.message != Empty) {
			content = message.message.nicoad.v1.message
			premium = 3
		} else if (message.message.simpleNotification.rankingIn != Empty) {
			content = message.message.simpleNotification.rankingIn
			premium = 3
		} else if (message.message.simpleNotification.visited != Empty) {
			content = message.message.simpleNotification.visited
			premium = 3
		} else if (message.message.simpleNotification.cruise != Empty) {
			content = message.message.simpleNotification.cruise
			premium = 5
		} else if (message.message.simpleNotification.quote != Empty) {
			content = message.message.simpleNotification.quote
			premium = 5
		} else if (message.message.nicoad.v1.message != Empty) {
			content = message.message.nicoad.v1.message
			premium = 3
		}
		let element: ChatElements = ChatElements(thread: thread, vpos: vpos, no: no, user_id: user_id, content: content, date: date, date_usec: date_usec, premium: premium, mail: "", anonymity: annonimity, locale: .ja)
		return element
	}
		// MARK: - Delegates


}// end class ProtobufCommnentVector
