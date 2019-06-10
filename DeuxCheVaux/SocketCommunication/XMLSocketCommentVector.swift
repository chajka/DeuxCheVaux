//
//  XMLSocketCommentVector.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/26.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

public protocol XMLSocketCommentVectorDelegate {
	func commentVector(commentVector vector: XMLSocketCommentVector, didRecieveComment comment: XMLElement) -> Void
}// end protocol CommentSocketDelegate

public typealias heartbeatCallback = (_ commentCount: Int, _ watcherCount: Int, _ ticket: String) -> Void
typealias PostKeyCallBack = (_ postkey: String) -> Void

public let defaultHistroryCount: Int = 400

private let BufferSize: Int = 8192
private let threadFormat: String = "<thread thread=\"%@\" res_from=\"-%d\" version=\"20061206\" scores=\"1\"/>\0"
private let heartbeatFormat: String = "http://watch.live.nicovideo.jp/api/heartbeat?v="
private let postkeyFormat: String = "http://watch.live.nicovideo.jp/api/getpostkey?v="

private enum XML {
	enum Name: String {
		case Chat = "chat"
	}// end Name
	enum Attr: String {
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
	enum Key: String {
		case Thread = "thread"
		case Block = "block_no"
		case UseLocale = "uselc"
		case Locale = "locale_flag"
		case Lang = "lang_flag"
		case Seat = "seat_flag"
	}// end enum Key
	
	enum UseLocale: String {
		case UseLocale = "1"
	}// end enum
	
	enum Locale: String {
		case Null = "null"
	}// end enum
	
	enum Lang: String {
		case ja = "1"
		case zh = "2"
		case en = "4"
	}// end enum
	
	enum Seat: String {
		case ja = "1"
		case zh = "4"
		case en = "8"
	}// end enum
}// end enum POSTKey

private enum HeartbeatElement: String {
	case watch = "watchCount"
	case comment = "commentCount"
	case ticket = "ticket"

	static func ~= (lhs: HeartbeatElement, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ~=
	static func == (lhs: HeartbeatElement, rhs: String) -> Bool {
		return lhs.rawValue == rhs ? true : false
	}// end func ==
}// end enum HeartbeatElement

extension XML.Name: StringEnum { }
extension XML.Attr: StringEnum { }
extension POSTKey.Key: StringEnum { }
extension POSTKey.UseLocale: StringEnum { }
extension POSTKey.Locale: StringEnum { }
extension POSTKey.Lang: StringEnum { }
extension POSTKey.Seat: StringEnum { }

public final class XMLSocketCommentVector: NSObject ,StreamDelegate {
	public private(set) var runLoop: RunLoop?
	public private(set) var roomLabel: String? = nil

	private let queue: DispatchQueue = DispatchQueue.global(qos: .default)

	private var writeable: Bool {
		willSet (value) {
			if value == true {
				guard let writeStream = outputStream else { return }
				let data: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: threadData.count)
				threadData.copyBytes(to: data, count: threadData.count)
				let dataPointer: UnsafePointer<UInt8> = UnsafePointer<UInt8>(data)
				writeStream.write(dataPointer, maxLength: threadData.count)
				data.deallocate()
			}// end didSet
		}// end computed property set
	}// end property writeable
	
	private let server: String
	private let port: Int
	private let thread: String
	private let threadData: Data
	private let userIdentifier: String
	private let userLanguage: UserLanguage
	private let program: String
	private let baseTiem: Date
	private let isPremium: Bool
	private let cookies: Array<HTTPCookie>
	
	private var finishRunLoop: Bool = true
	
	private var inputStream: InputStream?
	private var outputStream: OutputStream?
	private var inputRemnant: Data = Data()
	
	public var delegate: XMLSocketCommentVectorDelegate!

