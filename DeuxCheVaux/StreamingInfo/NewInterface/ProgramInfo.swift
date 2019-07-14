//
//  ProgramInfo.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/08/19.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

let ProgramInfoFormat: String = "http://live2.nicovideo.jp/watch/"
let ProgramInfoSuffix: String = "/programinfo"

public struct Room: Codable {
	let webSocketUri: String
	let xmlSocketUri: String
	let name: String
	let id: Int
	let threadId: String
}// end struct Room

public struct SocialGroup: Codable {
	let type: String
	let id: String
	let name: String
	let communityLevel: Int
}// end struct SocialGroup

public struct Broadcaster: Codable {
	let name: String
	let id: String
}// end struct Broadcaster

public struct ProtramInformation: Codable {
	let title: String
	let description: String
	let isMemberOnly: Bool
	let vposBaseAt: TimeInterval
	let beginAt: TimeInterval
	let endAt: TimeInterval
	let status: ProgramStatus
	let categories: Array<String>
	let rooms: Array<Room>
	let isUserNiconicoAdsEnabled: Bool
	let socialGroup: SocialGroup
	let broadcaster: Broadcaster
}// end struct ProtramInformation

fileprivate struct ProgramInfoJSON: Codable {
	let meta: MetaInformation
	let data: ProtramInformation?
}// end struct ProgramInfoJSON

public enum ProgramInfoError: Error {
	case NoError
	case NoProgramError
	case URLResponseError
	case JSONParseError
	case SelfReleased
}// end enum ProgramInfoError

public enum ProgramStatus: String, Codable {
	case test = "test"
	case onAir = "onAir"
	case ended = "ended"
}// end enum ProgramStatus

public struct Social {
	public let name: String
	public let identifier: String
	public let level: Int
	public let type: SocialType
}// end struct Social

public struct BroadcasterInfo {
	public let name: String
	public let identifier: String
}// end Struct Broadcaster

private enum RoomKeys: String {
	case name = "name"
	case webSocket = "webSocketUri"
	case xmlSocket = "xmlSocketUri"
	case thread = "threadId"
	case id = "id"

	static func ~= (lhs: RoomKeys, rhs: String) -> Bool {
		return lhs.rawValue ~= rhs ? true : false
	}// end func ~=
}// end enum RoomKey

//private enum JSONKey {
//	enum toplevel: String {
//		case meta = "meta"
//		case data = "data"
//	}// end enum toplevel
//	enum data: String {
//		case beginAt = "beginAt"
//		case socialGroup = "socialGroup"
//		case status = "status"
//		case isMemberOnly = "isMemberOnly"
//		case categories = "categories"
//		case vposBaseAt = "vposBaseAt"
//		case description = "description"
//		case endAt = "endAt"
//		case title = "title"
//		case broadcaster = "broadcaster"
//		case isUserNiconicoAdsEnabled = "isUserNiconicoAdsEnabled"
//		case rooms = "rooms"
//	}// dataKey
//	enum social: String {
//		case communityLevel = "communityLevel"
//		case id = "id"
//		case name = "name"
//		case type = "type"
//	}// end socialKeys
//	enum broadcaster: String {
//		case id = "id"
//		case name = "name"
//	}// end enum broadcaster
//	enum room: String {
//		case id = "id"
//		case name = "name"
//		case thread = "threadId"
//		case webSocket = "webSocketUri"
//		case xmlSocket = "xmlSocketUri"
//	}// end enum room
//}// end public enum JSONKey
//
//extension JSONKey.toplevel: StringEnum { }
//extension JSONKey.data: StringEnum { }
//extension JSONKey.social: StringEnum { }
//extension JSONKey.broadcaster: StringEnum { }
//extension JSONKey.room: StringEnum { }

private let Timeout: Double = 2.0

