//
//  ProgramInfo.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/08/19.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

fileprivate let ProgramInfoFormat: String = "https://live2.nicovideo.jp/watch/"
fileprivate let ProgramInfoSuffix: String = "/programinfo"

public enum UserLanguage: String, Codable {
	case ja = "ja-jp"
	case zh = "zh-tw"
	case en = "en-us"
}// end public enum UserLanguage

public struct Room: Codable {
	let webSocketUri: String
	let xmlSocketUri: String
	let name: String
	let id: Int
	let threadId: String
}// end struct Room

public struct SocialGroup: Codable {
	let type: SocialType
	let id: String
	let name: String
	let communityLevel: Int?
	let ownerName: String?
}// end struct SocialGroup

public struct Broadcaster: Codable {
	let name: String
	let id: String
}// end struct Broadcaster

public struct ProgramInformation: Codable {
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

public struct ProgramInfoJSON: Codable {
	public let meta: MetaInformation
	public let data: ProgramInformation?
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
	case ended = "end"
}// end enum ProgramStatus

public struct Social {
	public let name: String
	public let identifier: String
	public let level: Int?
	public let type: SocialType
	public let ownerName: String?
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

public final class ProgramInfo: NSObject {
		// MARK: class method
	public static func urlForProgram (program programNumber: String) -> URL {
		return URL(string: ProgramInfoFormat + programNumber + ProgramInfoSuffix)!
	}// end programURL

		// MARK:   Outlets
		// MARK: - Properties
	public private(set) var title: String!
	public private(set) var ownerName: String!
	public private(set) var ownerIdentifier: String!
	public private(set) var social: Social!
	public private(set) var status: ProgramStatus!
	public private(set) var isMemberOnly: Bool!
	public private(set) var categories: Array<String>!
	public private(set) var baseTime: Date!
	public private(set) var startTime: Date!
	public private(set) var endTime: Date!
	public private(set) var programDesc: String!
	public private(set) var programDescription: NSAttributedString!
	public private(set) var broadcaster: BroadcasterInfo!
	public private(set) var canNicoAd: Bool!
	public private(set) var servers: Array<MessageServer> = Array()

		// MARK: - Member variables
		// MARK: - Constructor/Destructor
	public init(data: Data) throws {
		super.init()
		let result: ProgramInfoError = decodeData(data: data)
		if result != .NoError { throw result }
	}// end init

	public init (_ programInfo: ProgramInformation) {
		title = programInfo.title
		ownerName = programInfo.broadcaster.name
		ownerIdentifier = programInfo.broadcaster.id
		let social: SocialGroup = programInfo.socialGroup
		self.social = Social(name: social.name, identifier: social.id, level: social.communityLevel, type: programInfo.socialGroup.type, ownerName: social.ownerName)
		status = programInfo.status
		isMemberOnly = programInfo.isMemberOnly
		categories = programInfo.categories
		baseTime = Date(timeIntervalSince1970: programInfo.vposBaseAt)
		startTime = Date(timeIntervalSince1970: programInfo.beginAt)
		endTime = Date(timeIntervalSince1970: programInfo.endAt)
		programDesc = programInfo.description
		broadcaster = BroadcasterInfo(name: programInfo.broadcaster.name, identifier: programInfo.broadcaster.id)
		for room: Room in programInfo.rooms {
			if let webSocket: URL = URL(string: room.webSocketUri), let xml: URL = URL(string: room.xmlSocketUri) {
				if let xmlHost: String = xml.host, let port: Int = xml.port {
					let xmlSocket: XMLSocket = XMLSocket(address: xmlHost, port: port)
					let server: MessageServer = MessageServer(XMLSocket: xmlSocket, webSocket: webSocket, thread: room.threadId, name: room.name, identifier: room.id)
					servers.append(server)
				}// end optional binding check for get xml socket server addreess and port
			}// end optional binding check for make url for web socket and xml socket
		}// end foreach rooms
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Private methods
	private func decodeData (data: Data) -> ProgramInfoError {
		do {
			let decoder: JSONDecoder = JSONDecoder()
			let result: ProgramInfoJSON = try decoder.decode(ProgramInfoJSON.self, from: data)
			if let programInfo: ProgramInformation = result.data {
				title = programInfo.title
				ownerName = programInfo.broadcaster.name
				ownerIdentifier = programInfo.broadcaster.id
				if let social: SocialGroup = result.data?.socialGroup {
					self.social = Social(name: social.name, identifier: social.id, level: social.communityLevel, type: programInfo.socialGroup.type, ownerName: social.ownerName)
				}// end optional binding for social type is much to social type
				status = programInfo.status
				isMemberOnly = programInfo.isMemberOnly
				categories = programInfo.categories
				baseTime = Date(timeIntervalSince1970: programInfo.vposBaseAt)
				startTime = Date(timeIntervalSince1970: programInfo.beginAt)
				endTime = Date(timeIntervalSince1970: programInfo.endAt)
				programDesc = programInfo.description
				broadcaster = BroadcasterInfo(name: programInfo.broadcaster.name, identifier: programInfo.broadcaster.id)
				for room: Room in programInfo.rooms {
					if let webSocket: URL = URL(string: room.webSocketUri), let xml: URL = URL(string: room.xmlSocketUri) {
						if let xmlHost: String = xml.host, let port: Int = xml.port {
							let xmlSocket: XMLSocket = XMLSocket(address: xmlHost, port: port)
							let server: MessageServer = MessageServer(XMLSocket: xmlSocket, webSocket: webSocket, thread: room.threadId, name: room.name, identifier: room.id)
							servers.append(server)
						}// end optional biniding check for get xml socket server addreess and port
					}// end optional binding check for make url for web socket and xml socket
				}// end foreach rooms
			}// end if optional check for data
		} catch let error {
			print(error.localizedDescription)
			return ProgramInfoError.JSONParseError
		}// end try - catch JSONSerialization exception

		return ProgramInfoError.NoError
	}// end decodeData

		// MARK: - Delegates
}// end class
