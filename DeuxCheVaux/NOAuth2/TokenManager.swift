//
//  TokenManager.swift
//  Charleston
//
//  Created by Я Чайка on 2021/03/30.
//  Copyright © 2021 Чайка. All rights reserved.
//

import Cocoa
import WebKit
import Security

fileprivate let TokenManagerNibName: String = "TokenManager"
fileprivate let MyPageURL: URL = URL(string: "https://www.nicovideo.jp/my")!
fileprivate let LiveURLString: String = "https://live.nicovideo.jp"
fileprivate let AuthorizationBaseURL: URL = URL(string: "https://oauth.nicovideo.jp/")!
fileprivate let AuthorizedURL: URL = AuthorizationBaseURL.appendingPathComponent("oauth2/authorized")
fileprivate let UserInfoURL: URL = AuthorizationBaseURL.appendingPathComponent("open_id/userinfo")
fileprivate let PremiumInfoURL: URL = AuthorizationBaseURL.appendingPathComponent("v1/user/premium.json")
fileprivate let WSEndPointURLString: String = "https://api.live2.nicovideo.jp/api/v1/wsendpoint"
fileprivate let WSEndPointProgramKey: String = "?nicoliveProgramId="
fileprivate let WSEndPointUserIDKey: String = "&userId="
fileprivate let AccessTokenInterval: TimeInterval = 60 * 60
fileprivate let AuthorizationKey: String = "Authorization"
fileprivate let AuthorizationBearer: String = "Bearer "
fileprivate let TokenKey: String = "jp.nicovideo.oauth2-tokens"
fileprivate let RefreshToken: String = "jp.nicovideo.oauth2-refresh_token"
fileprivate let IDToken: String = "jp.nicovideo.oauth2-id_token"
fileprivate let SessionToken: String = "jp.nicovideo.user_session"
fileprivate let ArchiveKey: String = "cookie"
private let cookieProperties: Dictionary<HTTPCookiePropertyKey, Any> = [
	.domain: UserSessionDomain,
	.name: UserSessionName,
	.path: "/"
]
extension Notification.Name {
	static let userModificationDone = Notification.Name("User Modification Done")
}

public enum TokenManagerError: Error {
	case URLError
	case DataError
	case IdentifierNotFound
	case TimerDidNotFound
	case UserNotFound
	case UserSessionNotFound
	case TokensDecodeError
}// end enum TokenManagerError

fileprivate struct Tokens: Codable {
	let access_token: String
	let token_type: String
	let expires_in: Int
	let scope: String
	let refresh_token: String
	let id_token: String?
}// end struct Tokens

fileprivate struct IDTokenData: Codable {
	let iss: String
	let sub: String
}// end struct IDTokenData

fileprivate struct UserInfo: Codable {
	let sub: String
	let nickname: String
	let profile: String
	let picture: String
	let gender: String?
	let zoneinfo: String
	let updated_at: Int
}// end struct UserInfo

fileprivate enum UserPremium: String, Codable {
	case regular = "regular"
	case premium = "premium"
}// end enum UserPremium

fileprivate struct PremiumData: Codable {
	let type: UserPremium
	let expireTime: String?
}// end struct PremiumData

fileprivate struct Premium: Codable {
	let meta: MetaInformation
	let data: PremiumData
}// end struct Premium

fileprivate struct URLData: Codable {
	let url: String
}// end struct URLData

fileprivate struct URLResult: Codable {
	let meta: MetaInformation
	let data: URLData
}// end struct URLResult

fileprivate struct IDInfo: Codable {
	let meta: MetaInformation
	let data: IDTokenData
}// end struct IDInfo

public struct UserInformations: Codable {
	let identifier: String
	let nickname: String
	let premium: Bool
	var accessToken: String
	var refreshToken: String
	let identifierToken: String
	let userSession: String
	let date: Date

	init (item: UserTokens) {
		identifier = item.identifier
		nickname = item.nickname
		premium = item.premium
		accessToken = item.accessToken
		refreshToken = item.refreshToken
		identifierToken = item.identifierToken
		userSession = item.userSession
		date = item.date
	}// end init
}// end struct UserTokens

