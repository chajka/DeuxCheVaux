//
//  OwnerAndVIPCommentHandler.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/25.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

private let apiBase:String = "http://live2.nicovideo.jp/watch/"

private let operatorComment:String = "/operator_comment"
private let programExtension:String = "/extension"
private let vipComment:String = "/bsp_comment"
private let statistics:String = "/statistics"
private let contents:String = "/contents"
private let mixing:String = "/mixing"

private let perm:String = "/perm "
private let clear:String = "/cls"

private let ContentTypeKey:String = "Content-type"
private let ContentTypeJSON:String = "application/json"


enum HTTPMethod:String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
}// end enum httpMehod

enum CommentKeys:String {
	case comment = "text"
	case name = "userName"
	case color = "color"
	case perm = "isPermanent"
	case link = "link"
}// end enum CommentKeys

enum VIPCommentColor:String {
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
}// end enum VIPCommentColor

extension CommentKeys:StringEnum { }

class OwnerAndVIPCommentHandler: NSObject {
	private let program:String
	private let apiBaseString:String
	private let cookies:Array<HTTPCookie>
	private var request:URLRequest
	private let session:URLSession

	init(program:String, cookies:Array<HTTPCookie>) {
		self.program = program
		self.cookies = cookies
		apiBaseString = apiBase + self.program
		session = URLSession(configuration: URLSessionConfiguration.default)
		let url:URL = URL(string: apiBaseString)!
		request = URLRequest(url: url)
		if (cookies.count > 0) {
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		}// end if have cookies
	}// end init

	func ownerComment(comment:String, name:String = "", color:String = "", isPerm:Bool = false) throws -> Void {
		var permanent:Bool = isPerm
		var commentToPost = String(comment)
		if (comment.starts(with: clear)) {
			clearOwnerComment()
			return
		}// end if comment is clear command

		guard let url = URL(string: apiBaseString + operatorComment) else { return }
		if (comment.starts(with: perm)) {
			permanent = true
			commentToPost = String(comment.suffix(comment.count - perm.count))
		}// end if comment include permanent command
		
		var jsonDict:Dictionary<String, Any> = Dictionary()
		jsonDict[CommentKeys.comment] = commentToPost
		if permanent { jsonDict[CommentKeys.perm] = true }
		if !name.isEmpty { jsonDict[CommentKeys.name] = name }
		if !color.isEmpty { jsonDict[CommentKeys.color] = color }
		
		request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
		request.url = url
		request.httpMethod = HTTPMethod.put.rawValue
		request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		let task:URLSessionDataTask = session.dataTask(with: request)
		task.resume()
	}// end func owner comment

	func clearOwnerComment() -> Void {
		guard let url = URL(string: apiBaseString + operatorComment) else { return }
		request.url = url
		request.httpMethod = HTTPMethod.delete.rawValue
		request.setValue(nil, forHTTPHeaderField: ContentTypeKey)
		request.httpBody = nil
		let task:URLSessionDataTask = session.dataTask(with: request)
		task.resume()
	}// end clearOwnerComment

	func postVIPComment(comment:String, name:String, color:String) throws -> Void {
		let vipCommentColor:VIPCommentColor? = VIPCommentColor(rawValue: color)
		if (comment.isEmpty) || (name.isEmpty) || (vipCommentColor == nil) { return }
		guard let url = URL(string: apiBaseString + vipComment) else { return }
		var jsonDict:Dictionary<String, Any> = Dictionary()
		jsonDict[CommentKeys.comment] = comment
		jsonDict[CommentKeys.name] = name
		jsonDict[CommentKeys.color] = color
		
		request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
		request.url = url
		request.httpMethod = HTTPMethod.post.rawValue
		request.setValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		let task:URLSessionDataTask = session.dataTask(with: request)
		task.resume()
	}
}// end class OwnerAndVIPCommentHandler
