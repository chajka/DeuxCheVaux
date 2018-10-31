//
//  OwnerAndVIPCommentHandler.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/25.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

public enum Color {
	enum normal: String {
		case white = "white"
		case red = "red"
		case pink = "pink"
		case orange = "orange"
		case yellow = "yellow"
		case green = "green"
		case cyan = "cyan"
		case blue = "bule"
		case purple = "purple"
		case black = "black"
	}// end enum normal member usable comment color
	enum vip: String {
		case white = "white"
		case red = "red"
		case green = "green"
		case blue = "bule"
		case cyan = "cyan"
		case yellow = "yellow"
		case purple = "purple"
		case pink = "pink"
		case orange = "orange"
		case niconicowhite = "niconicowhite"
	}// end enum
	enum premium: String {
		case white = "white"
		case red = "red"
		case pink = "pink"
		case orange = "orange"
		case yellow = "yellow"
		case green = "green"
		case cyan = "cyan"
		case blue = "bule"
		case purple = "purple"
		case black = "black"
		case white2 = "white2"
		case red2 = "red2"
		case pink2 = "pink2"
		case orange2 = "orange2"
		case yellow2 = "yellow2"
		case green2 = "green2"
		case cyan2 = "cyan2"
		case blue2 = "bule2"
		case purple2 = "purple2"
		case black2 = "black2"
	}// end enum premium member usable comment color
}// end usable color for comment

public enum CommentPostError: Error {
	case EmptyComment
	case NameUndefined
	case InvalidColor(String)
}// end public enum CommentPostError

private let apiBase: String = "http://live2.nicovideo.jp/watch/"

private let StartStopStream: String = "/segment"
private let operatorComment: String = "/operator_comment"
private let programExtension: String = "/extension"
private let vipComment: String = "/bsp_comment"
private let statistics: String = "/statistics"
private let contents: String = "/contents"
private let mixing: String = "/mixing"

private let perm: String = "/perm "
private let clear: String = "/clear"

private let ContentTypeKey: String = "Content-type"
private let ContentTypeJSON: String = "application/json"

enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
}// end enum httpMehod

enum StreamControl {
	enum Key: String {
		case state = "state"
	}// end enum Key
	enum Value: String {
		case start = "on_air"
		case end = "end"
	}// end enum value
}// end enum StreamControl

enum CommentKeys: String {
	case comment = "text"
	case name = "userName"
	case color = "color"
	case perm = "isPermanent"
	case link = "link"
}// end enum CommentKeys

extension StreamControl.Key: StringEnum { }
extension StreamControl.Value: StringEnum { }
extension CommentKeys: StringEnum { }

public final class OwnerAndVIPCommentHandler: NSObject {
	private let program: String
	private let apiBaseString: String
	private let cookies: Array<HTTPCookie>
	private var request: URLRequest
	private let session: URLSession

	public init(program: String, cookies: Array<HTTPCookie>) {
		self.program = program
		self.cookies = cookies
		apiBaseString = apiBase + self.program
		session = URLSession(configuration: URLSessionConfiguration.default)
		let url: URL = URL(string: apiBaseString)!
		request = URLRequest(url: url)
		if (cookies.count > 0) {
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		}// end if have cookies
	}// end init

	public func startStreaming() -> Void {
		guard let url = URL(string: apiBaseString + StartStopStream) else { return }
		var jsonDict: Dictionary<String, Any> = Dictionary()
		jsonDict[StreamControl.Key.state] = StreamControl.Value.start.rawValue
		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
			request.setValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
			request.httpMethod = HTTPMethod.put.rawValue
			request.url = url
			let task = session.dataTask(with: request)
			task.resume()
		} catch {
			print("Program \(program) can not serialize")
		}// end try - catch JSONSerialization
	}// end func startStreaming
	
	public func stopStreaming() -> Void {
		guard let url = URL(string: apiBaseString + StartStopStream) else { return }
		var jsonDict: Dictionary<String, Any> = Dictionary()
		jsonDict[StreamControl.Key.state] = StreamControl.Value.end.rawValue
		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
			request.setValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
			request.httpMethod = HTTPMethod.put.rawValue
			request.url = url
			let task = session.dataTask(with: request)
			task.resume()
		} catch {
			print("Program \(program) can not serialize")
		}// end try - catch JSONSerialization
	}// end func startStreaming

	public func postOwnerComment(comment: String, name: String = "", color: String = "white", isPerm: Bool = false) throws -> Void {
		if comment.isEmpty { throw CommentPostError.EmptyComment }
		var commentToPost = String(comment)
		if (comment.starts(with: clear)) {
			clearOwnerComment()
			return
		}// end if comment is clear command
		let commentColor = Color.premium(rawValue: color)
		if commentColor == nil { throw CommentPostError.InvalidColor(color)}
		var permanent: Bool = isPerm

		guard let url = URL(string: apiBaseString + operatorComment) else { return }
		if (comment.starts(with: perm)) {
			permanent = true
			commentToPost = String(comment.suffix(comment.count - perm.count))
		}// end if comment include permanent command
		
		var jsonDict: Dictionary<String, Any> = Dictionary()
		jsonDict[CommentKeys.comment] = commentToPost
		if permanent { jsonDict[CommentKeys.perm] = true }
		if !name.isEmpty { jsonDict[CommentKeys.name] = name }
		if !color.isEmpty { jsonDict[CommentKeys.color] = color }
		
		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
			request.url = url
			request.httpMethod = HTTPMethod.put.rawValue
			request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
			let task: URLSessionDataTask = session.dataTask(with: request)
			task.resume()
		} catch {
			print("Comment \(jsonDict) can not serialize")
		}// end try - catch JSONSerialization
	}// end func owner comment

	public func clearOwnerComment() -> Void {
		guard let url = URL(string: apiBaseString + operatorComment) else { return }
		request.url = url
		request.httpMethod = HTTPMethod.delete.rawValue
		request.setValue(nil, forHTTPHeaderField: ContentTypeKey)
		request.httpBody = nil
		let task: URLSessionDataTask = session.dataTask(with: request)
		task.resume()
	}// end clearOwnerComment

	public func postVIPComment(comment: String, name: String, color: String) throws -> Void {
		let vipCommentColor: Color.vip? = Color.vip(rawValue: color)
		if vipCommentColor == nil { throw CommentPostError.InvalidColor(color)}
		if name.isEmpty { throw CommentPostError.NameUndefined }
		if comment.isEmpty { throw CommentPostError.EmptyComment }

		guard let url = URL(string: apiBaseString + vipComment) else { return }
		var jsonDict: Dictionary<String, Any> = Dictionary()
		jsonDict[CommentKeys.comment] = comment
		jsonDict[CommentKeys.name] = name
		jsonDict[CommentKeys.color] = color
		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
			request.url = url
			request.httpMethod = HTTPMethod.post.rawValue
			request.setValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
			let task: URLSessionDataTask = session.dataTask(with: request)
			task.resume()
		} catch {
			print("Comment \(jsonDict) can not serialize")
		}// end try - catch JSONSerialization
	}// end func postVIPComment
}// end class OwnerAndVIPCommentHandler
