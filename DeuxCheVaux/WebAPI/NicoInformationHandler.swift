//
//  NicoNicoInformationFetcher.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/12.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

public typealias IdentifierHandler = (String, Bool, UserLanguage) -> Void
public typealias NicknameHandler = (String?) -> Void
public typealias ThumbnailHandler = (NSImage?) -> Void
public typealias RawDataHandler = (Data?, URLResponse?, Error?) -> Void
public typealias CurrentProgramsHandler = (Array<Program>) -> Void

fileprivate let UnknownNickname = "Unknown User"
fileprivate let NicknameNodeName: String = "nickname"
fileprivate let CouldNotParse = "Could not parse"

internal let NicknameAPIFormat: String = "https://api.live2.nicovideo.jp/api/v1/user/nickname?userId="
fileprivate let ThumbnailAPIFormat: String = "https://secure-dcdn.cdn.nimg.jp/nicoaccount/usericon/%@/%@.jpg"
fileprivate let ChannelThumbnailApi: String = "https://secure-dcdn.cdn.nimg.jp/comch/channel-icon/128x128/%@.jpg"
fileprivate let NicoNicoMyPageURL: String = "https://www.nicovideo.jp/my/top"
fileprivate let FollowingProgramsFormat: String = "https://live.nicovideo.jp/api/relive/notifybox.content"
fileprivate let FollowingProgramsPage: String = "?page="
fileprivate let UserInformationPage: String = "https://www.nicovideo.jp/user/"

fileprivate let IdentifierFinderRegex: String = "user\\.user_id = parseInt\\('(\\d+)', 10\\)"
fileprivate let PremiumFinderRegex: String = "user.member_status = '(\\w+)';"
fileprivate let LanguageFinderRegex: String = "user.ui_lang = '(.*?)';"
fileprivate let UserLevelRegex: String = "&quot;currentLevel&quot;:(\\d+),&quot;"

public enum InformationError: Error {
	case notLogin
}// end InformationError

fileprivate enum CurrentLanguage: String {
	case Japanese = "ja-jp"
	case Chinese = "zh-tw"
	case English = "en-us"
}// end enum CurrentLanguage

fileprivate let Premium: String = "premium"

internal struct data: Codable {
	let id: String
	let nickname: String
}// end struct data

internal struct error: Codable {
	let code: Int
	let messae: String?
}// end struct error

