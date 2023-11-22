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

private let InfoQueryAPI: String = "https://ext.nicovideo.jp/api/getthumbinfo/"

public final class VideoInformation: HTTPCommunicatable, XMLParserDelegate {
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
	private var request: URLRequest!
	private var stringBuffer: String

		// MARK: - Constructor/Destructor
	public init (videoNumber video: String, for identifier: String) {
		self.videoNumber = video
		tags = Array()
		stringBuffer = String()
		super.init(with: identifier)
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
	private func loadData () async {
		if let url = URL(string: InfoQueryAPI + videoNumber) {
			request = URLRequest(url: url)
			request.method = .get
			do {
				let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
				self.parser = XMLParser(data: result.data)
			} catch let error {
				print(error.localizedDescription)
			}
		}// end optional checking
	}// end load data

		// MARK: - Delegates
	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if let element: VideoInfoTag = VideoInfoTag(rawValue: elementName) {
			switch element {
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
			}// end switch
		}// end optional binding check for element name is mutch need tag
	}// end parser did end element

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end parser found charactors

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		stringBuffer = String()
	}// end parser did start element
}// end class VideoInformation