	public init(playerStatus: PlayerStatus, serverOffset: Int, history: Int = defaultHistroryCount, cookies: Array<HTTPCookie>, inRunLoop runLoop: RunLoop? = nil) {
		let messageServer = playerStatus.messageServers[serverOffset]
		server = messageServer.XMLSocet.address
		port = messageServer.XMLSocet.port
		thread = messageServer.thread
		threadData = String(format: threadFormat, messageServer.thread, history).data(using: .utf8)!
		userIdentifier = playerStatus.listenerIdentifier
		baseTiem = playerStatus.baseTime
		isPremium = playerStatus.listenerIsPremium
		program = playerStatus.number
		userLanguage = playerStatus.listenerLanguage
		if let roomPrefix: Substring = messageServer.name?.prefix(1) {
			let prefix = String(roomPrefix)
			roomLabel = prefix == "c" ? "Arena" : "\u{7ACB} \(prefix):"
		} else {
			roomLabel = messageServer.name
		}
		self.cookies = cookies
		self.runLoop = runLoop
		writeable = false
	}// end init

	public init (_ messageServer: MessageServer, broadcastStatus playerStatus: PlayerStatus, history: Int = defaultHistroryCount, cookies: Array<HTTPCookie>, inRunLoop runLoop: RunLoop? = nil) {
		server = messageServer.XMLSocet.address
		port = messageServer.XMLSocet.port
		thread = messageServer.thread
		threadData = String(format: threadFormat, messageServer.thread, history).data(using: .utf8)!
		userIdentifier = playerStatus.listenerIdentifier
		baseTiem = playerStatus.baseTime
		isPremium = playerStatus.listenerIsPremium
		program = playerStatus.number
		userLanguage = playerStatus.listenerLanguage
		if let roomPrefix: Substring = messageServer.name?.prefix(1) {
			let prefix = String(roomPrefix)
			roomLabel = prefix == "c" ? "Arena" : messageServer.name
		} else {
			roomLabel = messageServer.name
		}
		self.cookies = cookies
		self.runLoop = runLoop
		writeable = false
	}// end init
	
	deinit {
		if finishRunLoop != true { _ = close() }
	}// end deinit

	public func open() -> Bool {
		Stream.getStreamsToHost(withName: server, port: port, inputStream: &inputStream, outputStream: &outputStream)
		guard let readStream = inputStream, let writeStream = outputStream else { return false }

		if runLoop == nil {
			queue.async { [weak self] in
				guard let weakSelf = self else { return }
				weakSelf.runLoop = RunLoop.current
				weakSelf.finishRunLoop = false
				while (!weakSelf.finishRunLoop) {
					RunLoop.current.run(mode: RunLoop.Mode.default, before: Date.distantFuture)
				}// end keep runloop
			}// end block async
		}// end if did not pass run loop, make it
		while (runLoop == nil) { Thread.sleep(forTimeInterval: 0.001) }

		guard let runLoop = runLoop else { return false }
		for stream in [readStream, writeStream] {
			stream.delegate = self
			stream.open()
			stream.schedule(in: runLoop, forMode: RunLoop.Mode.default)
		}// end foreach streams
		
		return true
	}// end func open
	
	public func close() -> Bool {
		if finishRunLoop == true { return false }
		
		guard let readStream = inputStream, let writeStream = outputStream else { return false }
		guard let runLoop = runLoop else { return false }
		for stream in [readStream, writeStream] {
			stream.remove(from: runLoop, forMode: RunLoop.Mode.default)
			stream.close()
		}// end foreach streams
		
		inputStream = nil
		outputStream = nil
		stopRunLoop()
		
		return true
	}// end function close
	
	public func comment(comment: String, command: Array<String>) -> Void {
		let chatXMLElement: XMLElement = XMLElement(name: XML.Name.Chat.rawValue, stringValue: comment)
		var attributes: Dictionary<String, String> = Dictionary()
		attributes[XML.Attr.Thread] = thread
		attributes[XML.Attr.UserID] = userIdentifier
		attributes[XML.Attr.Premium] = isPremium ? "1" : "0"
		attributes[XML.Attr.Locale] = userLanguage.rawValue
		
		if !command.isEmpty {
			attributes[XML.Attr.Command] = command.joined(separator: " ")
		}// end if have command
		
		heartbeat { (watchCount, commentCount, ticket) in
			if !ticket.isEmpty {
				self.postkey(commentCount: commentCount, ticket: ticket, callback: { (postkey) in
					attributes[XML.Attr.Ticket] = ticket
					attributes[XML.Attr.Postkey] = postkey
					attributes[XML.Attr.Vops] = String(Int((-self.baseTiem.timeIntervalSinceNow) * 100))
					chatXMLElement.setAttributesAs(attributes)
					
					let chatElement: String = chatXMLElement.xmlString + "\0"
					self.write(chatElement)
				})// end closure for postkey
			}// end if
		}// end closure for heartbeat
	}// end function comment
	
