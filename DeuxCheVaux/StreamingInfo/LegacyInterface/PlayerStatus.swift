//
//  PlayerStatus.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

public struct XMLSocket {
	public var address: String
	public var port: Int

	static func == (lhs: XMLSocket, rhs: XMLSocket) -> Bool {
		return (lhs.address == rhs.address) && (lhs.port == rhs.port)
	}// end func ==
}// end struct XMLSocket

public struct MessageServer: Equatable {
	let XMLSocet: XMLSocket
	let WebSocket: URL?
	let thread: String
	let name: String?
	let identifier: Int?

	static public func == (lhs: MessageServer, rhs: MessageServer) -> Bool {
		return (lhs.XMLSocet == rhs.XMLSocet) && (lhs.WebSocket == rhs.WebSocket) && (lhs.thread == rhs.thread)
	}// end func ==
}// end struct MessageServer

public enum SocialType: String, Codable {
	case community = "community"
	case channel = "channel"
	case official = "official"
}// end enum SocialType

public enum UserLanguage: String {
	case ja = "ja-jp"
	case zh = "zh-tw"
	case en = "en-us"
}// end public enum UserLanguage

enum PlayerStatusKey: String {
	case programNumber = "id"
	case programTitle = "title"
	case programDescription = "description"
	case socialType = "provider_type"
	case communityName = "default_community"
	case ownerFlag = "is_owner"
	case ownerIdentifier = "owner_id"
	case ownerName = "owner_name"
	case baseTime = "base_time"
	case startTime = "start_time"
	case endTime = "end_time"
	case communityThumbail = "thumb_url"
	case listenerIdentifier = "user_id"
	case listenerName = "nickname"
	case listenerIsPremium = "is_premium"
	case listenerLanguage = "userLanguage"
	case listenerIsVIP = "is_vip"
	case msAddress = "addr"
	case msPort = "port"
	case msThread = "thread"
	case messageServerList = "ms_list"
	case code = "code"
}// end enum PlayerStatusKey

let playerStatusFormat: String = "https://watch.live.nicovideo.jp/api/getplayerstatus?v="

public final class PlayerStatus: NSObject , XMLParserDelegate {
		// MARK: class method
	public static func urlForProgram (program programNumber: String) -> URL {
		return URL(string: playerStatusFormat + programNumber)!
	}// end programURL

		// MARK: - Properties
	public private(set) var code: String?
	public private(set) var number: String!
	public private(set) var title: String!
	public private(set) var desc: String!
	public private(set) var socialType: SocialType!
	public private(set) var community: String!
	public private(set) var isOwner: Bool!
	public private(set) var ownerIdentifier: String!
	public private(set) var ownerName: String!
	public private(set) var baseTime: Date!
	public private(set) var startTime: Date!
	public private(set) var endTime: Date!
	public private(set) var communityThumbnaiURL: URL!

	public private(set) var listenerIdentifier: String!
	public private(set) var listenerName: String!
	public private(set) var listenerIsPremium: Bool!
	public private(set) var listenerLanguage: UserLanguage!
	public private(set) var listenerIsVIP: Bool!

	public private(set) var messageServers: Array<MessageServer> = Array()

		// MARK: - Member variables
	private var stringBuffer: String = String()

	private var server: String!
	private var port: Int!
	private var thread: String!

