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
fileprivate let NicoNicoMyPageURL: String = "https://www.nicovideo.jp/my/top"

fileprivate let IdentifierFindRegex: String = "<p class=\"accountNumber\">ID:<span>(\\d+)\\("
fileprivate let LanguageFindRegex: String = "<span class=\"currentType\">(.*?)</span>"

fileprivate enum CurrentLanguage: String {
	case Japanese = "\u{65E5}\u{672C}\u{8A9E}"
	case Chinese = "\u{4E2D}\u{6587}\u{20}\u{28}\u{7E41}\u{9AD4}\u{29}"
	case English = "English (US)"
}

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

public final class NicoInformationHandler: HTTPCommunicatable {
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
	public func myUserIdentifier () -> (identifier: String, language: UserLanguage) {
		return fetchMyUserID()
	}// end myUserIdentifier

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
			defer { semaphore.signal() }
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else { return }
			thumbnail = image
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
			defer { semaphore.signal() }
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else { return }
			thumbnail = image
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
			defer { semaphore.signal() }
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else { return }
			thumbnail = image
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
			defer { semaphore.signal() }
			guard let data: Data = dat else { return }
			rawData = data
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { rawData = nil }

		return rawData
	}// end rawData

		// MARK: - Internal methods
		// MARK: - Private methods
	private func fetchMyUserID () -> (identifier: String, language: UserLanguage) {
		guard let url = URL(string: NicoNicoMyPageURL) else { return ("", .ja) }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var userIdentifier: String? = nil
		var userLanguage: UserLanguage = .ja
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() }
			guard let data: Data = dat else { return }
			if let htmlSource: String = String(data: data, encoding: .utf8) {
				let htmlRange: NSRange = NSRange(location: 0, length: htmlSource.count)
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: IdentifierFindRegex, options: NSRegularExpression.Options.caseInsensitive) {
					if let result: NSTextCheckingResult = regex.firstMatch(in: htmlSource, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: htmlRange) {
						let range: NSRange = result.range(at: 1)
						userIdentifier = (htmlSource as NSString).substring(with: range)
					}// end optional binding check for founded regex
				}// end optional binding check for compile regex
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: LanguageFindRegex, options: NSRegularExpression.Options.caseInsensitive) {
					if let result: NSTextCheckingResult = regex.firstMatch(in: htmlSource, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: htmlRange) {
						let range: NSRange = result.range(at: 1)
						if let currentLanguage: CurrentLanguage = CurrentLanguage(rawValue: (htmlSource as NSString).substring(with: range)) {
							switch currentLanguage {
								case .Japanese:
									userLanguage = .ja
								case .Chinese:
									userLanguage = .zh
								case .English:
									userLanguage = .en
							}// end switch case by current language
						}// end optional binding check of String is member of CurrentLanguage enum
					}// end optional binding check of found regex
				}// end optional binding check for compile regex
			}// end optional binding check for fetch html source successed ?
		}// end completion handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(wallTimeout: DispatchWallTime.now() + Timeout)
		if timeout == .timedOut { return ("", .ja) }
		if let identifier: String = userIdentifier { return (identifier, userLanguage) }
		return ("", .ja)
	}// end fetchMyUserID

	private func fetchNickname (from identifier: String) -> String? {
		guard let url = URL(string: NicknameAPIFormat + identifier) else { return nil }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var nickname: String? = nil
		let task: URLSessionTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() }
			guard let data: Data = dat else { return }
			do {
				let nicknameJSON: Nickname = try JSONDecoder().decode(Nickname.self, from: data)
				if let nick: data = nicknameJSON.data {
					nickname = nick.nickname
				}// end optional binding
			} catch let error {
				print(error.localizedDescription)
			}// end try - catch error of decode json data
		}// end url request closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { nickname = nil }

		return nickname
	}// end fetchNickname from NicoNico API (New at 3/4/2020)

		// MARK: - Delegates
}// end NicoNicoInformationFetcher
