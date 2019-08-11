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
fileprivate let NicknameNodeName: String = "nickname"
fileprivate let CouldNotParse = "Could not parse"

fileprivate let NicknameAPIFormat: String = "http://seiga.nicovideo.jp/api/user/info?id="

public final class NicoNicoInformationFetcher: NSObject {
		// MARK:   Outlets
		// MARK: - Properties
		// MARK: - Member variables
	private var session: URLSession
	private let cookies: Array<HTTPCookie>

		// MARK: - Constructor/Destructor
	public init (_ cookie: Array<HTTPCookie>) {
		let sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration.timeoutIntervalForRequest = RequestTimeOut
		sessionConfiguration.timeoutIntervalForResource = DataTimeOut
		sessionConfiguration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.onlyFromMainDocumentDomain
		session = URLSession(configuration: sessionConfiguration)
		self.cookies = cookie
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Internal methods
		// MARK: - Private methods
	private func fetchNickname (fromSeigaAPI identifier: String) -> String? {
		guard let url = URL(string: NicknameAPIFormat + identifier) else { return nil }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var nickname: String? = nil
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard
			do {
				let seiga: XMLDocument = try XMLDocument(data: data, options: .documentTidyXML)
				guard let children: Array<XMLNode> = seiga.children?.first?.children?.first?.children else { throw NSError(domain: CouldNotParse, code: 0, userInfo: nil)}
				for child: XMLNode in children {
					if child.name == NicknameNodeName { nickname = child.stringValue }
				}// end foreach children
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch
			semaphore.signal()
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { nickname = nil }

		return nickname
	}// end fetchNickname from seiga api

	private func fetchNickname (fromVitaAPI identifier: String) -> String? {
		guard let url = URL(string: VitaAPIFormat + identifier) else { return nil }
		let request: URLRequest = makeRequest(url: url, method: .get)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var nickname: String? = nil
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard
			do {
				let vita: XMLDocument = try XMLDocument(data: data, options: .documentTidyXML)
				guard let children: Array<XMLNode> = vita.children?.first?.children?.first?.children else { throw NSError(domain: CouldNotParse, code: 0, userInfo: nil)}
				for child: XMLNode in children {
					if child.name == NicknameNodeName { nickname = child.stringValue }
				}// end foreach children
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch
			semaphore.signal()
		}// end closure
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { nickname = nil }
		
		return nickname
	}// end fetchNickname from VITA api
	
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
