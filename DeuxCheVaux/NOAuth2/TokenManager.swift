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
fileprivate let AuthorizationBaseURL: URL = URL(string: "https://oauth.nicovideo.jp/")!
fileprivate let AuthorizedURL: URL = AuthorizationBaseURL.appendingPathComponent("oauth2/authorized")
fileprivate let UserInfoURL: URL = AuthorizationBaseURL.appendingPathComponent("open_id/userinfo")
fileprivate let WSEndPointURLString: String = "https://api.live2.nicovideo.jp/api/v1/wsendpoint"
fileprivate let UserSessionDomain: String = ".nicovideo.jp"
fileprivate let WSEndPointProgramKey: String = "?nicoliveProgramId="
fileprivate let WSEndPointUserIDKey: String = "&userId="
fileprivate let AccessTokenInterval: Int = 60 * 60
fileprivate let AuthorizationKey: String = "Authorization"
fileprivate let AutorizationBearer: String = "Bearer "
fileprivate let RefreshToken: String = "jp.nicovideo.oauth2-refresh_token"
fileprivate let IDToken: String = "jp.nicovideo.oauth2-id_token"
fileprivate let SessionToken: String = "jp.nicovideo.user_session"

fileprivate struct Tokens: Codable {
	let access_token: String
	let token_type: String
	let expires_in: Int
	let scope: String
	let refresh_token: String
	let id_token: String?
}// end struct Tokens

fileprivate struct UserInfo: Codable {
	let sub: String
	let nickname: String
	let profile: String
	let picture: String
	let gender: String?
	let zoneinfo: String
	let updated_at: Int
}// end struct UserInfo

fileprivate struct URLData: Codable {
	let url: String
}// end struct URLData

fileprivate struct URLResult: Codable {
	let meta: MetaInformation
	let data: URLData
}// end struct URLResult

public final class TokenManager: NSWindowController, WKNavigationDelegate {
		// MARK:   Class Variables
	public static let shared: TokenManager = TokenManager()

		// MARK: - Class Methods
		// MARK: - Properties
	public var refreshToken: String!
	public var accessToken: String!
	public var idToken: String!
	public var user_session: String!

		// MARK: - Computed Properties
		// MARK: - Outlets
	@IBOutlet weak var webView: WKWebView!

