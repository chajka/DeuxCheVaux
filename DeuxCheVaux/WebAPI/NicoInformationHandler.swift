//
//  NicoNicoInformationFetcher.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/12.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

public typealias IdentifierHandler = (String, UserLanguage) -> Void
public typealias NicknameHandler = (String?) -> Void
public typealias ThumbnailHandler = (NSImage?) -> Void
public typealias RawDataHandler = (Data?, URLResponse?, Error?) -> Void
public typealias CurrentProgramsHandler = (Array<Program>) -> Void

fileprivate let UnknownNickname = "Unknown User"
fileprivate let NicknameNodeName: String = "nickname"
fileprivate let CouldNotParse = "Could not parse"

fileprivate let NicknameAPIFormat: String = "https://api.live2.nicovideo.jp/api/v1/user/nickname?userId="
fileprivate let ThumbnailAPIFormat: String = "https://secure-dcdn.cdn.nimg.jp/nicoaccount/usericon/%@/%@.jpg"
fileprivate let ChannelThumbnailApi: String = "https://secure-dcdn.cdn.nimg.jp/comch/channel-icon/128x128/%@.jpg"
fileprivate let NicoNicoMyPageURL: String = "https://www.nicovideo.jp/my/top"
fileprivate let FollowingProgramsFormat: String = "https://live.nicovideo.jp/api/relive/notifybox.content"

fileprivate let IdentifierFinderRegex: String = "user.user_id = parseInt\\('(\\d+)\\)', 10\\)"
fileprivate let PremiumFinderRegex: String = "user.member_status = '(\\w+)';"
fileprivate let LanguageFinderRegex: String = "user.ui_lang = '(.*?)';"

fileprivate enum CurrentLanguage: String {
	case Japanese = "ja-jp"
	case Chinese = "zh-tw"
	case English = "en-us"
}// end enum CurrentLanguage

fileprivate let Premium: String = "premium"

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

fileprivate struct UserProgramInfo: Codable {
	let ownerIdentifier: String
	let title: String
	let thumnailURL: String
	let thumbnailLinkURL: String
	let communityName: String
	let elapsedTime: Int
	let providerType: ProviderType

	enum ProviderType: String, Codable {
		case channel = "channel"
		case community = "community"
	}// end enum ProviderType

	private enum CodingKeys: String, CodingKey {
		case ownerIdentifier = "id"
		case title
		case thumnailURL = "thumbnail_url"
		case thumbnailLinkURL = "thumbnail_link_url"
		case communityName = "community_name"
		case elapsedTime = "elapsed_time"
		case providerType = "provider_type"
	}// end enum CodingKeys

	init (from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		ownerIdentifier = try container.decode(String.self, forKey: .ownerIdentifier)
		title = try container.decode(String.self, forKey: .title)
		thumnailURL = try container.decode(String.self, forKey: .thumnailURL)
		thumbnailLinkURL = try container.decode(String.self, forKey: .thumbnailLinkURL)
		communityName = try container.decode(String.self, forKey: .communityName)
		elapsedTime = try container.decode(Int.self, forKey: .elapsedTime)
		providerType = ProviderType(rawValue: try container.decode(String.self, forKey: .providerType))!
	}// end init
}// end struct UserProgramInfo

fileprivate struct UserPrograms: Codable {
	let meta: MetaInformation
	let data: NotifyContent

	struct NotifyContent: Codable {
		let notifyboxContent: Array<UserProgramInfo>
		let totalPage: Int

		private enum CodingKeys: String, CodingKey {
			case notifyboxContent = "notifybox_content"
			case totalPage = "total_page"
		}// end enum CodingKeys
	}// end struct NotifyContent
}// end struct UserPrograms

