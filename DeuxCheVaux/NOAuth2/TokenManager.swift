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


public final class TokenManager: NSWindowController, WKNavigationDelegate {
		// MARK:   Class Variables
		// MARK: - Class Methods
		// MARK: - Properties
		// MARK: - Computed Properties
		// MARK: - Outlets
		// MARK: - Member Variables
		// MARK: - Constructor / Destructor
		// MARK: - OVerrides
	public override func windowDidLoad() {
		super.windowDidLoad()
	}// end window did load

		// MARK: - Actions
		// MARK: - Public Method
		// MARK: - Private Methods
		// MARK: - Delegate / Protocol clients
}// end class TokenManager