		// MARK: - Member Variables
	private let concurrentBackground: DispatchQueue = DispatchQueue(label: "tv.from.chajka.DeuxCheVaux", qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 0), attributes: DispatchQueue.Attributes.concurrent)
	private var oauthURL: URL!
	private var refreshQuery: String!
	private var expire: Int = AccessTokenInterval
	private let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
	private var userIdentifier: String!
	private var userNickname: String!

	private var watcherCount: Int = 0

	private var refreshTokenTimer: DispatchSourceTimer? = nil

		// MARK: - Constructor / Destructor
	private convenience init() {
		self.init(windowNibName: TokenManagerNibName)
		if let token: String = readToken(tokenType: RefreshToken) {
			self.refreshToken = token
		}// end optional binding check for old refresh token in iCloudKeychain or not
		if let token: String = readToken(tokenType: IDToken) {
			self.idToken = token
		}// end optional binding check for id token in iCloudKeychain or not
	}// end convinience init

	deinit {
		if let timer: DispatchSourceTimer = refreshTokenTimer, !timer.isCancelled {
			timer.cancel()
			timer.suspend()
			refreshTokenTimer = nil
		}// end if optional binding check for 
	}// end deinit
	
		// MARK: - OVerrides
	public override func windowDidLoad() {
		super.windowDidLoad()
	}// end window did load

		// MARK: - Actions
		// MARK: - Public Method
	public func authenticate () {
		window?.setIsVisible(true)
		let request: URLRequest = URLRequest(url: oauthURL)
		webView.load(request)
	}// end func authenticate

	public func start (with oAuthURL: URL, refreshQuery query: String) {
		oauthURL = oAuthURL
		refreshQuery = query
		watcherCount += 1
		if refreshToken == nil { authenticate() }
		if refreshTokenTimer == nil {
			refreshTokenTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(), queue: concurrentBackground)
			if let timer: DispatchSourceTimer = refreshTokenTimer {
				timer.setEventHandler {
					let queryURLString: String = self.oauthURL.absoluteString
					guard let query: String = self.refreshQuery, let token: String = self.refreshToken else { return }
					let queryURL: URL = URL(string: queryURLString + "?" + query + "=" + token)!
					let request: URLRequest = self.makeRequest(url: queryURL)
					let task: URLSessionDataTask = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (dat:Data?, resp: URLResponse?, err: Error?) in
						guard let data: Data = dat, let html: String = String(data: data, encoding: .utf8) else { return }
						let body: String = String(html.split(separator: ">",maxSplits: 11).last!)
						let jsonString: String = String(body.split(separator: "<", maxSplits: 2).first!)
						if let json: Data = jsonString.data(using: .utf8) {
							let decoder: JSONDecoder = JSONDecoder()
							do {
								let tokens: Tokens = try decoder.decode(Tokens.self, from: json)
								self.refreshToken = tokens.refresh_token
								self.accessToken = tokens.access_token
								_ = self.updateToken(to: self.refreshToken, tokenType: RefreshToken)
							} catch let error {
								print(error.localizedDescription)
							}// end do try - catch decode tokens json
						}// end if json to convert data
					}// end closure
					task.resume()
				}// end event handler
				timer.schedule(deadline: DispatchTime.now(), repeating: .seconds(expire), leeway: .microseconds(10))
				timer.resume()
			}// end if optional binding check for refresh token timer
			Thread.sleep(forTimeInterval: 2)
			getUserInfo()
		}// end if refresh token timer is not set
	}// end func start

	public func stop () {
		watcherCount -= 1
	}// end func stop

	public func getWSEndPoint (program liveNumber: String) -> URL {
		var wsEndPointURL: URL = URL(string: "https://live.nicovideo.jp")!
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let url: URL = URL(string: WSEndPointURLString + WSEndPointProgramKey + liveNumber + WSEndPointUserIDKey + userIdentifier)!
		let request = makeRequestWithAccessToken(url: url)
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
	}// end func getWSEndPoint

	public func makeRequest (url: URL) -> URLRequest {
		var request: URLRequest = URLRequest(url: url)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)

		return request
	}// end func makeRequest

	public func makeRequestWithAccessToken (url: URL) -> URLRequest {
		var request: URLRequest = URLRequest(url: url)
		if let token: String = accessToken {
			request.addValue(AutorizationBearer + token, forHTTPHeaderField: AuthorizationKey)
		}// end optional binding check for access token
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		request.httpMethod = "GET"

		return request
	}// end func makeRequest

		// MARK: - Private Methods
	private func getUserInfo() {
		let request:URLRequest =  makeRequestWithAccessToken(url: UserInfoURL)
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else { return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let userInfo: UserInfo = try decoder.decode(UserInfo.self, from: data)
				self.userIdentifier = userInfo.sub
				self.userNickname = userInfo.nickname
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode user info
		}// end completion handler
		task.resume()
	}// end func get user info from oAuth2 server

	private func saveToken (refreshToken token: String, tokenType type: String) -> Bool {
		let query: Dictionary<String, AnyObject> = [
			kSecClass as String: kSecClassGenericPassword,
			kSecReturnPersistentRef as String: kCFBooleanTrue,
			kSecAttrAccessible as String: kSecAttrAccessibleAlways,
			kSecAttrSynchronizable as String: kCFBooleanTrue,
			kSecAttrType as String: kSecAttrApplicationLabel,
			kSecAttrService as String: type as NSString,
			kSecValueData as String: token.data(using: .utf8)! as NSData
		]
		var result: AnyObject?
		let resultCode: OSStatus = withUnsafeMutablePointer(to: &result) {
			SecItemAdd(query as CFDictionary, $0)
		}
		if resultCode == errSecDuplicateItem {
			return false
		}

		return resultCode == errSecSuccess
	}// end func save token into keychain

	private func updateToken (to token: String, tokenType type: String) -> Bool {
		let query: Dictionary<String, AnyObject> = [
			kSecClass as String: kSecClassGenericPassword,
			kSecMatchLimit as String: kSecMatchLimitAll,
			kSecReturnPersistentRef as String: kCFBooleanTrue,
			kSecReturnData as String: kCFBooleanTrue,
			kSecAttrSynchronizable as String: kCFBooleanTrue,
			kSecAttrAccessible as String: kSecAttrAccessibleAlways,
			kSecAttrService as String: type as NSString
		]
		let itemToUpdate: Dictionary<String, AnyObject> = [
			kSecClass as String: kSecClassGenericPassword,
			kSecReturnPersistentRef as String: kCFBooleanTrue,
			kSecAttrAccessible as String: kSecAttrAccessibleAlways,
			kSecAttrSynchronizable as String: kCFBooleanTrue,
			kSecAttrType as String: kSecAttrApplicationLabel,
			kSecAttrService as String: type as NSString,
			kSecValueData as String: token.data(using: .utf8)! as NSData
		]
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

	private func readToken (tokenType type: String) -> String? {
		let query: Dictionary<String, AnyObject> = [
			kSecClass as String: kSecClassGenericPassword,
			kSecMatchLimit as String: kSecMatchLimitAll,
			kSecReturnPersistentRef as String: kCFBooleanTrue,
			kSecReturnData as String: kCFBooleanTrue,
			kSecAttrSynchronizable as String: kCFBooleanTrue,
			kSecAttrAccessible as String: kSecAttrAccessibleAlways,
			kSecAttrService as String: type as NSString
		]
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

		// MARK: - Delegate / Protocol clients
	public func webView (_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		if let url: URL = webView.url {
			if url.absoluteURL == AuthorizedURL {
				window?.setIsVisible(false)
			} else {
				window?.setIsVisible(true)
			}// end my window need visible or not
		}// end if my web view url is valid
	}// end func webView didStartProvisionalNavigation

	public func webView (_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		webView.evaluateJavaScript("document.getElementsByTagName('div')[0].innerHTML") { (json: Any?, error: Error?) -> Void in
			guard let jsonString: String = json as? String, let jsonData: Data = jsonString.data(using: .utf8) else { return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let tokens: Tokens = try decoder.decode(Tokens.self, from: jsonData)
				self.refreshToken = tokens.refresh_token
				self.accessToken = tokens.access_token
				if let id_token: String = tokens.id_token {
					self.idToken = id_token
				}
				self.expire = tokens.expires_in
				_ = self.updateToken(to: self.refreshToken, tokenType: RefreshToken)
				_ = self.updateToken(to: self.idToken, tokenType: IDToken)
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode json
		}// end evaluate java scrippt completion handler
	}// end func wevbiew didFinish
}// end class TokenManager