public struct Program {
	public let program: String
	public let title: String
	public let community: String
	public let owner: String
	public let thumbnail: NSImage?
}// end struct Program

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

	public func myUserIdentifier (with handler: @escaping IdentifierHandler) -> Void {
		guard let url = URL(string: NicoNicoMyPageURL) else { handler("", .ja); return }
		let request: URLRequest = makeRequest(url: url, method: .get)
		var userIdentifier: String = ""
		var userLanguage: UserLanguage = .ja
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(userIdentifier, userLanguage) }
			guard let data: Data = dat else { return }
			if let htmlSource: String = String(data: data, encoding: .utf8) {
				let htmlRange: NSRange = NSRange(location: 0, length: htmlSource.count)
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: IdentifierFinderRegex, options: NSRegularExpression.Options.caseInsensitive) {
					if let result: NSTextCheckingResult = regex.firstMatch(in: htmlSource, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: htmlRange) {
						let range: NSRange = result.range(at: 1)
						userIdentifier = (htmlSource as NSString).substring(with: range)
					}// end optional binding check for founded regex
				}// end optional binding check for compile regex
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: PremiumFinderRegex, options: NSRegularExpression.Options.caseInsensitive) {
					if let result: NSTextCheckingResult = regex.firstMatch(in: htmlSource, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: htmlRange) {
						let range: NSRange = result.range(at: 1)
						if Premium == (htmlSource as NSString).substring(with: range) {
							userIsPremium = true
						}// end if found string is premium
					}// end optional binding check for founded regex
				}// end optional binding check for compile regex
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: LanguageFinderRegex, options: NSRegularExpression.Options.caseInsensitive) {
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
		}// end completion handler closure
		task.resume()
	}// end myUserIdentifier

	public func fetchNickName (forIdentifier userIdentifieer: String) -> String? {
		if let nickname = fetchNickname(from: userIdentifieer) {
			return nickname
		}// end if

		return UnknownNickname
	}// end fetchNickName

	public func fetchNickname (of userIdentifier: String, with handler: @escaping NicknameHandler) -> Void {
		guard let url = URL(string: NicknameAPIFormat + userIdentifier) else { handler(nil); return }
		let request: URLRequest = makeRequest(url: url, method: .get)
		var nickname: String? = nil
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(nickname) }
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
	}// end fetchNickname

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

	public func thumbnail (identifieer userIdentifer: String, with handler: @escaping ThumbnailHandler) -> Void {
		let prefix: String = String(userIdentifer.prefix(userIdentifer.count - 4))
		let urlString: String = String(format: ThumbnailAPIFormat, prefix, userIdentifer)
		var thumbnail: NSImage? = nil
		guard let url: URL = URL(string: urlString) else { handler(thumbnail); return }// end guard url initialize failed
		let request: URLRequest = makeRequest(url: url, method: .get)
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(thumbnail) }
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else { return }
			thumbnail = image
		}// end closure
		task.resume()
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

	public func communityThumbnail (_ url: URL, with handler: @escaping ThumbnailHandler) -> Void {
		let request: URLRequest = makeRequest(url: url, method: .get)
		var thumbnail: NSImage? = nil
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(thumbnail) }
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else { return }
			thumbnail = image
		}// end completion handler closure
		task.resume()
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

	public func channelThumbnail (of channel: String, with handler: @escaping ThumbnailHandler) -> Void {
		let urlString: String = String(format: ChannelThumbnailApi, channel)
		guard let url: URL = URL(string: urlString) else { handler(nil); return }
		let request: URLRequest = makeRequest(url: url, method: .get)
		var thumbnail: NSImage? = nil
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(thumbnail) }
			guard let data: Data = dat, let image: NSImage = NSImage(data: data) else { return }
			thumbnail = image
		}// end completion handler closure
		task.resume()
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

	public func rawData (ofURL url: URL, httpMethod method: HTTPMethod = .get, HTTPBody body: Data? = nil, contentsType type: String? = nil, with handler: @escaping RawDataHandler) -> Void {
		var request: URLRequest = makeRequest(url: url, method: method)
		if let body: Data = body, let type: String = type {
			request.addValue(type, forHTTPHeaderField: ContentTypeKey)
			request.httpBody = body
		}// end optional binding check for body and its content type
		let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, resp: URLResponse?, err: Error?) in
			handler(data, resp, err)
		}// end completion handler closure
		task.resume()
	}// end rawData

	public func currentPrograms () -> Array<Program> {
		let url: URL = URL(string: FollowingProgramsFormat)!
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let request: URLRequest = makeRequest(url: url, method: .get)
		var programs: Array<Program> = Array()
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() }
			guard let data: Data = dat, let info: UserPrograms = try? JSONDecoder().decode(UserPrograms.self, from: data) else { return }
			let currentPrograms: Array<UserProgramInfo> = info.data.notifyboxContent
			for prog: UserProgramInfo in currentPrograms {
				let liveNumber: String = URL(string: prog.thumbnailLinkURL)?.lastPathComponent ?? ""
				let title: String = prog.title
				let community: String = prog.communityName
				let owner: String = prog.ownerIdentifier
				let thumb: NSImage? = NSImage(contentsOf: URL(string: prog.thumnailURL)!)
				let program: Program = Program(program: liveNumber, title: title, community: community, owner: owner, thumbnail: thumb)
				programs.append(program)
			}// end foreach all program informations
		}// end current programs completion handler closure
		task.resume()
		let _: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)

		return programs
	}// end currentPrograms

	public func currentPrograms (with handler: @escaping CurrentProgramsHandler) -> Void {
		let url: URL = URL(string: FollowingProgramsFormat)!
		let request: URLRequest = makeRequest(url: url, method: .get)
		var programs: Array<Program> = Array()
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(programs) }
			guard let data: Data = dat, let info: UserPrograms = try? JSONDecoder().decode(UserPrograms.self, from: data) else { return }
			let currentPrograms: Array<UserProgramInfo> = info.data.notifyboxContent
			for prog: UserProgramInfo in currentPrograms {
				let liveNumber: String = URL(string: prog.thumbnailLinkURL)?.lastPathComponent ?? ""
				let title: String = prog.title
				let community: String = prog.communityName
				let owner: String = prog.ownerIdentifier
				let thumb: NSImage? = NSImage(contentsOf: URL(string: prog.thumnailURL)!)
				let program: Program = Program(program: liveNumber, title: title, community: community, owner: owner, thumbnail: thumb)
				programs.append(program)
			}// end foreach all program informations
		}// end current programs completion handler closure
		task.resume()
	}// end currentPrograms

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
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: IdentifierFinderRegex, options: NSRegularExpression.Options.caseInsensitive) {
					if let result: NSTextCheckingResult = regex.firstMatch(in: htmlSource, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: htmlRange) {
						let range: NSRange = result.range(at: 1)
						userIdentifier = (htmlSource as NSString).substring(with: range)
					}// end optional binding check for founded regex
				}// end optional binding check for compile regex
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: PremiumFinderRegex, options: NSRegularExpression.Options.caseInsensitive) {
					if let result: NSTextCheckingResult = regex.firstMatch(in: htmlSource, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: htmlRange) {
						let range: NSRange = result.range(at: 1)
						if Premium == (htmlSource as NSString).substring(with: range) {
							userIsPremium = true
						}// end if found string is premium
					}// end optional binding check for founded regex
				}// end optional binding check for compile regex
				if let regex: NSRegularExpression = try? NSRegularExpression(pattern: LanguageFinderRegex, options: NSRegularExpression.Options.caseInsensitive) {
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