		// MARK: - Constructor/Destructor
	public init(xmlData data: Data) throws {
		super.init()
		let parser: XMLParser = XMLParser(data: data)
		parser.delegate = self
		_ = parser.parse()
		if checkSuccessParse() == false { throw StatusError.XMLParseError }
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Private methods
	private func checkSuccessParse () -> Bool {
		guard let _ = number else { return false }
		guard let _ = title else { return false }
		guard let _ = desc else { return false }
		guard let _ = socialType else { return false }
		guard let _ = community else { return false }
		guard let _ = isOwner else { return false }
		guard let _ = ownerIdentifier else { return false }
		guard let _ = ownerName else { return false }
		guard let _ = baseTime else { return false }
		guard let _ = startTime else { return false }
		guard let _ = endTime else { return false }
		guard let _ = communityThumbnaiURL else { return false }
		guard let _ = listenerIdentifier else { return false }
		guard let _ = listenerName else { return false }
		guard let _ = listenerIsPremium else { return false }
		guard let _ = listenerLanguage else { return false }
		guard let _ = listenerIsVIP else { return false }

		return true
	}// end check success parse

		// MARK: - Delegates
			// MARK: NSXMLParserDelegate
	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if let element: PlayerStatusKey = PlayerStatusKey(rawValue: elementName) {
			switch element {
			case .programNumber:
				number = String(stringBuffer)
			case .programTitle:
				title = String(stringBuffer)
			case .programDescription:
				desc = String(stringBuffer)
			case .socialType:
				if let social: SocialType = SocialType(rawValue: stringBuffer) {
					switch social {
					case .community:
						socialType = .community
					case .channel:
						socialType = .channel
					case .official:
						socialType = .official
					}// end switch case by provider type
				} else {
					socialType = .community
				}// end optional binding for string buffer is much to member of SocialType
			case .communityName:
				community = String(stringBuffer)
			case .ownerFlag:
				isOwner = stringBuffer == "1" ? true : false
			case .ownerIdentifier:
				ownerIdentifier = String(stringBuffer)
			case .ownerName:
				ownerName = String(stringBuffer)
			case .baseTime:
				let baseTimeStr = stringBuffer
				let baseTimeInterval = TimeInterval(baseTimeStr)
				if let unixTime: TimeInterval = baseTimeInterval {
					baseTime = Date(timeIntervalSince1970: unixTime)
				}// end unix time string can convert unix time
			case .startTime:
				let startTimeStr = stringBuffer
				let startTimeInterval = TimeInterval(startTimeStr)
				if let unixTime: TimeInterval = startTimeInterval {
					startTime = Date(timeIntervalSince1970: unixTime)
				}// end unix time string can convert unix time
			case .endTime:
				let endTimeStr = stringBuffer
				let endTimeInterval = TimeInterval(endTimeStr)
				if let unixTime: TimeInterval = endTimeInterval {
					endTime = Date(timeIntervalSince1970: unixTime)
				}// end unix time string can convert unix time
			case .communityThumbail:
				communityThumbnaiURL = URL(string: stringBuffer)
			case .listenerIdentifier:
				listenerIdentifier = String(stringBuffer)
			case .listenerName:
				listenerName = String(stringBuffer)
			case .listenerIsPremium:
				listenerIsPremium = stringBuffer == "1" ? true : false
			case .listenerLanguage:
				if let userLang: UserLanguage = UserLanguage(rawValue: stringBuffer) {
					switch userLang {
					case .ja:
						listenerLanguage = .ja
					case .zh:
						listenerLanguage = .zh
					case .en:
						listenerLanguage = .en
					}// end switch case by user language
				} else {
					listenerLanguage = .ja
				}// end if optional binding check for string value is match to user language
			case .listenerIsVIP:
				listenerIsVIP = stringBuffer == "1" ? true : false
			case .msAddress:
				server = String(stringBuffer)
			case .msPort:
				if let portNumber: Int = Int(stringBuffer) {
					port = portNumber
				}// end if port number is convert to integer
			case .msThread:
				thread = String(stringBuffer)
				let xmlserver: XMLSocket = XMLSocket(address: server, port: port)
				let ms: MessageServer = MessageServer(XMLSocet: xmlserver, WebSocket: nil, thread: thread, name: nil, identifier: nil)
				messageServers.append(ms)
			case .messageServerList:
				messageServers.removeFirst()
			case .code:
				code = stringBuffer
			}// end switch case by element name
		}// end if optional binding check for element name is member of PlayerStatusKey
	}// end func parser didEndElement

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [: ]) {
		stringBuffer = String()
	}// end function parser didStartElement

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end func parser foundCharracters
}// end class PlayerStatus
