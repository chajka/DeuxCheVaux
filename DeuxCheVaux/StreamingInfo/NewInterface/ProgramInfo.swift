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

public struct XMLSocket {
	public var address: String
	public var port: Int

	static func == (lhs: XMLSocket, rhs: XMLSocket) -> Bool {
		return (lhs.address == rhs.address) && (lhs.port == rhs.port)
	}// end func ==
}// end struct XMLSocket

public struct MessageServer: Equatable {
	public let webSocket: URL?
	public let thread: String
	public let name: String?
	public let identifier: Int?

	static public func == (lhs: MessageServer, rhs: MessageServer) -> Bool {
		return (lhs.webSocket == rhs.webSocket) && (lhs.thread == rhs.thread)
	}// end func ==
}// end struct MessageServer

public enum SocialType: String, Codable {
	case community = "community"
	case channel = "channel"
	case official = "official"
}// end enum SocialType

public struct Room: Codable {
	let webSocketUri: URL
	let xmlSocketUri: URL?
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
	let thumbnailUrl: URL
}// end struct SocialGroup

public struct Broadcaster: Codable {
	let name: String
	let id: String
}// end struct Broadcaster

public enum MaxQuality: String, Codable {
	case highest = "6Mbps720p"
	case high = "2Mbps450p"
	case normal = "1Mbps450p"
	case low = "384kbps288p"
	case lowest = "192kbps288p"
}// end enum MaxQuality

public enum Orientation: String, Codable {
	case landscape = "Landscape"
	case portrait = "Portrait"
}// end enum Orientation

public struct StreamSetting: Codable {
	public let maxQuality: MaxQuality
	public let orientation: Orientation
}// end struct StreamSetting

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
	let streamSetting: StreamSetting
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
	public private(set) var thumbnailURL: URL!
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
		self.thumbnailURL = programInfo.socialGroup.thumbnailUrl
		for room: Room in programInfo.rooms {
			let webSocket: URL = room.webSocketUri
			let server: MessageServer = MessageServer(webSocket: webSocket, thread: room.threadId, name: room.name, identifier: room.id)
			servers.append(server)
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
					let webSocket: URL = room.webSocketUri
					let server: MessageServer = MessageServer(webSocket: webSocket, thread: room.threadId, name: room.name, identifier: room.id)
					servers.append(server)
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
