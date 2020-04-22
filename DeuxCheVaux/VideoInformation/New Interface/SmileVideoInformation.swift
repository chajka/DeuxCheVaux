//
//  SmileVideoInformation.swift
//  Charleston
//
//  Created by Я Чайка on 2019/06/07.
//  Copyright © 2019 Чайка. All rights reserved.
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

	static func ~= (lhs: VideoInfoTag, rhs: String) -> Bool {
		return lhs.rawValue ~= rhs ? true : false
	}// end ~=
}// end enum VideoInfoTag

internal struct MovieDescription: Codable {
	let id: String
	let length: Int
	let title: String
	let userId: String
}// end struct MovieDescription

private struct MovieInformation: Codable {
	let meta: MetaInformation
	let data: MovieDescription?
}// end struct MovieInfo

fileprivate let ContentsTimeout: Double = 2.0
fileprivate let ContentsAPI: String = "https://live2.nicovideo.jp/unama/tool/v1/contents/"

public final class SmileVideoInformation: HTTPCommunicatable {
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
	private var stringBuffer: String

		// MARK: - Constructor/Destructor
	public init (videoNumber video: String, cookies cookie: Array<HTTPCookie>) {
		videoNumber = video
		tags = Array()
		stringBuffer = String()
		super.init(cookie)
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods\
	public func parse () -> Bool {
		let result: Bool = checkContents()

		return result
	}// end parse

		// MARK: - Private methods
	private func checkContents () -> Bool {
		if let contentsAPIURL: URL = URL(string: ContentsAPI) {
			request = URLRequest(url: contentsAPIforcurrentVideo, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 0.1)
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
			request.method = .get
			let contentsAPIforcurrentVideo: URL = contentsAPIURL.appendingPathComponent(videoNumber)
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			let task: URLSessionDataTask = session.dataTask(with: request) { [unowned self] (dat, resp, err) in
				guard let data: Data = dat else { return }
				do {
					let description: MovieInformation = try JSONDecoder().decode(MovieInformation.self, from: data)
					if description.meta.errorCode == "OK" {
						if let desc: MovieDescription = description.data {
							self.title = desc.title
							let length: String = String(format: "%4.2f", Float(desc.length / 60))
							self.time = "\(length) min"
						}// end optional binding check for data
					}// end if
				} catch let error {
					print(error.localizedDescription)
				}// end do try - catch json serializatioon
				semaphore.signal()
			}// end closure
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + ContentsTimeout)
			if timeout == DispatchTimeoutResult.success { return true }
		}// end optional binding check for make contents api base url

		return false
	}// end checkContents

		// MARK: - Delegates
}// end class VideoInformation
