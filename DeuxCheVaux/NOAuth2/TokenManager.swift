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

public enum TokenManagerError: Error {
	case URLError
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
	let cookies: Data
	let date: Date

	init (item: UserTokens) {
		identifier = item.identifier
		nickname = item.nickname
		premium = item.premium
		accessToken = item.accessToken
		refreshToken = item.refreshToken
		identifierToken = item.identifierToken
		date = item.date
		do {
			cookies = try NSKeyedArchiver.archivedData(withRootObject: item.cookies, requiringSecureCoding: false)
		} catch let error {
			print("User information initialize failed \(error.localizedDescription)")
			cookies = Data()
		}// end do try - catch archive cookie
	}// end init
}// end struct UserTokens

final class UserTokens {
	public var identifier: String
	public var nickname: String
	public var premium: Bool
	public var accessToken: String
	public var refreshToken: String
	public var identifierToken: String
	public var cookies: Array<HTTPCookie>
	public var date: Date

	init (item: UserInformations) {
		identifier = item.identifier
		nickname = item.nickname
		premium = item.premium
		accessToken = item.accessToken
		refreshToken = item.refreshToken
		identifierToken = item.identifierToken
		date = item.date
		do {
			cookies = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(item.cookies) as! Array<HTTPCookie>
		} catch let error {
			print("User Tokens initialize failed: \(error.localizedDescription)")
			cookies = Array()
		}// end do try - catch unarchive cookie
	}// end init

	init (identifier: String, nickname: String, premium: Bool, accessToken: String, refreshToken: String, identifierToken: String, cookies: Array<HTTPCookie>) {
		self.identifier = identifier
		self.nickname = nickname
		self.premium = premium
		self.accessToken = accessToken
		self.refreshToken = refreshToken
		self.identifierToken = identifierToken
		self.cookies = cookies
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
		kSecAttrAccessible as String: kSecAttrAccessibleAlways,
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
	}// end func awake from nib

	public override func windowDidLoad() {
		super.windowDidLoad()
	}// end window did load

		// MARK: - Actions
		// MARK: - Public Method
	public func authenticate () {
		window?.setIsVisible(true)
		var request: URLRequest = URLRequest(url: oauthURL)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		webView.load(request)
	}// end func authenticate

	public func start (with oAuthURL: URL, refreshQuery query: String, ofUser identifier: String?, handler: @escaping AccountsHandler) throws {
		oauthURL = oAuthURL
		refreshQuery = query
		var id: String? = identifier
		if tokens.count == 0 {
			let tokens: UserTokens = try updateOldAccount()
			id = tokens.identifier
		}// end update old account
		guard let userTokens: UserTokens = tokens[id!] else { throw TokenManagerError.UserNotFound }
		handler(userTokens.identifier, userTokens.nickname, userTokens.premium)
	}// end start

	public func getWSEndPoint (program liveNumber: String, for identifier: String) -> URL? {
		do {
			var wsEndPointURL: URL = URL(string: "https://live.nicovideo.jp")!
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			let url: URL = URL(string: WSEndPointURLString + WSEndPointProgramKey + liveNumber + WSEndPointUserIDKey + identifier)!
			let request = try makeRequestWithAccessToken(url: url, for: identifier)
			let task = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
				defer { semaphore.signal() }
				guard let data: Data = dat else { return }
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let urlData: URLResult = try decoder.decode(URLResult.self, from: data)
					if urlData.meta.status == 200 {
						wsEndPointURL = URL(string: urlData.data.url)!
					}// end if no error
				} catch let error {
					print(error.localizedDescription)
				}// end do try - catch decode URL JSON
			}// end completion handler
			task.resume()
			_ = semaphore.wait(timeout: DispatchTime.now() + .seconds(200))

