//
//  PlayerStatus.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

let playerStatusFormat:String = "http://watch.live.nicovideo.jp/api/getplayerstatus?v="

class PlayerStatus: NSObject , XMLParserDelegate {
	var programNumber:String
	var userSession:Array<HTTPCookie>

	var stringBuffer:String = String()

	init(program:String, cookies:Array<HTTPCookie>) {
		programNumber = program
		userSession = cookies
		super.init()
	}// end init

	func getPlayerStatus() -> Void {
		let playerStatusURLString:String = playerStatusFormat + programNumber
		if let playerStatusURL:URL = URL(string: playerStatusURLString) {
			let session:URLSession = URLSession(configuration: URLSessionConfiguration.default)
			var request = URLRequest(url: playerStatusURL)
			var parser:XMLParser?
			var recievieDone:Bool = false
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: userSession)
			let task:URLSessionDataTask = session.dataTask(with: request) { (dat, req, err) in
				guard let data = dat else { return }
				parser = XMLParser(data: data)
				recievieDone = true
			}// end closure
			task.resume()
			while !recievieDone { Thread.sleep(forTimeInterval: 0.1) }
			parser?.parse()
		}// end if url is not empty
	}// end function getPlayerStatus

	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		switch elementName {
		default:
			break
		}// end switch case by element name
	}// end func parser didEndElement

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		stringBuffer = String()
	}// end function parser didStartElement

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		stringBuffer += string
	}// end func parser foundCharracters
}// end class PlayerStatus
