//
//  NicoNicoInformationFetcher.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/12.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

fileprivate let UnknownNickname = "Unknown User"
fileprivate let NicknameNodeName: String = "nickname"
fileprivate let CouldNotParse = "Could not parse"

fileprivate let NicknameAPIFormat: String = "https://api.live2.nicovideo.jp/api/v1/user/nickname?userId="
fileprivate let ThumbnailAPIFormat: String = "https://secure-dcdn.cdn.nimg.jp/nicoaccount/usericon/%@/%@.jpg"
fileprivate let ChannelThumbnailApi: String = "https://secure-dcdn.cdn.nimg.jp/comch/channel-icon/128x128/%@.jpg"

fileprivate struct data: Codable {
	let id: String
	let nickname: String
}// end struct data

fileprivate struct error: Codable {
	let code: Int
	let messae: String?
}// end struct error

fileprivate struct Nickname: Codable {
	let data: data?
	let err: error?
}// end struct Nickname

public final class NicoInformationHandler: NSObject {
		// MARK:   Outlets
		// MARK: - Properties
		// MARK: - Member variables

		// MARK: - Constructor/Destructor
	public override init (_ cookie: Array<HTTPCookie>) {
		super.init(cookie)
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
	public func fetchNickName (forIdentifier userIdentifieer: String) -> String? {
		if let nickname = fetchNickname(from: userIdentifieer) {
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
	private func fetchNickname (from identifier: String) -> String? {
		guard let url = URL(string: NicknameAPIFormat + identifier) else { return nil }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var nickname: String? = nil
		let task: URLSessionTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard
			do {
				let nicknameJSON: Nickname = try JSONDecoder().decode(Nickname.self, from: data)
				if let nick: data = nicknameJSON.data {
					nickname = nick.nickname
				}// end optional binding
			} catch let error {
				print(error.localizedDescription)
			}// end try - catch error of decode json data
			semaphore.signal()
		}// end url request closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { nickname = nil }

		return nickname
	}// end fetchNickname from NicoNico API (New at 3/4/2020)

		// MARK: - Delegates
}// end NicoNicoInformationFetcher
