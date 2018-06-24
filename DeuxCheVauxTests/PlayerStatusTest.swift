//
//  PlayerStatusTest.swift
//  DeuxCheVauxTests
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import XCTest

class PlayerStatusTest: XCTestCase {
	private let user_session_value:String = "user_session_6347612_a0c800610aa6bbe0f20ad9edb3ab94d3b8b0b369f96eb0fcfcf70f1ed69e097a"
	private let liveNumber:String = "lv314021092"
	
	private var cookie:HTTPCookie!
	
	override func setUp() {
		super.setUp()
		cookie = HTTPCookie(properties: [HTTPCookiePropertyKey.name: "user_session", HTTPCookiePropertyKey.value: user_session_value, HTTPCookiePropertyKey.domain: "nicovideo.jp", HTTPCookiePropertyKey.path: "/"])
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func test01_allocation() {
		let playerstatus:PlayerStatus = PlayerStatus(program: liveNumber, cookies: [cookie])
		XCTAssertNotNil(playerstatus, "player status is nil")
	}
	
	func test02_properties() {
		let playerstatus:PlayerStatus = PlayerStatus(program: liveNumber, cookies: [cookie])
		XCTAssertNotNil(playerstatus, "player status is nil")
		XCTAssertNotNil(playerstatus.number, "property programNumber is nil")
		XCTAssertNotNil(playerstatus.title, "property title is nil")
		XCTAssertNotNil(playerstatus.desc, "property desc is nil")
		XCTAssertNotNil(playerstatus.socialType, "property socialType is nil")
		XCTAssertNotNil(playerstatus.community, "property socialType is nil")
		XCTAssertFalse(playerstatus.isOwner, "property isOwner is true")
		XCTAssertNotNil(playerstatus.ownerIdentifier, "property isOwner is true")
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measure {
			// Put the code you want to measure the time of here.
		}
	}
}