	public func heartbeat(_ callback: @escaping heartbeatCallback) -> Void {
		guard let heartbeatURL = URL(string: (heartbeatFormat + program)) else { return }
		let config = URLSessionConfiguration.default
		let session = URLSession(configuration: config)
		var req = URLRequest(url: heartbeatURL)
		if !cookies.isEmpty {
			let cookiesForHeader = HTTPCookie.requestHeaderFields(with: cookies)
			req.allHTTPHeaderFields = cookiesForHeader
		}// end if have cookies
		
		let task: URLSessionDataTask = session.dataTask(with: req) { (dat, res, err) in
			guard let data = dat else { return }
			do {
				let heartbeat = try XMLDocument(data: data, options: XMLNode.Options.documentTidyXML)
				let heartbeatStatus = heartbeat.rootElement()?.attribute(forName: "status")
				if heartbeatStatus?.stringValue == "ok" {
					guard let children = heartbeat.children?.last?.children else { return }
					var watch: Int = 0
					var comment: Int = 0
					var ticket: String = ""
					for child: XMLNode in children {
						guard let name = child.name else { break }
						switch name {
						case .watch:
							guard let watchCount = child.stringValue else { break }
							watch = Int(watchCount)!
						case .comment:
							guard let commentCount = child.stringValue else { break }
							comment = Int(commentCount)!
						case .ticket:
							guard let ticketString = child.stringValue else { break }
							ticket = ticketString
						default:
							break
						}// end switch child
					}// end foreach children
					callback(watch, comment, ticket)
				}// end if hertbeat status is OK
			} catch {
				callback(-1, -1, "")
			}// end try - catch
		}// end completion handler
		task.resume()
		
		return
	}// end function heartbeat
	
