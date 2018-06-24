//
//  PlayerStatus.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

enum PlayerStatusKey:String {
	case programNumber = "id"
	case programTitle = "title"
	case programDescription = "description"
	case socialType = "provider_type"
	case communityName = "default_community"
	case ownerFlag = "is_owner"
	case ownerIdentifier = "owner_id"
	case ownerName = "owner_name"
	case baseTime = "base_time"
	case listenerIdentifier = "user_id"
	case listenerName = "nickname"
	case listenerIsPremium = "is_premium"
	case listenerLanguage = "userLanguage"

	static func ~= (lhs:PlayerStatusKey, rhs:String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=
}// end enum PlayerStatusKey

public enum SocialType:String {
	case community = "community"
	case channel = "channel"
	case official = "official"

	static func ~= (lhs:SocialType, rhs:String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=

	static func == (lhs:SocialType, rhs:String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ==
}// end enum SocialType

public enum UserLanguage:String {
	case ja = "ja-jp"
	case zh = "zh-tw"
	case en = "en-us"
	
	static func ~= (lhs:UserLanguage, rhs:String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=
	
	static func == (lhs:UserLanguage, rhs:String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ==
}

let playerStatusFormat:String = "http://watch.live.nicovideo.jp/api/getplayerstatus?v="

private let VIPPassString:String = "\0xe3\0x83\0x90\0xe3\0x83\0x83\0xe3\0x82\0xaf\0xe3\0x82\0xb9\0xe3\0x83\0x86\0xe3\0x83\0xbc\0xe3\0x82\0xb8\0xe3\0x83\0x91\0xe3\0x82\0xb9"

class PlayerStatus: NSObject , XMLParserDelegate {
	public var number:String!
	public var title:String!
	public var desc:String!
	public var socialType:SocialType!
	public var community:String!
	public var isOwner:Bool!
	public var ownerIdentifier:String!
	public var ownerName:String!
	public var baseTime:Date!

	public var listenerIdentifier:String!
	public var listenerName:String!
	public var listenerIsPremium:Bool!
	public var listenerLanguage:UserLanguage!

	var userSession:Array<HTTPCookie>
	var stringBuffer:String = String()

	init(program:String, cookies:Array<HTTPCookie>) {
		userSession = cookies
		super.init()
		getPlayerStatus(programNumber: program)
	}// end init

	func getPlayerStatus(programNumber:String) -> Void {
		let playerStatusURLString:String = playerStatusFormat + programNumber
		if let playerStatusURL:URL = URL(string: playerStatusURLString) {
			let session:URLSession = URLSession(configuration: URLSessionConfiguration.default)
			var request = URLRequest(url: playerStatusURL)
			var parser:XMLParser?
			var recievieDone:Bool = false
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: userSession)
			let task:URLSessionDataTask = session.dataTask(with: request) { (dat, req, err) in
				guard let data = dat else { return }
				parser = XMLParser(data: data)
				recievieDone = true
			}// end closure
			task.resume()
			while !recievieDone { Thread.sleep(forTimeInterval: 0.1) }
			if let playerStatusParser:XMLParser = parser {
				playerStatusParser.delegate = self
				playerStatusParser.parse()
			}
		}// end if url is not empty
	}// end function getPlayerStatus

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
			if let unixTime:TimeInterval = baseTimeInterval {
				baseTime = Date(timeIntervalSince1970: unixTime)
			}// end unix time string can convert unix time
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
		default:
			break
		}// end switch case by element name
	}// end func parser didEndElement

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		stringBuffer = String()
	}// end function parser didStartElement

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end func parser foundCharracters
}// end class PlayerStatus