final class UserTokens {
	public var identifier: String
	public var nickname: String
	public var premium: Bool
	public var accessToken: String
	public var refreshToken: String
	public var identifierToken: String
	public var userSession: String
	public var date: Date

	init (item: UserInformations) {
		identifier = item.identifier
		nickname = item.nickname
		premium = item.premium
		accessToken = item.accessToken
		refreshToken = item.refreshToken
		identifierToken = item.identifierToken
		userSession = item.userSession
		date = item.date
	}// end init

	init (identifier: String, nickname: String, premium: Bool, accessToken: String, refreshToken: String, identifierToken: String, cookies: Array<HTTPCookie>) {
		self.identifier = identifier
		self.nickname = nickname
		self.premium = premium
		self.accessToken = accessToken
		self.refreshToken = refreshToken
		self.identifierToken = identifierToken
		self.userSession = identifier
		for cookie in cookies {
			if cookie.name == UserSessionName && cookie.domain == UserSessionDomain {
				self.userSession = cookie.value
			}
		}
		date = Date()
	}
}// end struct UserTokens

public typealias AccountsHandler = (_ userIdentifier: String, _ nickname: String?, _ premium: Bool) -> Void

public final class TokenManager: NSWindowController, WKNavigationDelegate {
		// MARK:   Class Variables
	public static let shared: TokenManager = TokenManager()

		// MARK: - Class Methods
		// MARK: - Properties
		// MARK: - Computed Properties
	public var allAccounts: Array<(String, String)> {
		get {
			var allAccounts: Array<(String, String)> = Array()
			for tokens: UserTokens in tokens.values {
				allAccounts.append((tokens.identifier, tokens.nickname))
			}// end foreach user tokens

			return allAccounts
		}// end get
	}// end computed property allAccounts

		// MARK: - Outlets
	@IBOutlet weak var webView: WKWebView!

