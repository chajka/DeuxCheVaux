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

public class XMLSocketCommentVector: NSObject ,StreamDelegate {
	private let queue:DispatchQueue = DispatchQueue.global(qos: .default)
	private let sem:DispatchSemaphore
	
	private var writeable:Bool {
		willSet (value) {
			if value == true {
				guard let writeStream = outputStream else { return }
				_ = threadData.withUnsafeBytes( {(data:UnsafePointer<UInt8>) -> Void in writeStream.write(data, maxLength: threadData.count)})
			}// end didSet
		}// end computed property set
	}// end property writeable
	
	private let server:String
	private let port:Int
	private let thread:String
	private let threadData:Data
	private let userLanguage:UserLanguage
	private let program:String
	private let baseTiem:Date
	private let isPremium:Bool
	private let cookies:Array<HTTPCookie>
	
	private var runLoop:RunLoop!
	private var finishRunLoop:Bool = true
	
	private var inputStream:InputStream?
	private var outputStream:OutputStream?
	private var inputRemnant:Data = Data()
	
	public var delegate:CommentSocketDelegate!

	public init(playerStatus:PlayerStatus, serverOffset:Int, history:Int = defaultHistroryCount, cookies:Array<HTTPCookie>) {
		let messageServer = playerStatus.messageServers[serverOffset]
		server = messageServer.XMLSocet.address
		port = messageServer.XMLSocet.port
		thread = messageServer.thread
		threadData = String(format: threadFormat, messageServer.thread, history).data(using: .utf8)!
		baseTiem = playerStatus.baseTime
		isPremium = playerStatus.listenerIsPremium
		program = playerStatus.number
		userLanguage = playerStatus.listenerLanguage
		self.cookies = cookies
		writeable = false

		sem = DispatchSemaphore(value: serverOffset)
	}// end init
	
	deinit {
		if finishRunLoop != true { _ = close() }
	}// end deinit

	public func open() -> Bool {
		Stream.getStreamsToHost(withName: server, port: port, inputStream: &inputStream, outputStream: &outputStream)
		guard let readStream = inputStream, let writeStream = outputStream else { return false }
		queue.async {
			self.runLoop = RunLoop.current
			self.sem.signal()
			self.finishRunLoop = false
			
			while (!self.finishRunLoop) {
				RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
			}// end keep runloop
		}// end block async
		
		sem.wait()
		guard let runLoop = runLoop else { return false }
		for stream in [readStream, writeStream] {
			stream.delegate = self
			stream.open()
			stream.schedule(in: runLoop, forMode: .defaultRunLoopMode)
		}// end foreach streams
		
		return true
	}// end func open
	
	public func close() -> Bool {
		if finishRunLoop == true { return false }
		
		guard let readStream = inputStream, let writeStream = outputStream else { return false }
		guard let runLoop = runLoop else { return false }
		for stream in [readStream, writeStream] {
			stream.remove(from: runLoop, forMode: .defaultRunLoopMode)
			stream.close()
		}// end foreach streams
		
		inputStream = nil
		outputStream = nil
		stopRunLoop()
		
		return true
	}// end function close
	
	private func postkey(commentCount:Int, ticket:String, callback:@escaping PostKeyCallBack) -> Void {
		let result =  makePostKeyURL(commentCount:commentCount, ticket:ticket)
		let postkeyURL:URL = result.0
		let params:String = result.1
		let config = URLSessionConfiguration.default
		let session = URLSession(configuration: config)
		var req = URLRequest(url: postkeyURL)
		req.httpMethod = "POST"
		req.httpBody = params.data(using: .utf8)
		if (cookies.count > 0) {
			let cookiesForHeader = HTTPCookie.requestHeaderFields(with: cookies)
			req.allHTTPHeaderFields = cookiesForHeader
		}// end if have cookie(s)
		
		let task:URLSessionDataTask = session.dataTask(with: req) { (dat, resp, err) in
			guard let data:Data = dat else { return }
			let postkeyResult = String(data: data, encoding: String.Encoding.utf8)!
			let postkeys:Array<Substring> = postkeyResult.split(separator: "=", maxSplits: 2, omittingEmptySubsequences: true)
			if (postkeys.count == 2) {
				let postkey:String = String(postkeys.last!)
				callback(postkey)
			} else  {
				Swift.print(postkeyURL)
				return
			}// end if
		}// end process recieved data
		task.resume()
	}// end func postkey
	
	private func makePostKeyURL(commentCount:Int, ticket:String) -> (URL, String) {
		let therad:String = [POSTKey.Key.Thread.rawValue, thread].joined(separator: "=")
		let block:String = [POSTKey.Key.Block.rawValue, String(Int((commentCount + 1) / 100))].joined(separator: "=")
		let useLocale:String = [POSTKey.Key.UseLocale.rawValue, POSTKey.UseLocale.UseLocale.rawValue].joined(separator: "=")
		let locale:String = [POSTKey.Key.Locale.rawValue, POSTKey.Locale.Null.rawValue].joined(separator: "=")
		var lang:String
		var seat:String
		switch userLanguage {
		case UserLanguage.ja:
			lang = [POSTKey.Key.Lang.rawValue, POSTKey.Lang.ja.rawValue].joined(separator: "=")
			seat = [POSTKey.Key.Seat.rawValue, POSTKey.Seat.ja.rawValue].joined(separator: "=")
		case UserLanguage.zh:
			lang = [POSTKey.Key.Lang.rawValue, POSTKey.Lang.zh.rawValue].joined(separator: "=")
			seat = [POSTKey.Key.Seat.rawValue, POSTKey.Seat.zh.rawValue].joined(separator: "=")
		case UserLanguage.en:
			lang = [POSTKey.Key.Lang.rawValue, POSTKey.Lang.en.rawValue].joined(separator: "=")
			seat = [POSTKey.Key.Seat.rawValue, POSTKey.Seat.en.rawValue].joined(separator: "=")
		}// end switch
		
		let params:String = [therad, block, useLocale, lang, locale, seat].joined(separator: "&")
		let postkeyURLandParamStr:String = postkeyFormat + program
		let postkeysURL:URL = URL(string: postkeyURLandParamStr)!
		
		return (postkeysURL, params)
	}// end function makePostKeyURL
	
	private func stopRunLoop() -> Void {
		finishRunLoop = true
		let _:Timer = Timer(timeInterval: 0, target: self, selector: #selector(noop(timer:)), userInfo: nil, repeats: false)
	}// end function stopRunLoop
	
	@objc private func noop(timer:Timer) -> Void {
		// dummy noop function for terminate private run loop
	}// end function noop
}// end class XMLSocketCommentVector
