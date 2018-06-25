//
//  XMLSocketCommentVector.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/26.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

public protocol CommentSocketDelegate {
	func commentSocket(commentVector vector:XMLSocketCommentVector, didRecieveComment comment:XMLElement) -> Void
}// end protocol CommentSocketDelegate

public typealias heartbeatCallback = (_ commentCount:Int, _ watcherCount:Int, _ ticket:String) -> Void
typealias PostKeyCallBack = (_ postkey:String) -> Void

public let defaultHistroryCount:Int = 400

private let BufferSize:Int = 8192
private let threadFormat:String = "<thread thread=\"%@\" res_from=\"-%d\" version=\"20061206\" scores=\"1\"/>\0"
private let heartbeatFormat:String = "http://watch.live.nicovideo.jp/api/heartbeat?v="
private let postkeyFormat:String = "http://watch.live.nicovideo.jp/api/getpostkey?v="

private enum XML {
	enum Name:String {
		case Chat = "chat"
	}// end Name
	enum Attr:String {
		case Ticket = "ticket"
		case Thread = "thread"
		case UserID = "user_id"
		case Premium = "premium"
		case Locale = "locale"
		case Vops = "vpos"
		case Postkey = "postkey"
		case Command = "mail"
	}// end Attr
}// end enum

private enum POSTKey {
	enum Key:String {
		case Thread = "thread"
		case Block = "block_no"
		case UseLocale = "uselc"
		case Locale = "locale_flag"
		case Lang = "lang_flag"
		case Seat = "seat_flag"
	}// end enum Key
	
	enum UseLocale:String {
		case UseLocale = "1"
	}// end enum
	
	enum Locale:String {
		case Null = "null"
	}// end enum
	
	enum Lang:String {
		case ja = "1"
		case zh = "2"
		case en = "4"
	}// end enum
	
	enum Seat:String {
		case ja = "1"
		case zh = "4"
		case en = "8"
	}// end enum
}// end enum POSTKey

extension XML.Name: StringEnum { }
extension XML.Attr: StringEnum { }
extension POSTKey.Key: StringEnum { }
extension POSTKey.UseLocale: StringEnum { }
extension POSTKey.Locale: StringEnum { }
extension POSTKey.Lang: StringEnum { }
extension POSTKey.Seat: StringEnum { }

public class XMLSocketCommentVector: NSObject {

}
