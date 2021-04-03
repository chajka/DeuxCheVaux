//
//  WebSocketEndpointTalker.swift
//  DeuxCheVaux
//
//  Created by Я Чайка on 2021/04/03.
//  Copyright © 2021 Чайка. All rights reserved.
//

import Cocoa
import SwiftWebSocket

fileprivate let SubProtocol: String = "msg.nicovideo.jp#json"

public final class WebSocketEndpointTalker: NSObject {
		// MARK:   Class Variables
		// MARK: - Class Methods
		// MARK: - Properties
	public let url: URL

		// MARK: - Computed Properties
		// MARK: - Outlets
		// MARK: - Member Variables
	private weak var runLoop: RunLoop? = DeuxCheVaux.shared.runLoop
	private var endpoint: WebSocket

		// MARK: - Constructor / Destructor
	public init (url: URL) {
		self.url = url
		var request: URLRequest = URLRequest(url: self.url)
		request.addValue(DeuxCheVaux.shared.userAgent, forHTTPHeaderField: UserAgentKey)
		if let runLoop: RunLoop = self.runLoop {
			endpoint = WebSocket(request: request, subProtocols: [SubProtocol], runLoop: runLoop)
		} else {
			endpoint = WebSocket(request: request, subProtocols: [SubProtocol])
		}// end optional binding check for runLoop
		endpoint.compression.on = true
		endpoint.allowSelfSignedSSL = true
	}// end init

		// MARK: - Overrides
		// MARK: - Actions
		// MARK: - Public Methods
		// MARK: - Private Methods
		// MARK: - Delegate / Protocol clients
}// end class WebSocketEndpointTalker
