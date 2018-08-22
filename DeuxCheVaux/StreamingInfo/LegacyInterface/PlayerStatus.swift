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

public struct MessageServer {
	public var XMLSocet: XMLSocket
	public var WebSocket: URL?
	public var thread: String
	public var name: String?

	static func == (lhs: MessageServer, rhs: MessageServer) -> Bool {
		return (lhs.XMLSocet == rhs.XMLSocet) && (lhs.WebSocket == rhs.WebSocket) && (lhs.thread == rhs.thread)
	}// end func ==
}// end struct MessageServer

public enum SocialType: String {
	case community = "community"
	case channel = "channel"
	case official = "official"

	static func ~= (lhs: SocialType, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=

	static func == (lhs: SocialType, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ==
}// end enum SocialType

public enum UserLanguage: String {
	case ja = "ja-jp"
	case zh = "zh-tw"
	case en = "en-us"
	
	static func ~= (lhs: UserLanguage, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=
	
	static func == (lhs: UserLanguage, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ==
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
	
	static func ~= (lhs: PlayerStatusKey, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=
}// end enum PlayerStatusKey

let playerStatusFormat: String = "http://watch.live.nicovideo.jp/api/getplayerstatus?v="

public class PlayerStatus: NSObject , XMLParserDelegate {
		// MARK:   Outlets
		// MARK: - Properties
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
	private var userSession: Array<HTTPCookie>
	private var stringBuffer: String = String()
	
	private var server: String!
	private var port: Int!
	private var thread: String!
	
		// MARK: - Constructor/Destructor
	public init(program: String, cookies: Array<HTTPCookie>) {
		userSession = cookies
		super.init()
		getPlayerStatus(programNumber: program)
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Private methods
	private func getPlayerStatus(programNumber: String) -> Void {
		let playerStatusURLString: String = playerStatusFormat + programNumber
		if let playerStatusURL: URL = URL(string: playerStatusURLString) {
			let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
			var request = URLRequest(url: playerStatusURL)
			var parser: XMLParser?
			var recievieDone: Bool = false
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: userSession)
			let task: URLSessionDataTask = session.dataTask(with: request) { (dat, req, err) in
				guard let data = dat else { return }
				parser = XMLParser(data: data)
				recievieDone = true
			}// end closure
			task.resume()
			while !recievieDone { Thread.sleep(forTimeInterval: 0.1) }
			if let playerStatusParser: XMLParser = parser {
				playerStatusParser.delegate = self
				playerStatusParser.parse()
			}
		}// end if url is not empty
	}// end function getPlayerStatus

		// MARK: - Delegates
			// MARK: NSXMLParserDelegate
	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		switch elementName {
		case .programNumber:
			number = String(stringBuffer)
		case .programTitle:
			title = String(stringBuffer)
		case .programDescription:
			desc = String(stringBuffer)
		case .socialType:
			switch stringBuffer {
			case .community:
				socialType = .community
			case .channel:
				socialType = .channel
			case .official:
				socialType = .official
			default:
				socialType = .community
			}// end switch case by provider type
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
			switch stringBuffer {
			case .ja:
				listenerLanguage = .ja
			case .zh:
				listenerLanguage = .zh
			case .en:
				listenerLanguage = .en
			default:
				listenerLanguage = .ja
			}// end switch case by user language
		case .listenerIsVIP:
			listenerIsVIP = stringBuffer == "1" ? true : false
		case .msAddress:
			server = String(stringBuffer)
		case .msPort:
			if let portNumber: Int = Int(stringBuffer) {
				port = portNumber
			}
		case .msThread:
			thread = String(stringBuffer)
			let xmlserver: XMLSocket = XMLSocket(address: server, port: port)
			let ms: MessageServer = MessageServer(XMLSocet: xmlserver, WebSocket: nil, thread: thread, name: nil)
			messageServers.append(ms)
		case .messageServerList:
			messageServers.removeFirst()
		default:
			break
		}// end switch case by element name
	}// end func parser didEndElement

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [: ]) {
		stringBuffer = String()
	}// end function parser didStartElement

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end func parser foundCharracters
}// end class PlayerStatus