		// MARK: - Member Variables
	private let concurrentBackground: DispatchQueue = DispatchQueue(label: "tv.from.chajka.DeuxCheVaux", qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 0), attributes: DispatchQueue.Attributes.concurrent)
	private var oauthURL: URL!
	private var refreshQuery: String!
	private var expire: TimeInterval = AccessTokenInterval
	private let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
	private var userNickname: String!
	private var sessionIsValid: Bool = false
	private let defaultQuery: Dictionary<String, AnyObject> = [
		kSecClass as String: kSecClassGenericPassword,
		kSecReturnPersistentRef as String: kCFBooleanTrue,
		kSecAttrSynchronizable as String: kCFBooleanTrue,
		kSecAttrType as String: kSecAttrApplicationLabel
	]
	private var tokens: Dictionary<String, UserTokens> = Dictionary()

	private var refreshToken: String!
	private var accessToken: String!
	private var idToken: String!
	private var user_session: String!
	private var premium: Bool!
	private var userIdentifier: String?
	private var cookies: Array<HTTPCookie>?

	private var watcherCount: Int = 0

	private var refreshTokenTimer: DispatchSourceTimer? = nil

		// MARK: - Constructor / Destructor
	private convenience init() {
		self.init(windowNibName: TokenManagerNibName)
		let decoder: JSONDecoder = JSONDecoder()
		let items: Array<Data> = readDataFromKeychain(kind: TokenKey)
		do {
			for item: Data in items {
				let info: UserInformations = try decoder.decode(UserInformations.self, from: item)
				let token: UserTokens = UserTokens(item: info)
				self.tokens[token.identifier] = token
			}// end foreach available tokens
		} catch let error {
			print ("Decode tokens in initializer failed: \(error.localizedDescription)")
		}// end do try - catch
	}// end convinience init

	deinit {
		if let timer: DispatchSourceTimer = refreshTokenTimer, !timer.isCancelled {
			timer.cancel()
			timer.suspend()
			refreshTokenTimer = nil
		}// end if optional binding check for 
	}// end deinit
	
		// MARK: - Overrides
	public override func awakeFromNib () {
		let store: WKWebsiteDataStore = WKWebsiteDataStore.nonPersistent()
		webView.configuration.websiteDataStore = store
		webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies: Array<HTTPCookie>) in
			for cookie in cookies {
				self.webView.configuration.websiteDataStore.httpCookieStore.delete(cookie)
			}// end foreach
		}// end closure of getAllCookies
	}// end func awake from nib

	public override func windowDidLoad() {
		super.windowDidLoad()
	}// end window did load

		// MARK: - Actions
		// MARK: - Public Method
	public func authenticate (with url: URL) {
		if oauthURL == nil { oauthURL = url }
		window?.setIsVisible(true)
		let store: WKWebsiteDataStore = WKWebsiteDataStore.nonPersistent()
		webView.configuration.websiteDataStore = store
		var request: URLRequest = URLRequest(url: oauthURL)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		webView.load(request)
	}// end func authenticate

	public func reAuthenticate (for identifier: String, with url: URL) {
		if oauthURL == nil { oauthURL = url }
		window?.setIsVisible(true)
		let store: WKWebsiteDataStore = WKWebsiteDataStore.nonPersistent()
		webView.configuration.websiteDataStore = store
		var property: Dictionary<HTTPCookiePropertyKey, Any> = cookieProperties
		property[.value] = tokens[identifier]?.userSession
		if let cookie: HTTPCookie = HTTPCookie(properties: property) {
			webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
		}// end if cookie
		var request: URLRequest = URLRequest(url: oauthURL)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		webView.load(request)
	}// end re authenticate

	public func removeAccount (of identifier: String) {
		tokens[identifier] = nil
		removeItemFromKeychain(kind: TokenKey, account: identifier)
		let center: NotificationCenter = NotificationCenter()
		center.post(name: .userModificationDone, object: nil)
	}// end func remove

	public func start (with oAuthURL: URL, refreshQuery query: String, ofUser identifier: String?) async throws -> (String, String?, Bool) {
		oauthURL = oAuthURL
		refreshQuery = query
		var id: String
		if tokens.count == 0 || identifier == nil {
			let tokens: UserTokens = try await updateOldAccount()
			id = tokens.identifier
		} else {
			id = identifier!
		}// end update old account
		guard let userTokens: UserTokens = tokens[id] else { throw TokenManagerError.UserNotFound }
		return (userTokens.identifier, userTokens.nickname, userTokens.premium)
	}// end start

	public func getWSEndPoint (program liveNumber: String, for identifier: String) async -> URL? {
		do {
			var wsEndPointURL: URL = URL(string: LiveURLString)!
			let url: URL = URL(string: WSEndPointURLString + WSEndPointProgramKey + liveNumber + WSEndPointUserIDKey + identifier)!
			let request = try makeRequestWithAccessToken(url: url, for: identifier)
			let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
			let decoder: JSONDecoder = JSONDecoder()
			let urlData: URLResult = try decoder.decode(URLResult.self, from: result.data)
			if urlData.meta.status == 200 {
				wsEndPointURL = URL(string: urlData.data.url)!
			}// end if no error

			return wsEndPointURL
		} catch let error {
			print("get web socket end point error for id \(identifier), \(error.localizedDescription)")
			return nil
		}
	}// end func getWSEndPoint

	public func getCookies (for identifier: String) -> Array<HTTPCookie> {
		guard let tokens: UserTokens = tokens[identifier] else { return Array() }
		var property: Dictionary<HTTPCookiePropertyKey, Any> = cookieProperties
		property[.value] = tokens.userSession
		if let cookie: HTTPCookie = HTTPCookie(properties: property) {
			return [cookie]
		} else {
			return Array()
		}
	}// end func getCookies

	public func getUserSession (for identifier: String) throws -> String {
		guard let tokens: UserTokens = tokens[identifier] else { throw TokenManagerError.UserNotFound }

		return tokens.userSession
	}// end func getUserSession

	public func makeRequest (url: URL) -> URLRequest {
		var request: URLRequest = URLRequest(url: url)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)

		return request
	}// end func makeRequest

	public func makeRequestWithAccessToken (url: URL, for identifier: String) throws -> URLRequest {
		guard let userTokens: UserTokens = tokens[identifier] else { throw TokenManagerError.IdentifierNotFound }
		if -userTokens.date.timeIntervalSinceNow > expire {
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			guard let query: String = self.refreshQuery else { throw TokenManagerError.URLError }
			let queryURLString: String = self.oauthURL.absoluteString
			let queryURL: URL = URL(string: queryURLString + "?" + query + "=" + userTokens.refreshToken)!
			let request: URLRequest = self.makeRequest(url: queryURL)
			let task: URLSessionDataTask = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (dat:Data?, resp: URLResponse?, err: Error?) in
				defer { semaphore.signal() }
				guard let data: Data = dat, let html: String = String(data: data, encoding: .utf8) else { return }
				let body: String = String(html.split(separator: ">",maxSplits: 11).last!)
				let jsonString: String = String(body.split(separator: "<", maxSplits: 2).first!)
				if let json: Data = jsonString.data(using: .utf8) {
					let decoder: JSONDecoder = JSONDecoder()
					do {
						let tokens: Tokens = try decoder.decode(Tokens.self, from: json)
						userTokens.refreshToken = tokens.refresh_token
						userTokens.accessToken = tokens.access_token
						userTokens.date = Date()
						let info: UserInformations = UserInformations(item: userTokens)
						let dataJSON: Data = try JSONEncoder().encode(info)
						self.updateDataToKeychain(data: dataJSON, kind: TokenKey, account: userTokens.identifier)
					} catch let error {
						print(error.localizedDescription)
					}// end do try - catch decode tokens json
				}// end if json to convert data
			}// end closure
			task.resume()
			_ = semaphore.wait(timeout: DispatchTime.now() + .seconds(2))
		}// end if access token expire time is over
		var request: URLRequest = URLRequest(url: url)
		request.addValue(AuthorizationBearer + userTokens.accessToken, forHTTPHeaderField: AuthorizationKey)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		request.httpMethod = "GET"

		return request
	}// end func makeRequest

	public func makeRequestWithCustomToken (url: URL, for token: String) -> URLRequest {
		var request: URLRequest = URLRequest(url: url)
		request.addValue(AuthorizationBearer + token, forHTTPHeaderField: AuthorizationKey)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		request.httpMethod = "GET"

		return request
	}// end make request with id token

		// MARK: - Private Methods
	private func getUserInfo (for identifier: String) {
		guard let tokens: UserTokens = tokens[identifier] else { return }
		do {
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			let request: URLRequest = try makeRequestWithAccessToken(url: UserInfoURL, for: identifier)
			let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
				defer { semaphore.signal() }
				guard let data: Data = dat else { return }
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let userInfo: UserInfo = try decoder.decode(UserInfo.self, from: data)
					tokens.nickname = userInfo.nickname
				} catch let error {
					print(error.localizedDescription)
				}// end do try - catch decode user info
			}// end completion handler
			task.resume()
			_ = semaphore.wait(timeout: DispatchTime.now() + .seconds(2))
		} catch let error {
			print("get user info error: \(error.localizedDescription)")
		}
	}// end func get user info from oAuth2 server

	private func userPremium (for identifier: String) async -> Bool {
		do {
			var premium: Bool = false
			let request: URLRequest = try makeRequestWithAccessToken(url: PremiumInfoURL, for: identifier)
			let result: (data: Data, resp: URLResponse) = try await session.data(for: request)
				do {
					let premiumInfo: Premium = try JSONDecoder().decode(Premium.self, from: result.data)
					premium = premiumInfo.data.type == .premium
				} catch let error {
					print("GET Premium decode error: \(error.localizedDescription)")
				}// end do try - catch decode premium data json

			return premium
		} catch TokenManagerError.IdentifierNotFound {
			print("user premium catch identifier error")
		} catch let error {
			print("user premium catch error: \(error.localizedDescription)")
		}

		return false
	}// end userPremium

	private func updateOldAccount () async throws -> UserTokens {
		guard let refreshToken: String = readStringFromKeychain(kind: RefreshToken), let identifierToken: String = readStringFromKeychain(kind: IDToken), let sessionToken = readStringFromKeychain(kind: SessionToken) else { throw TokenManagerError.UserNotFound}
		self.refreshToken = refreshToken
		removeItemFromKeychain(kind: RefreshToken)
		self.idToken = identifierToken
		removeItemFromKeychain(kind: IDToken)
		self.user_session = sessionToken
		removeItemFromKeychain(kind: SessionToken)
		guard let userSession: String = user_session else { throw TokenManagerError.UserSessionNotFound }
		let cookieProperties: Dictionary<HTTPCookiePropertyKey, Any> = [
			.domain: UserSessionDomain,
			.name: UserSessionName,
			.value: userSession,
			HTTPCookiePropertyKey.path: "/"]
		let cookie: HTTPCookie = HTTPCookie(properties: cookieProperties)!
		let userTokens: UserTokens = UserTokens(identifier: "", nickname: "", premium: false, accessToken: "", refreshToken: refreshToken, identifierToken: idToken, cookies: [cookie])
		let queryURLString: String = self.oauthURL.absoluteString
		guard let query: String = self.refreshQuery, let token: String = self.refreshToken else { throw TokenManagerError.TokensDecodeError }
		let queryURL: URL = URL(string: queryURLString + "?" + query + "=" + token)!
		var request: URLRequest = self.makeRequest(url: queryURL)
		var result: (data: Data, resp: URLResponse) = try await URLSession(configuration: URLSessionConfiguration.default).data(for: request)
		guard let html: String = String(data: result.data, encoding: .utf8) else { throw TokenManagerError.DataError }
		let body: String = String(html.split(separator: ">",maxSplits: 11).last!)
		let jsonString: String = String(body.split(separator: "<", maxSplits: 2).first!)
		if let json: Data = jsonString.data(using: .utf8) {
			let decoder: JSONDecoder = JSONDecoder()
			do {
				let tokens: Tokens = try decoder.decode(Tokens.self, from: json)
				userTokens.refreshToken = tokens.refresh_token
				userTokens.accessToken = tokens.access_token
				if userTokens.identifier != "" {
					self.updateDataToKeychain(data: result.data, kind: TokenKey, account: userTokens.identifier)
				}
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode tokens json
		}// end if json to convert data
		request = makeRequestWithCustomToken(url: UserInfoURL, for: userTokens.accessToken)
		result = try await session.data(for: request)
		let decoder: JSONDecoder = JSONDecoder()
		do {
			let info: UserInfo = try decoder.decode(UserInfo.self, from: result.data)
			userTokens.identifier = info.sub
			userTokens.nickname = info.nickname
		} catch let error {
			print("Decode ID token information error: \(error.localizedDescription)")
		}// end do try - catch JSON Decode error
		request.url = PremiumInfoURL
		result = try await session.data(for: request)
		do {
			let premium: Premium = try decoder.decode(Premium.self, from: result.data)
			userTokens.premium = premium.data.type == .premium
		} catch let error {
			print("premium data decode error \(error.localizedDescription)")
		}
		let id = userTokens.identifier
		tokens[id] = userTokens

		do {
			let encoder: JSONEncoder = JSONEncoder()
			let info: UserInformations = UserInformations(item: userTokens)
			let data: Data = try encoder.encode(info)
			if !saveDataToKeychain(data: data, kind: TokenKey, account: userTokens.identifier) {
				updateDataToKeychain(data: data, kind: TokenKey, account: userTokens.identifier)
			}// end if data can not save to keychain
		} catch let error {
			print("encode user infomation error\(error.localizedDescription)")
		}

		return userTokens
	}// end func updateOldAccount

	private func getUserInformation (of token: String, with handler: @escaping AccountsHandler) -> Void {
		var request: URLRequest = makeRequestWithCustomToken(url: UserInfoURL, for: token)
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				handler("", "", false)
				return
			}// end guard optional binding check for data
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let information: UserInfo = try decoder.decode(UserInfo.self, from: data)
				request.url = PremiumInfoURL
				let task: URLSessionDataTask = self.session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
					guard let data: Data = dat else {
						handler("", "", false)
						return
					}// end guard optional binding check for data
					do {
						let premium: Premium = try decoder.decode(Premium.self, from: data)
						handler(information.sub, information.nickname, premium.data.type == .premium)
					} catch let error {
						print("Get user premium data decde error: \(error.localizedDescription)")
					}// end do try - catch premium decode error handler
				}// end closure get premium json
				task.resume()
			} catch let error {
				print("Get user information data decode error: \(error.localizedDescription)")
			}// end do try - catch decode user information handler
		}// end closure get user information json
		task.resume()
	}// end func get user information

	private func saveStringToKeychain (string: String, kind: String, account: String? = nil) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		if let account: String = account {
			query[kSecAttrAccount as String] = account as NSString
		}
		query[kSecValueData as String] = string.data(using: .utf8)! as NSData
		var result: AnyObject?
		let resultCode: OSStatus = withUnsafeMutablePointer(to: &result) {
			SecItemAdd(query as CFDictionary, $0)
		}
		if resultCode == errSecDuplicateItem {
			let resultCode: OSStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String : string.data(using: .utf8)! as NSData] as CFDictionary)
			if resultCode == errSecSuccess { return true }
		}

		return resultCode == errSecSuccess
	}// end func save string into keychain

	private func saveDataToKeychain (data: Data, kind: String, account: String? = nil) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		if let account: String = account {
			query[kSecAttrAccount as String] = account as NSString
		}
		query[kSecValueData as String] = data as NSData
		var result: AnyObject?
		let resultCode: OSStatus = withUnsafeMutablePointer(to: &result) {
			SecItemAdd(query as CFDictionary, $0)
		}
		if resultCode == errSecDuplicateItem {
			let resultCode: OSStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String : data as NSData] as CFDictionary)
			if resultCode == errSecSuccess { return true }
		}

		return resultCode == errSecSuccess
	}// end func save data into keychain

	@discardableResult
	private func updateStringToKeychain (string: String, kind: String, account: String? = nil) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		if let account: String = account {
			query[kSecAttrAccount as String] = account as NSString
		}
		let newAttribute: Dictionary<String, AnyObject> = [kSecValueData as String : string.data(using: .utf8)! as NSData]
		let resultCode: OSStatus = SecItemUpdate(query as CFDictionary, newAttribute as CFDictionary)

		return resultCode == errSecSuccess
	}// end update string of keychain

	@discardableResult
	private func updateDataToKeychain (data: Data, kind: String, account: String? = nil) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		if let account: String = account {
			query[kSecAttrAccount as String] = account as NSString
		}
		let newAttribute: Dictionary<String, AnyObject> = [kSecValueData as String : data as NSData]
		let resultCode: OSStatus = SecItemUpdate(query as CFDictionary, newAttribute as CFDictionary)

		return resultCode == errSecSuccess
	}// end update data of keychain

	private func readStringFromKeychain (kind: String, account: String? = nil) -> String? {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		if let account: String = account {
			query[kSecAttrAccount as String] = account as NSString
		}
		query[kSecMatchLimit as String] = kSecMatchLimitOne as NSString
		query[kSecReturnData as String] = kCFBooleanTrue
		var result: AnyObject?
		let resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if resultCode == errSecItemNotFound {
			return nil
		} else {
			if let keychainItem = result as? NSDictionary {
				if let data: Data = keychainItem[kSecValueData] as? Data {
					return String(data: data, encoding: .utf8)!
				}// end if token found
			}// end if found keychain items
		}// end if keychain items found or not

		return nil
	}// end func read string from keychain

	private func readStringFromKeychain (kind: String) -> Array<String> {
		var items: Array<String> = Array()
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		query[kSecMatchLimit as String] = kSecMatchLimitAll as NSString
		query[kSecReturnData as String] = kCFBooleanTrue
		var result: AnyObject?
		let resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if resultCode == errSecItemNotFound {
			return items
		} else {
			if let keychainItems = result as? Array<NSDictionary> {
				for item: NSDictionary in keychainItems {
					if let data: Data = item[kSecValueData] as? Data {
						items.append(String(data: data, encoding: .utf8)!)
					}// end if token found
				}// end foreach keychain items
			}// end if found keychain items
		}// end if keychain items found or not

		return items
	}// end func read strings from keychain

	private func readDataFromKeychain (kind: String, account: String? = nil) -> Data? {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		if let account: String = account {
			query[kSecAttrAccount as String] = account as NSString
		}
		query[kSecMatchLimit as String] = kSecMatchLimitOne as NSString
		query[kSecReturnData as String] = kCFBooleanTrue
		var result: AnyObject?
		let resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if resultCode == errSecItemNotFound {
			return nil
		} else {
			if let keychainItem = result as? NSDictionary {
				if let data: Data = keychainItem[kSecValueData] as? Data {
					return data
				}// end if token found
			}// end if found keychain items
		}// end if keychain items found or not

		return nil
	}// end func read data from keychain

	private func readDataFromKeychain (kind: String) -> Array<Data> {
		var items: Array<Data> = Array()
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		query[kSecMatchLimit as String] = kSecMatchLimitAll as NSString
		query[kSecReturnData as String] = kCFBooleanTrue
		var result: AnyObject?
		let resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if resultCode == errSecItemNotFound {
			return items
		} else {
			if let keychainItems = result as? Array<NSDictionary> {
				for item in keychainItems {
					if let data: Data = item[kSecValueData] as? Data {
						items.append(data)
					}// end if token found
				}// end foreach keychain items
			}// end if found keychain items
		}// end if keychain items found or not

		return items
	}// end func read datas from keychain

	@discardableResult
	private func removeItemFromKeychain (kind: String, account: String? = nil) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		if let account: String = account {
			query[kSecAttrAccount as String] = account as NSString
		}
		query[kSecAttrService as String] = kind as NSString
		let resultCode: OSStatus = SecItemDelete(query as CFDictionary)

		return resultCode == errSecSuccess
	}// end func remove item from keychain

		// MARK: - Delegate / Protocol clients
	public func webView (_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		if let url: URL = webView.url {
			if url.absoluteURL != MyPageURL, url.absoluteURL == AuthorizedURL || (oauthURL != nil && sessionIsValid) {
				window?.setIsVisible(false)
			} else {
				window?.setIsVisible(true)
			}// end my window need visible or not
		}// end if my web view url is valid
	}// end func webView didStartProvisionalNavigation

	public func webView (_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies:Array<HTTPCookie>) in
			for cookie: HTTPCookie in cookies {
				if cookie.name == UserSessionName && cookie.domain == UserSessionDomain {
					self.user_session = cookie.value
					self.sessionIsValid = true
					if let id = self.userIdentifier, let token: UserTokens = self.tokens[id] {
						token.userSession = self.user_session
					}// end if token found
					self.cookies = cookies
				}// end if found user session cookie
			}// end foreach cookie
		}// end all cookies handler

		webView.evaluateJavaScript("document.getElementsByTagName('div')[0].innerHTML") { (html: Any?, error: Error?) -> Void in
			guard let jsonString: String = html as? String, let jsonData: Data = jsonString.data(using: .utf8) else { return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let tokens: Tokens = try decoder.decode(Tokens.self, from: jsonData)
				self.window?.setIsVisible(false)
				self.expire = TimeInterval(tokens.expires_in)
				self.getUserInformation(of: tokens.access_token) { (id: String, nickname: String?, premium: Bool )in
					guard id != "", let nick: String = nickname, nick != "", let cookies: Array<HTTPCookie> = self.cookies else { return }
					do {
						let userTokens: UserTokens = UserTokens(identifier: id, nickname: nick, premium: premium, accessToken: tokens.access_token, refreshToken: tokens.refresh_token, identifierToken: tokens.id_token!, cookies: cookies)
						let informations: UserInformations = UserInformations(item: userTokens)
						let data: Data = try JSONEncoder().encode(informations)
						if !self.saveDataToKeychain(data: data, kind: TokenKey, account: userTokens.identifier) {
							self.updateDataToKeychain(data: data, kind: TokenKey, account: userTokens.identifier)
						}// end if can not save data to keychain
						self.tokens[userTokens.identifier] = userTokens
						let center: NotificationCenter = NotificationCenter.default
						center.post(name: .userModificationDone, object: nil)
						DispatchQueue.main.async {
							self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies: Array<HTTPCookie>) in
								for cookie in cookies {
									self.webView.configuration.websiteDataStore.httpCookieStore.delete(cookie)
								}// end foreach
							}// end closure of getAllCookies
						}// end main queue task
					} catch let error {
						print("Encode new account informations error: \(error.localizedDescription)")
					}// end do try - catch decode json
				}// end closure
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode json
		}// end evaluate java scrippt completion handler
	}// end func wevbiew didFinish
}// end class TokenManager
