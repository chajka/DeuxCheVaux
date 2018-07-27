//
//  PublishStatus.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

private enum PublishStatusKey: String {
	case token = "token"
	case vote = "allow_vote"
	case rtmpurl = "url"
	case stream = "stream"
	
	static func ~= (lhs: PublishStatusKey, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=
}// end enum PlayerStatusKey

private let publishStatusFormat: String = "http: //watch.live.nicovideo.jp/api/getpublishstatus?v="

public class PublishStatus: NSObject ,XMLParserDelegate {
	public var number: String!
	public var token: String!
	public var canVote: Bool!
	public var rtmpURL: String!
	public var streamKey: String!

	private var userSession: Array<HTTPCookie> = Array()

	private var stringBuffer: String = String()

	public init(program: String, cookies: Array<HTTPCookie>) {
		userSession = cookies
		super.init()
		getPublishStatus(programNumber: program)
	}// end init

	func getPublishStatus(programNumber: String) -> Void {
		let publishStatusURLString: String = publishStatusFormat + programNumber
		if let publishStatusURL: URL = URL(string: publishStatusURLString) {
			let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
			var request = URLRequest(url: publishStatusURL)
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
			if let publishStatusParser: XMLParser = parser {
				publishStatusParser.delegate = self
				publishStatusParser.parse()
			}// end if parser can allocate
		}// end if url is not empty
	}// end func getPublishStatus

	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		switch elementName {
		case .programNumber:
			number = String(stringBuffer)
		case .token:
			token = String(stringBuffer)
		case .vote:
			canVote = stringBuffer == "1" ? true : false
		case .rtmpurl:
			rtmpURL = String(stringBuffer)
		case .stream:
			streamKey = String(stringBuffer)
		default:
			break
		}
	}// end func parser didEndElement
	
	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [: ]) {
		stringBuffer = String()
	}// end function parser didStartElement
	
	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end func parser foundCharracters
}// end class PublishStatus
