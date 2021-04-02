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
fileprivate let AccessTokenInterval: Int = 60 * 60
fileprivate let AuthorizationKey: String = "Authorization"
fileprivate let AutorizationBearer: String = "bearer "
fileprivate let RefreshToken: String = "jp.nicovideo.oauth2-refresh_token"
fileprivate let IDToken: String = "jp.nicovideo.oauth2-id_token"

fileprivate struct Tokens : Codable {
	let access_token: String
	let token_type: String
	let expires_in: Int
	let scope: String
	let refresh_token: String
	let id_token: String?
}// end struct Tokens

public final class TokenManager: NSWindowController, WKNavigationDelegate {
		// MARK:   Class Variables
	public static let shared: TokenManager = TokenManager()

		// MARK: - Class Methods
		// MARK: - Properties
	public var refreshToken: String!
	public var accessToken: String!
	public var idToken: String!

		// MARK: - Computed Properties
		// MARK: - Outlets
	@IBOutlet weak var webView: WKWebView!

		// MARK: - Member Variables
	private let concurrentBackground: DispatchQueue = DispatchQueue(label: "tv.from.chajka.DeuxCheVaux", qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 0), attributes: DispatchQueue.Attributes.concurrent)
	private var oauthURL: URL!
	private var refreshQuery: String!
	private var expire: Int = AccessTokenInterval

	private var watcherCount: Int = 0

	private var refreshTokenTimer: DispatchSourceTimer? = nil

		// MARK: - Constructor / Destructor
		// MARK: - OVerrides
	public override func windowDidLoad() {
		super.windowDidLoad()
	}// end window did load

		// MARK: - Actions
		// MARK: - Public Method
		// MARK: - Private Methods
	func saveToken (refreshToken token: String, tokenType type: String) -> Bool {
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

	func updateToken (to token: String, tokenType type: String) -> Bool {
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

	func readToken (tokenType type: String) -> String? {
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
}// end class TokenManager
