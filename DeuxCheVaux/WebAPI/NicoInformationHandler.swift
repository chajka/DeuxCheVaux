//
//  NicoNicoInformationFetcher.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/12.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

fileprivate let RequestTimeOut: TimeInterval = 2.0
fileprivate let DataTimeOut: TimeInterval = 2.0
fileprivate let Timeout: Double = 2.0
fileprivate let UnknownNickname = "Unknown User"
fileprivate let NicknameNodeName: String = "nickname"
fileprivate let CouldNotParse = "Could not parse"

fileprivate let NicknameAPIFormat: String = "https://seiga.nicovideo.jp/api/user/info?id="
fileprivate let ThumbnailAPIFormat: String = "https://secure-dcdn.cdn.nimg.jp/nicoaccount/usericon/%@/%@.jpg"
fileprivate let ChannelThumbnailApi: String = "https://secure-dcdn.cdn.nimg.jp/comch/channel-icon/128x128/%@.jpg"

public final class NicoInformationHandler: NSObject {
		// MARK:   Outlets
		// MARK: - Properties
		// MARK: - Member variables
	private var session: URLSession
	private let cookies: Array<HTTPCookie>

		// MARK: - Constructor/Destructor
	public init (_ cookie: Array<HTTPCookie>) {
		let sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration.timeoutIntervalForRequest = RequestTimeOut
		sessionConfiguration.timeoutIntervalForResource = DataTimeOut
		sessionConfiguration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.onlyFromMainDocumentDomain
		session = URLSession(configuration: sessionConfiguration)
		self.cookies = cookie
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
	public func fetchNickName (forIdentifier userIdentifieer: String) -> String? {
		if let nickname = seigaNickName(fromSeigaAPI: userIdentifieer) {
			return nickname
		}// end if

		return UnknownNickname
	}// end fetchNickName

	public func thumbnail (identifieer userIdentifer: String, whenNoImage insteadImage: NSImage) -> NSImage {
		let prefix: String = String(userIdentifer.prefix(userIdentifer.count - 4))
		let urlString: String = String(format: ThumbnailAPIFormat, prefix, userIdentifer)
		guard let url: URL = URL(string: urlString) else { return insteadImage }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var thumbnail: NSImage = insteadImage
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else {
				semaphore.signal()
				return
			}// end guard
			thumbnail = image
			semaphore.signal()
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { thumbnail = insteadImage }

		return thumbnail
	}// end thumbnail

	public func communityThumbnail (_ url: URL, whenNoImage insteadImage: NSImage) -> NSImage {
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var thumbnail: NSImage = insteadImage
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else {
				semaphore.signal()
				return
			}// end guard
			thumbnail = image
			semaphore.signal()
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { thumbnail = insteadImage }

		return thumbnail
	}// end communityThumbnail

	public func channelThumbnail (channel: String, whenNoImage insteadImage: NSImage) -> NSImage {
		let urlString: String = String(format: ChannelThumbnailApi, channel)
		guard let url: URL = URL(string: urlString) else { return insteadImage }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var thumbnail: NSImage = insteadImage
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else {
				semaphore.signal()
				return
			}// end guard
			thumbnail = image
			semaphore.signal()
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { thumbnail = insteadImage }

		return thumbnail
	}// end channelThumbnail

	public func rawData (forURL url: URL, httpMethod method: HTTPMethod, HTTOBody body: Data? = nil, contentsType type: String? = nil) -> Data? {
		var rawData: Data? = nil
		var request: URLRequest = makeRequest(url: url, method: method)
		if let body: Data = body, let type: String = type {
			request.addValue(type, forHTTPHeaderField: ContentTypeKey)
			request.httpBody = body
		}// end optional binding for
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard else
			rawData = data
			semaphore.signal()
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { rawData = nil }

		return rawData
	}// end rawData

		// MARK: - Internal methods
		// MARK: - Private methods
	private func seigaNickName (fromSeigaAPI identifier: String) -> String? {
		guard let url = URL(string: NicknameAPIFormat + identifier) else { return nil }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var nickname: String? = nil
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard
			do {
				let seiga: XMLDocument = try XMLDocument(data: data, options: .documentTidyXML)
				guard let children: Array<XMLNode> = seiga.children?.first?.children?.first?.children else { throw NSError(domain: CouldNotParse, code: 0, userInfo: nil)}
				for child: XMLNode in children {
					if child.name == NicknameNodeName { nickname = child.stringValue }
				}// end foreach children
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch
			semaphore.signal()
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { nickname = nil }

		return nickname
	}// end fetchNickname from seiga api

	private func makeRequest (url requestURL: URL, method requestMethod: HTTPMethod, contentsType type: String? = nil) -> URLRequest {
		let deuxCheVaux: DeuxCheVaux = DeuxCheVaux.shared
		let userAgent: String = deuxCheVaux.userAgent
		var request: URLRequest = URLRequest(url: requestURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(userAgent, forHTTPHeaderField: UserAgentKey)
		if let contentsType: String = type {
			request.addValue(contentsType, forHTTPHeaderField: ContentTypeKey)
		}// end optional binding check for contents type
		request.method = requestMethod
 
		return request
	}// end makeRequest

		// MARK: - Delegates
}// end NicoNicoInformationFetcher
