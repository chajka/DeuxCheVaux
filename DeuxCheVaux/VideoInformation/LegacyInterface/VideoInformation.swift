//
//  VideoInformation.swift
//  DeuxCheVaux
//
//  Created by Я Чайка on 2018/09/14.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

private enum VideoInfoTag: String {
	case title = "title"
	case description = "description"
	case time = "length"
	case view = "view_counter"
	case commentCount = "comment_num"
	case mylist = "mylist_counter"
	case tag = "tag"
}// end enum VideoInfoTag

private let InfoQueryAPI: String = "http://ext.nicovideo.jp/api/getthumbinfo/"

public final class VideoInformation: NSObject, XMLParserDelegate {
		// MARK:   Properties
	public let videoNumber: String
	public private(set) var title: String!
	public private(set) var time: String!
	public private(set) var videoDescription: String!
	public private(set) var viewCount: Int!
	public private(set) var commentCount: Int!
	public private(set) var myListCount: Int!
	public private(set) var tags: Array<String>

		// MARK: - Member variables
	private var parser: XMLParser!
	private let session: URLSession
	private var request: URLRequest!
	private var stringBuffer: String

		// MARK: - Constructor/Destructor
	public init (videoNumber video: String) {
		self.videoNumber = video
		session = URLSession(configuration: URLSessionConfiguration.default)
		tags = Array()
		stringBuffer = String()
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods\
	public func parse () -> Bool {
		loadData()
		parser.delegate = self
		let result: Bool = parser.parse()

		return result
	}// end parse

		// MARK: - Private methods
	private func loadData () {
		if let url = URL(string: InfoQueryAPI + videoNumber) {
			request = URLRequest(url: url)
			request.httpMethod = "GET"
			var doneTransfer: Bool = false
			let task: URLSessionDataTask = session.dataTask(with: request) { (dat, resp, err) in
				guard let data: Data = dat else { return }
				self.parser = XMLParser(data: data)
				doneTransfer = true
			}// end closure
			task.resume()
			while (!doneTransfer) { Thread.sleep(forTimeInterval: 0.001) }
		}// end optional checking
	}// end load data

		// MARK: - Delegates
	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		switch elementName {
		case .title:
			title = String(stringBuffer)
		case .description:
			videoDescription = String(stringBuffer)
		case .time:
			time = String(stringBuffer)
		case .view:
			viewCount = Int(stringBuffer)
		case .commentCount:
			commentCount = Int(stringBuffer)
		case .mylist:
			myListCount = Int(stringBuffer)
		case .tag:
			tags.append(String(stringBuffer))
		default:
			break
		}// end switch
	}// end parser did end element

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end parser found charactors

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		stringBuffer = String()
	}// end parser did start element
}// end class VideoInformation
