//
//  NicoNicoInformationFetcher.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/12.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

fileprivate let RequestTimeOut: TimeInterval = 2.0
fileprivate let DataTimeOut: TimeInterval = 2.0
fileprivate let Timeout: Double = 2.0

public final class NicoNicoInformationFetcher: NSObject {
		// MARK:   Outlets
		// MARK: - Properties
		// MARK: - Member variables
	private var session: URLSessionConfiguration
	private let cookies: Array<HTTPCookie>

		// MARK: - Constructor/Destructor
	public init (_ cookie: Array<HTTPCookie>) {
		session = URLSessionConfiguration.default
		session.timeoutIntervalForRequest = RequestTimeOut
		session.timeoutIntervalForResource = DataTimeOut
		session.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.onlyFromMainDocumentDomain
		self.cookies = cookie
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Internal methods
		// MARK: - Private methods
		// MARK: - Delegates
}// end NicoNicoInformationFetcher