	private func write(_ message: String) -> Void {
		if (finishRunLoop) { return }
		guard let writeStream: OutputStream = outputStream, let stringDataToWrite: Data = message.data(using: String.Encoding.utf8) else { return }
		let data: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: stringDataToWrite.count)
		stringDataToWrite.copyBytes(to: data, count: stringDataToWrite.count)
		let dataPointer: UnsafePointer<UInt8> = UnsafePointer<UInt8>(data)
		writeStream.write(dataPointer, maxLength: stringDataToWrite.count)
		data.deallocate()
		Thread.sleep(forTimeInterval: 3)
	}// end function write
	
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch aStream {
		case outputStream!:
			handleWriteStreamEvent(eventCode: eventCode)
		case inputStream!:
			handleReadStreamEvent(eventCode: eventCode)
		default:
			break
		}// end switch
	}// end function stream: handleEventCode
	
	private func handleWriteStreamEvent(eventCode: Stream.Event) -> Void {
		guard let _ = outputStream else { return }
		switch eventCode {
		case .hasSpaceAvailable:
			if (!writeable) { self.writeable = true }
			print("write streame has byte available")
		case .endEncountered:
			print("Write Stream End Encounted")
		case .errorOccurred:
			print("Write Stream Error Occurred")
		default:
			print ("Write stream unknown Event Ocurred : \(eventCode)")
		}// end switch
	}// end function handleWriteSreamEvent
	
	private func handleReadStreamEvent(eventCode: Stream.Event) -> Void {
		var buffer = [UInt8](repeating: 0, count: BufferSize)
		guard let readStream = inputStream else { return }
		switch eventCode {
		case .hasBytesAvailable:
			let result: Int = readStream.read(&buffer, maxLength: buffer.count)
			switch result {
			case -1:
				print("Can not read")
			case 0:
				print("No data")
			default:
				let dataBuffer: Data = Data(buffer)
				var dataForSstrings: Array<Data> = dataBuffer.split(separator: 0)
				if (inputRemnant.count > 0) {
					dataForSstrings[0] = inputRemnant + dataForSstrings[0]
					inputRemnant = Data()
				}// end if have input remnant
				if (buffer[result - 1] != 0) {
					inputRemnant = dataForSstrings.last!
					dataForSstrings.removeLast()
				}// end if have remnant
				var comments: Array<String> = Array()
				for stringData: Data in dataForSstrings {
					if let comment = String(data: stringData, encoding: String.Encoding.utf8) {
						comments.append(comment)
					}// end if
				}// end foreach comment strings
				
				guard let commentSocketDelegate = delegate else { return }
				for comment in comments {
					do {
						let element: XMLElement = try XMLElement(xmlString: comment)
						commentSocketDelegate.commentVector(commentVector: self, didRecieveComment: element)
					} catch {
						print("comment socket recieve not a xml format string or broken string \(comment)")
					}// end try - catch parse xml element
				}// end foreach
		}// end switch result of read stream
		default:
			print("event is not has bytes available \(eventCode)")
		}// end switch by event code
	}// end function handleReadStreamEvent
	
	private func postkey(commentCount: Int, ticket: String, callback: @escaping PostKeyCallBack) -> Void {
		let (postkeyURL, params) =  makePostKeyURL(commentCount: commentCount, ticket: ticket)
		let config = URLSessionConfiguration.default
		let session = URLSession(configuration: config)
		var req = URLRequest(url: postkeyURL)
		req.httpMethod = HTTPMethod.post.rawValue
		req.httpBody = params.data(using: .utf8)
		if !cookies.isEmpty {
			let cookiesForHeader = HTTPCookie.requestHeaderFields(with: cookies)
			req.allHTTPHeaderFields = cookiesForHeader
		}// end if have cookie(s)
		
		let task: URLSessionDataTask = session.dataTask(with: req) { (dat, resp, err) in
			guard let data: Data = dat else { return }
			let postkeyResult = String(data: data, encoding: String.Encoding.utf8)!
			let postkeys: Array<Substring> = postkeyResult.split(separator: "=", maxSplits: 2, omittingEmptySubsequences: true)
			if (postkeys.count == 2) {
				let postkey: String = String(postkeys.last!)
				callback(postkey)
			} else  {
				Swift.print(postkeyURL)
				return
			}// end if
		}// end process recieved data
		task.resume()
	}// end func postkey
	
	private func makePostKeyURL(commentCount: Int, ticket: String) -> (URL, String) {
		let therad: String = [POSTKey.Key.Thread.rawValue, thread].joined(separator: "=")
		let block: String = [POSTKey.Key.Block.rawValue, String(Int((commentCount + 1) / 100))].joined(separator: "=")
		let useLocale: String = [POSTKey.Key.UseLocale.rawValue, POSTKey.UseLocale.UseLocale.rawValue].joined(separator: "=")
		let locale: String = [POSTKey.Key.Locale.rawValue, POSTKey.Locale.Null.rawValue].joined(separator: "=")
		var lang: String
		var seat: String
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
		
		let params: String = [therad, block, useLocale, lang, locale, seat].joined(separator: "&")
		let postkeyURLandParamStr: String = postkeyFormat + program
		let postkeysURL: URL = URL(string: postkeyURLandParamStr)!
		
		return (postkeysURL, params)
	}// end function makePostKeyURL
	
	private func stopRunLoop() -> Void {
		finishRunLoop = true
		let _: Timer = Timer(timeInterval: 0, target: self, selector: #selector(noop(timer: )), userInfo: nil, repeats: false)
	}// end function stopRunLoop
	
	@objc private func noop(timer: Timer) -> Void {
		// dummy noop function for terminate private run loop
	}// end function noop
}// end class XMLSocketCommentVector