internal struct Nickname: Codable {
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
		case official = "official"
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

fileprivate struct NotifyContent: Codable {
	let notifyboxContent: Array<UserProgramInfo>
	let totalPage: Int

	private enum CodingKeys: String, CodingKey {
		case notifyboxContent = "notifybox_content"
		case totalPage = "total_page"
	}// end enum CodingKeys
}// end struct NotifyContent

public struct MetaCodeInformation: Codable {
	let status: Int
	let errorCode: Int?
	let errorMessage: String?
}// end struct MetaInformation

fileprivate struct UserPrograms: Codable {
	let meta: MetaCodeInformation
	let data: NotifyContent?
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
	public override init (with identifier: String) {
		super.init(with: identifier)
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
	public func myUserIdentifier () async -> (identifier: String, premium: Bool, language: UserLanguage) {
		return await fetchMyUserID()
	}// end myUserIdentifier

	public func myUserIdentifier (with handler: @escaping IdentifierHandler) -> Void {
		guard let url = URL(string: NicoNicoMyPageURL) else { handler("", false, .ja); return }
		let request: URLRequest = makeRequest(url: url, method: .get)
		var userIdentifier: String = ""
		var userIsPremium: Bool = false
		var userLanguage: UserLanguage = .ja
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(userIdentifier, userIsPremium, userLanguage) }
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

	public func fetchNickName (forIdentifier userIdentifier: String) -> String? {
		if let nickname = fetchNickname(from: userIdentifier) {
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

	public func thumbnailData (identifier userIdentifier: String) async -> Data? {
		let prefix: String = String(userIdentifier.prefix(userIdentifier.count - 4))
		let urlString: String = String(format: ThumbnailAPIFormat, prefix, userIdentifier)
		var thumbnailData: Data? = nil
		guard let url: URL = URL(string: urlString) else { return thumbnailData }
		let request: URLRequest = makeRequest(url: url, method: .get)
		do {
			let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
				if let _: NSImage = NSImage(data: result.data) {
					thumbnailData = result.data
				}
		} catch let error {
			Swift.print(error.localizedDescription)
		}// end do - try - catch

		return thumbnailData
	}// end thumbnailData

	public func userLevel (identifier userIdentifier: String) async -> Int {
		let userPageURL: URL = URL(string: UserInformationPage)!.appendingPathComponent(userIdentifier)
		let request: URLRequest = makeRequest(url: userPageURL, method: .get)
		do {
			let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
			guard let html: String = String(data: result.data, encoding: .utf8) else { return 1 }
			let userLevelRegex: NSRegularExpression = try NSRegularExpression(pattern: UserLevelRegex, options: [NSRegularExpression.Options.caseInsensitive])
			let htmlrange: NSRange = NSRange(location: 0, length: html.count)
			if let match: NSTextCheckingResult = userLevelRegex.firstMatch(in: html, options: [.withTransparentBounds, .withoutAnchoringBounds], range: htmlrange) {
				let userLevelRange: NSRange = match.range(at: 1)
				if let userLevel: Int = Int((html as NSString).substring(with: userLevelRange)) {
					return userLevel
				}// end optional binding of user level
			}// end optional binding of regex match
			return 1
		} catch let error {
			print(error.localizedDescription)
			return 1
		}// end do - try - catch
	}// end func userLevel

	public func communityThumbnailData (_ url: URL) async -> Data? {
		let request: URLRequest = makeRequest(url: url, method: .get)
		var thumbnailData: Data? = nil
		do {
			let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
			if let _: NSImage = NSImage(data: result.data) {
				thumbnailData = result.data
			}
		} catch let error {
			print(error.localizedDescription)
		}// end completion handler closure

		return thumbnailData
	}// end communityThumbnail

	public func channelThumbnailData (of channel: String) async -> Data? {
		var thumbnailData: Data? = nil
		let urlString: String = String(format: ChannelThumbnailApi, channel)
		guard let url: URL = URL(string: urlString) else { return thumbnailData }
		let request: URLRequest = makeRequest(url: url, method: .get)
		do {
			let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
			if let _: NSImage = NSImage(data: result.data) {
				thumbnailData = result.data
			}

			return thumbnailData
		} catch let error {
			print(error.localizedDescription)
			return thumbnailData
		}
	}// end channelThumbnailData

	public func rawData (ofURL url: URL, httpMethod method: HTTPMethod = .get, HTTPBody body: Data? = nil, contentsType type: String? = nil) async throws -> Data {
		var request: URLRequest = makeRequest(url: url, method: method)
		if let body: Data = body, let type: String = type {
			request.addValue(type, forHTTPHeaderField: ContentTypeKey)
			request.httpBody = body
		}// end optional binding check for body and its content type
		let result: (dat: Data, ressp: URLResponse) = try await session.data(for: request)

		return result.dat
	}// end rawData

	public func currentPrograms (with handler: @escaping CurrentProgramsHandler) async throws -> Void {
		var url: URL = URL(string: FollowingProgramsFormat)!
		var request: URLRequest = makeRequest(url: url, method: .get)
		var programs: Array<Program> = Array()
		var pageCount: Int = 0
		var maxPage: Int = 0
		var error: InformationError? = nil
		repeat {
			pageCount += 1
			url = pageCount == 1 ? URL(string: FollowingProgramsFormat)! : URL(string: FollowingProgramsFormat + FollowingProgramsPage + String(pageCount))!
			request.url = url
			let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
			guard let info: UserPrograms = try? JSONDecoder().decode(UserPrograms.self, from: result.data) else { return }
			if info.meta.status == 404 { error = InformationError.notLogin }
			guard info.meta.status != 404, let information: NotifyContent = info.data else { return }
			maxPage = information.totalPage
			let currentPrograms: Array<UserProgramInfo> = information.notifyboxContent
			for prog: UserProgramInfo in currentPrograms {
				if prog.providerType == .official { continue }
				let liveNumber: String = URL(string: prog.thumbnailLinkURL)?.lastPathComponent ?? ""
				let title: String = prog.title
				let community: String = prog.communityName
				let owner: String = prog.ownerIdentifier
				let thumb: NSImage? = NSImage(contentsOf: URL(string: prog.thumnailURL)!)
				let program: Program = Program(program: liveNumber, title: title, community: community, owner: owner, thumbnail: thumb)
				programs.append(program)
			}// end foreach all program informations
			if error == .notLogin { throw error! }
		} while pageCount < maxPage
		handler(programs)
	}// end currentPrograms

		// MARK: - Internal methods
		// MARK: - Private methods
	private func fetchMyUserID () async -> (identifier: String, premium: Bool, language: UserLanguage) {
		guard let url = URL(string: NicoNicoMyPageURL) else { return ("", false, .ja) }
		let request: URLRequest = makeRequest(url: url, method: .get)
		var userIdentifier: String? = nil
		var userIsPremium: Bool = false
		var userLanguage: UserLanguage = .ja
		do {
			let res: (data: Data, resp: URLResponse) = try await session.data(for: request)
			if let htmlSource: String = String(data: res.data, encoding: .utf8) {
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
		} catch let error {
			print(error.localizedDescription)
		}

		if let identifier: String = userIdentifier { return (identifier, userIsPremium, userLanguage) }
		return ("", false, .ja)
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
