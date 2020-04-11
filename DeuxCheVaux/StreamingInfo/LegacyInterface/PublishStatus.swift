//
//  PublishStatus.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

private enum PublishStatusKey: String {
	case programNumber = "id"
	case token = "token"
	case vote = "allow_vote"
	case rtmpurl = "url"
	case stream = "stream"
}// end enum PlayerStatusKey

private let publishStatusFormat: String = "https://watch.live.nicovideo.jp/api/getpublishstatus?v="

public final class PublishStatus: NSObject ,XMLParserDelegate {
		// MARK: class method
	public static func urlForProgram (program programNumber: String) -> URL {
		return URL(string: publishStatusFormat + programNumber)!
	}// end programURL

		// MARK: - Properties
	public var number: String!
	public var token: String!
	public var canVote: Bool!
	public var rtmpURL: String!
	public var streamKey: String!

		// MARK: - Member variables
	private var stringBuffer: String = String()

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
		// MARK: - Internal methods
		// MARK: - Private methods
	private func checkSuccessParse () -> Bool {
		guard let _ = number else { return false }
		guard let _ = token else { return false }
		guard let _ = canVote else { return false }
		guard let _ = rtmpURL else { return false }
		guard let _ = streamKey else { return false }

		return true
	}// end check success parse

		// MARK: - Delegates
			// MARK: XMLParser Delegatte
	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if let element: PublishStatusKey = PublishStatusKey(rawValue: elementName) {
			switch element {
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
			}// end switch case by element namee
		}// end optional binding check for element name match to PublishStatusKey
	}// end func parser didEndElement

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [: ]) {
		stringBuffer = String()
	}// end function parser didStartElement

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end func parser foundCharracters
}// end class PublishStatus
