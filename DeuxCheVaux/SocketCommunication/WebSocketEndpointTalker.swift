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
		// MARK: - Constructor / Destructor
	public init (url: URL) {
		self.url = url
	}// end init

		// MARK: - Overrides
		// MARK: - Actions
		// MARK: - Public Methods
		// MARK: - Private Methods
		// MARK: - Delegate / Protocol clients
}// end class WebSocketEndpointTalker
