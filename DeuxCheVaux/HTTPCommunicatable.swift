//
//  HTTPCommunicatable.swift
//  Charleston
//
//  Created by Я Чайка on 2020/04/22.
//  Copyright © 2020 Чайка. All rights reserved.
//

import Cocoa

internal let Timeout: Double = 2.0
fileprivate let RequestTimeOut: TimeInterval = 2.0
fileprivate let DataTimeOut: TimeInterval = 2.0

internal let UserSessionName: String = "user_session"
internal let NicoSessionHeaderKey: String = "X-niconico-session"

public enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
	case patch = "PATCH"
}// end enum httpMehod

public extension URLRequest {
	var method: HTTPMethod? {
		get {
			if let method: String = self.httpMethod {
				return HTTPMethod(rawValue: method)
			}// end get
			return nil
		}// end get
		set {
			if let httpMethod: HTTPMethod = newValue {
				self.httpMethod = httpMethod.rawValue
			} else {
				self.httpMethod = HTTPMethod.get.rawValue
			}// end optional binding check for new value is member of enum HTTPMethod
		}// end set
	}// end computed property extension of URLRequest
}// end of extension of URLRequest

public class HTTPCommunicatable: NSObject {
		// MARK: Properties
		// MARK: - Member variables
	internal let session: URLSession

		// MARK: - Constructor/Destructor
	public override init () {
		let sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration.timeoutIntervalForRequest = RequestTimeOut
		sessionConfiguration.timeoutIntervalForResource = DataTimeOut
		sessionConfiguration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.onlyFromMainDocumentDomain
		session = URLSession(configuration: sessionConfiguration)
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Internal methods
	internal func makeRequest (url requestURL: URL, method requestMethod: HTTPMethod, contentsType type: String? = nil) -> URLRequest {
		let deuxCheVaux: DeuxCheVaux = DeuxCheVaux.shared
		let userAgent: String = deuxCheVaux.userAgent
		var request: URLRequest = URLRequest(url: requestURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.addValue(TokenManager.shared.user_session, forHTTPHeaderField: NicoSessionHeaderKey)
		request.addValue(userAgent, forHTTPHeaderField: UserAgentKey)
		if let contentsType: String = type {
			request.addValue(contentsType, forHTTPHeaderField: ContentTypeKey)
		}// end optional binding check for contents type
		request.method = requestMethod
		
		return request
	}// end makeRequest
	
		// MARK: - Private methods
		// MARK: - Delegates
}// end class HTTPCommunicatable