public final class ProgramInfo: NSObject {
		// MARK:   Outlets
		// MARK: - Properties
	public private(set) var social: Social!
	public private(set) var status: ProgramStatus!
	public private(set) var isMemberOnly: Bool!
	public private(set) var categories: Array<String>!
	public private(set) var baseTime: Date!
	public private(set) var startTime: Date!
	public private(set) var endTime: Date!
	public private(set) var programDesctiption: NSAttributedString!
	public private(set) var broadcaster: BroadcasterInfo!
	public private(set) var canNicoAd: Bool!
	public private(set) var servers: Array<MessageServer> = Array()

		// MARK: - Member variables
	let userSession: Array<HTTPCookie>

		// MARK: - Constructor/Destructor
	public init (programNumber: String, cookies: [HTTPCookie]) throws {
		userSession = cookies
		super.init()
		let result: ProgramInfoError = getProgramInfomation(programNumber: programNumber)
		if result != .NoError { throw result }
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Private methods
	private func parseServers(information: Dictionary<String, Any>) {
		guard let servers: Array<Dictionary<String, Any>> = information[JSONKey.data.rooms] as? Array<Dictionary<String, Any>> else { return }
		servers.forEach { (server) in
			var name: String = "", webSocket: URL = URL(string: "http://www.apple.com")!, xml: String = "", port: Int = 0, thread: String = ""
			server.forEach({ (key, value) in
				switch key {
				case .name:
					name = value as? String ?? ""
				case .thread:
					thread = value as? String ?? ""
				case .webSocket:
					webSocket = URL(string: value as? String ?? "") ?? URL(string: "http://live2.nicovideo.jp/")!
				case .xmlSocket:
					let xmlSocket: URL = URL(string: value as? String ?? "") ?? URL(string: "http://live2.nicovideo.jp/")!
					xml = xmlSocket.host!
					port = xmlSocket.port!
				default:
					break
				}// end switch
			})// end foreach
			let xmlSocket: XMLSocket = XMLSocket(address: xml, port: port)
			let serv: MessageServer = MessageServer(XMLSocet: xmlSocket, WebSocket: webSocket, thread: thread, name: name)
			self.servers.append(serv)
		}// end foreach servers
	}// end func parseServers

	private func parseProperties(infomation: Dictionary<String, Any>) {
		guard let social: Dictionary<String, Any> = infomation[JSONKey.data.socialGroup] as? Dictionary<String, Any> else { return }
		let level: Int = social[JSONKey.social.communityLevel] as? Int ?? 1
		let communityIdentifier: String = social[JSONKey.social.id] as? String ?? ""
		let communityName: String = social[JSONKey.social.name] as? String ?? ""
		let type: SocialType = SocialType(rawValue: social[JSONKey.social.type] as? String ?? SocialType.community.rawValue) ?? SocialType.community
		self.social = Social(name: communityName, identifier: communityIdentifier, level: level, type: type)
		self.status = ProgramStatus(rawValue: infomation[JSONKey.data.status] as? String ?? ProgramStatus.ended.rawValue)
		self.isMemberOnly = infomation[JSONKey.data.isMemberOnly] as? Bool ?? false
		self.categories = infomation[JSONKey.data.categories] as? Array<String> ?? Array()
		self.baseTime = Date(timeIntervalSince1970: infomation[JSONKey.data.vposBaseAt] as? TimeInterval ?? Date().timeIntervalSince1970)
		self.startTime = Date(timeIntervalSince1970: infomation[JSONKey.data.beginAt] as? TimeInterval ?? Date().timeIntervalSince1970)
		self.endTime = Date(timeIntervalSince1970: infomation[JSONKey.data.endAt] as? TimeInterval ?? Date().timeIntervalSince1970)
		if let descriptionString = (infomation[JSONKey.data.description] as? String)?.data(using: .utf8) {
			do {
				let readingOptions: Dictionary<NSAttributedString.DocumentReadingOptionKey, Any> = [.documentType: NSAttributedString.DocumentType.html, .textEncodingName: "UTF-8"]
				programDesctiption = try NSAttributedString(data: descriptionString, options: readingOptions, documentAttributes: nil)
			} catch {
				programDesctiption = NSAttributedString(string: (infomation[JSONKey.data.description] as? String ?? ""))
			}
		}// end if
		if let broadcaster: Dictionary<String, String> = infomation[JSONKey.data.broadcaster] as? Dictionary<String, String> {
			let ownerName: String = broadcaster[JSONKey.broadcaster.name] ?? ""
			let identifier: String = broadcaster[JSONKey.broadcaster.id] ?? ""
			self.broadcaster = Broadcaster(name: ownerName, identifier: identifier)
		}// end optional checking
		self.canNicoAd = infomation[JSONKey.data.isUserNiconicoAdsEnabled] as? Bool ?? false
	}// end parseProperties

	private func getProgramInfomation(programNumber: String) -> ProgramInfoError {
		let programInfoURLString = ProgramInfoFormat + programNumber + ProgramInfoSuffix
		if let programInfoURL: URL = URL(string: programInfoURLString) {
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			var request: URLRequest = URLRequest(url: programInfoURL)
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: userSession)
			let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
			var infoErr: ProgramInfoError = .NoError
			var descriptionHTML: String?
			var descriptionString: String?
			let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat, resp, err) in
				guard let weakSelf = self, let recievedData: Data = dat, let response: HTTPURLResponse = resp as? HTTPURLResponse else {
					infoErr = .SelfReleased
					semaphore.signal()
					return
				}// end guard else
				if recievedData.count > 0 && Int(response.statusCode / 100) == 2 {
					let decoder: JSONDecoder = JSONDecoder()
					do {
						let result: ProgramInfoJSON = try decoder.decode(ProgramInfoJSON.self, from: recievedData)
						if let programInfo: ProtramInformation = result.data {
							infoErr = ProgramInfoError.NoError
							let social: SocialGroup = programInfo.socialGroup
							if let type: SocialType = SocialType(rawValue: social.type) {
								weakSelf.social = Social(name: social.name, identifier: social.id, level: social.communityLevel, type: type)
							}// end optional binding for social type is much to social type
							weakSelf.status = programInfo.status
							weakSelf.isMemberOnly = programInfo.isMemberOnly
							weakSelf.categories = programInfo.categories
							weakSelf.baseTime = Date(timeIntervalSince1970: programInfo.vposBaseAt)
							weakSelf.startTime = Date(timeIntervalSince1970: programInfo.beginAt)
							weakSelf.endTime = Date(timeIntervalSince1970: programInfo.endAt)
							descriptionString = programInfo.description
							descriptionHTML = "<html><body>" + programInfo.description + "</body></html>"
							weakSelf.broadcaster = BroadcasterInfo(name: programInfo.broadcaster.name, identifier: programInfo.broadcaster.id)
							for room: Room in programInfo.rooms {
								if let webSocket: URL = URL(string: room.webSocketUri), let xml: URL = URL(string: room.xmlSocketUri) {
									if let xmlHost: String = xml.host, let port: Int = xml.port {
										let xmlSocket: XMLSocket = XMLSocket(address: xmlHost, port: port)
										let server: MessageServer = MessageServer(XMLSocet: xmlSocket, WebSocket: webSocket, thread: room.threadId, name: room.name, identifier: room.id)
										weakSelf.servers.append(server)
									}// end optional biniding check for get xml socket server addreess and port
								}// end optional binding check for make url for web socket and xml socket
							}// end foreach rooms
						}// end if optional check for data
					} catch {
						infoErr = ProgramInfoError.JSONParseError
					}// end try - catch JSONSerialization exception
				} else {
					infoErr = ProgramInfoError.URLResponseError
				}// end
				semaphore.signal()
			}// end completion handler
			task.resume()
			_ = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			if infoErr != .NoError { return infoErr }
			parseProperties(infomation: data)
			parseServers(information: data)
 		}// end if URL can allocated

		return ProgramInfoError.NoError
	}// end getProgramInfomation

		// MARK: - Delegates
}// end class
