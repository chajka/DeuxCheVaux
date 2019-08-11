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
	private func makeRequest (url requestURL: URL, method requestMethod: HTTPMethod, contentsType type: String? = nil) -> URLRequest {
		let deuxCheVaux: DeuxCheVaux = DeuxCheVaux.shared
		let userAgent: String = deuxCheVaux.userAgent
		var request: URLRequest = URLRequest(url: requestURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(userAgent, forHTTPHeaderField: UserAgentKey)
		if let contentsType: String = type {
			request.addValue(contentsType, forHTTPHeaderField: ContentTypeKey)
		}// end optional binding check for contents type
		request.method = requestMethod
 
		return request
	}// end makeRequest

		// MARK: - Delegates
}// end NicoNicoInformationFetcher
