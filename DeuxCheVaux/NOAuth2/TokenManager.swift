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

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

public final class TokenManager: NSWindowController, WKNavigationDelegate {
		// MARK:   Class Variables
		// MARK: - Class Methods
		// MARK: - Properties
		// MARK: - Computed Properties
		// MARK: - Outlets
		// MARK: - Member Variables
		// MARK: - Constructor / Destructor
		// MARK: - OVerrides
		// MARK: - Actions
		// MARK: - Public Method
		// MARK: - Private Methods
		// MARK: - Delegate / Protocol clients
}// end class TokenManager
