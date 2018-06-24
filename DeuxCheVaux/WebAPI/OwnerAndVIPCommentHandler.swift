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

extension CommentKeys:StringEnum { }

class OwnerAndVIPCommentHandler: NSObject {

}
