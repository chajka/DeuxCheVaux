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

public enum JSONKey {
	enum toplevel: String {
		case meta = "meta"
		case data = "data"
	}// end enum toplevel
	enum data: String {
		case beginAt = "beginAt"
		case socialGroup = "socialGroup"
		case status = "status"
		case isMemberOnly = "isMemberOnly"
		case categories = "categories"
		case vposBaseAt = "vposBaseAt"
		case description = "description"
		case endAt = "endAt"
		case title = "title"
		case broadcaster = "broadcaster"
		case isUserNiconicoAdsEnabled = "isUserNiconicoAdsEnabled"
		case rooms = "rooms"
	}// dataKey
	enum social: String {
		case communityLevel = "communityLevel"
		case id = "id"
		case name = "name"
		case type = "type"
	}// end socialKeys
	enum broadcaster: String {
		case id = "id"
		case name = "name"
	}// end enum broadcaster
	enum room: String {
		case id = "id"
		case name = "name"
		case thread = "threadId"
		case webSocket = "webSocketUri"
		case xmlSocket = "xmlSocketUri"
	}// end enum room
}// end public enum JSONKey

extension JSONKey.toplevel: StringEnum { }
extension JSONKey.data: StringEnum { }
extension JSONKey.social: StringEnum { }
extension JSONKey.broadcaster: StringEnum { }
extension JSONKey.room: StringEnum { }

public enum ProgramInfoError: Error {
	case NoError
	case NoProgramError
	case URLResponseError
	case JSONParseError
}// end enum ProgramInfoError

public enum ProgramStatus: String {
	case test = "test"
	case onAir = "onAir"
	case ended = "ended"
}// end enum ProgramStatus

public struct Social {
	let name: String
	let identifier: String
	let level: Int
	let type: SocialType
}// end struct Social

public struct Broadcaster {
	let name: String
	let identifier: String
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

class ProgramInfo: NSObject {
		// MARK:   Outlets
		// MARK: - Properties
	private(set) var social: Social!
	private(set) var status: ProgramStatus!
	private(set) var isMemberOnly: Bool!
	private(set) var categories: Array<String>!
	private(set) var startTime: Date!
	private(set) var programDesctiption: NSAttributedString!
	private(set) var broadcaster: Broadcaster!
	private(set) var canNicoAd: Bool!
	private(set) var servers: Array<MessageServer> = Array()

		// MARK: - Member variables
	let userSession: Array<HTTPCookie>

		// MARK: - Constructor/Destructor
	init (programNumber: String, cookies: [HTTPCookie]) throws {
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
				Swift.print("key \(key), value \(value)")
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
		self.startTime = Date(timeIntervalSince1970: infomation[JSONKey.data.beginAt] as? TimeInterval ?? Date().timeIntervalSince1970)
		if let descriptionString = (infomation[JSONKey.data.description] as? String)?.data(using: .utf8) {
			do {
				programDesctiption = try NSAttributedString(data: descriptionString, options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
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
			var doneTransfer: Bool = false
			var request: URLRequest = URLRequest(url: programInfoURL)
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: userSession)
			let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
			var infoErr: ProgramInfoError = .NoError
			var data: Dictionary<String, Any> = Dictionary()
			let task: URLSessionDataTask = session.dataTask(with: request) { (dat, resp, err) in
				guard let recievedData: Data = dat, let response: HTTPURLResponse = resp as? HTTPURLResponse else { return }
				if recievedData.count > 0 && Int(response.statusCode / 100) == 2 {
					do {
						let result: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: recievedData, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, Any>
						if let infoDict: Dictionary<String, Any> = result[JSONKey.toplevel.data] as? Dictionary<String, Any> { data = infoDict }
					} catch {
						infoErr = ProgramInfoError.JSONParseError
					}// end try - catch JSONSerialization exception
				} else {
					infoErr = ProgramInfoError.URLResponseError
				}// end
				doneTransfer = true
			}// end completion handler
			task.resume()
			while (!doneTransfer) { Thread.sleep(forTimeInterval: 0.0001) }
			if infoErr != .NoError { return infoErr }
			parseProperties(infomation: data)
			parseServers(information: data)
 		}// end if URL can allocated

		return ProgramInfoError.NoProgramError
	}// end getProgramInfomation

		// MARK: - Delegates
}// end class