			return wsEndPointURL
		} catch let error {
			print("get web socket end point error for id \(identifier), \(error.localizedDescription)")
			return nil
		}
	}// end func getWSEndPoint

	public func getCookies (for identifier: String) -> Array<HTTPCookie> {
		guard let tokens: UserTokens = tokens[identifier] else { return Array() }

		return tokens.cookies
	}// end func getCookies

	public func getUserSession (for identifier: String) throws -> String {
		guard let tokens: UserTokens = tokens[identifier] else { throw TokenManagerError.UserNotFound }

		for cookie: HTTPCookie in tokens.cookies {
			if cookie.name == UserSessionName && cookie.domain == UserSessionDomain {
				return cookie.value
			}// end if cookie is user_session
		}// end foreach cookies
		throw TokenManagerError.UserSessionNotFound
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
	private func getUserInfo(for identifier: String) {
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

		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			defer { semaphore.signal() }
				let decoder: JSONDecoder = JSONDecoder()
			} catch let error {
		task.resume()

	private func userPremium () -> Bool {
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var premium: Bool = false
		let request: URLRequest = makeRequestWithAccessToken(url: PremiumInfoURL)
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() }
			guard let json: Data = dat else { return }
			do {
				let premiumInfo: Premium = try JSONDecoder().decode(Premium.self, from: json)
				premium = premiumInfo.data.type == .premium
			} catch let error {
				print("GET Premium decode error: \(error.localizedDescription)")
			}// end do try - catch decode premium data json
		}// end closure
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.now() + .seconds(2))

		return premium
	}// end userPremium

	private func saveStringToKeychain (string: String, kind: String) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		query[kSecValueData as String] = string.data(using: .utf8)! as NSData
		var result: AnyObject?
		let resultCode: OSStatus = withUnsafeMutablePointer(to: &result) {
			SecItemAdd(query as CFDictionary, $0)
		}
		if resultCode == errSecDuplicateItem {
			return false
		}

		return resultCode == errSecSuccess
	}// end func save token into keychain

	private func saveDataToKeychain (data: Data, kind: String) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		query[kSecValueData as String] = data as NSData
		var result: AnyObject?
		let resultCode: OSStatus = withUnsafeMutablePointer(to: &result) {
			SecItemAdd(query as CFDictionary, $0)
		}
		if resultCode == errSecDuplicateItem {
			return false
		}

		return resultCode == errSecSuccess
	}// end func save token into keychain

	private func updateStringToKeychain (string: String, kind: String) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		var itemToUpdate: Dictionary<String, AnyObject> = defaultQuery
		itemToUpdate[kSecAttrService as String] = kind as NSString
		itemToUpdate[kSecValueData as String] = string.data(using: .utf8)! as NSData
		var result: AnyObject?
		var resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if let keychainItems = result as? Array<NSDictionary> {
			for _ in keychainItems {
				resultCode = SecItemDelete(query as CFDictionary)
			}
		}
		resultCode = withUnsafeMutablePointer(to: &result) {
			SecItemAdd(itemToUpdate as CFDictionary, $0)
		}

		return resultCode == errSecSuccess
	}// end update token of keychain

	private func updateDataToKeychain (data: Data, kind: String) -> Bool {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		var itemToUpdate: Dictionary<String, AnyObject> = defaultQuery
		itemToUpdate[kSecAttrService as String] = kind as NSString
		itemToUpdate[kSecValueData as String] = data as NSData
		var result: AnyObject?
		var resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if let keychainItems = result as? Array<NSDictionary> {
			for _ in keychainItems {
				resultCode = SecItemDelete(query as CFDictionary)
			}
		}
		resultCode = withUnsafeMutablePointer(to: &result) {
			SecItemAdd(itemToUpdate as CFDictionary, $0)
		}

		return resultCode == errSecSuccess
	}// end update token of keychain

	private func readStringFromKeychain (kind: String) -> String? {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		var result: AnyObject?
		let resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if resultCode == errSecItemNotFound {
			return nil
		} else {
			if let keychainItems = result as? Array<NSDictionary> {
				for item: NSDictionary in keychainItems {
					if let data: Data = item[kSecValueData] as? Data {
						return String(data: data, encoding: .utf8)!
					}// end if token found
				}// end foreach keychain item
			}// end if found keychain items
		}// end if keychain items found or not

		return nil
	}// end func read token from keychain

	private func readDataFromKeychain (kind: String) -> Data? {
		var query: Dictionary<String, AnyObject> = defaultQuery
		query[kSecAttrService as String] = kind as NSString
		var result: AnyObject?
		let resultCode = withUnsafeMutablePointer(to: &result) {
			 SecItemCopyMatching(query as CFDictionary, $0)
		}
		if resultCode == errSecItemNotFound {
			return nil
		} else {
			if let keychainItems = result as? Array<NSDictionary> {
				for item: NSDictionary in keychainItems {
					if let data: Data = item[kSecValueData] as? Data {
						return data
					}// end if token found
				}// end foreach keychain item
			}// end if found keychain items
		}// end if keychain items found or not

		return nil
	}// end func read token from keychain

	private func verifyUserSession () {
		getUserInfo()
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		if let uid: String = self.userIdentifier {
			let url: URL = URL(string: NicknameAPIFormat + uid)!
			var request: URLRequest = makeRequest(url: url)
			request.addValue(user_session, forHTTPHeaderField: NicoSessionHeaderKey)
			let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
			let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
				defer { semaphore.signal() }
				guard let data: Data = dat else { return }
				let decoder: JSONDecoder = JSONDecoder()
				do {
					let nickname: Nickname = try decoder.decode(Nickname.self, from: data)
					if nickname.data?.id != uid {
						self.authenticate()
					}// end authenticate if can not get correct user id
					self.sessionIsValid = true
				} catch let error {
					self.authenticate()
					print(error.localizedDescription)
				}// end do try - catch decode nickname json.
			}// end completion handler
			task.resume()
			_ = semaphore.wait(timeout: DispatchTime.now() + .seconds(2))
		}// end if user identifier is there
	}// end func verifyUserSession

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
					if !self.saveStringToKeychain(string: cookie.value, kind: SessionToken) {
						_ = self.updateStringToKeychain(string: cookie.value, kind: SessionToken)
					}// end if can not save user session
					self.user_session = cookie.value
					self.sessionIsValid = true
				}// end if found user session cookie
			}// end foreach cookie
		}// end all cookies handler
		webView.evaluateJavaScript("document.getElementsByTagName('div')[0].innerHTML") { (json: Any?, error: Error?) -> Void in
			guard let jsonString: String = json as? String, let jsonData: Data = jsonString.data(using: .utf8) else { return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let tokens: Tokens = try decoder.decode(Tokens.self, from: jsonData)
				self.window?.setIsVisible(false)
				self.refreshToken = tokens.refresh_token
				self.accessToken = tokens.access_token
				if let id_token: String = tokens.id_token {
					self.idToken = id_token
				}
				self.expire = tokens.expires_in
				_ = self.updateStringToKeychain(string: self.refreshToken, kind: RefreshToken)
				_ = self.updateStringToKeychain(string: self.idToken, kind: IDToken)
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode json
		}// end evaluate java scrippt completion handler
	}// end func wevbiew didFinish
}// end class TokenManager
