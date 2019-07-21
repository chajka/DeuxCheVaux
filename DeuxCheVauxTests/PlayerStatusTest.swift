//
//  PlayerStatusTest.swift
//  DeuxCheVauxTests
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import XCTest

class PlayerStatusTest: XCTestCase {

	private var cookie: HTTPCookie!

	override func setUp() {
		super.setUp()
		cookie = HTTPCookie(properties: [HTTPCookiePropertyKey.name: "user_session", HTTPCookiePropertyKey.value: user_session_value, HTTPCookiePropertyKey.domain: "nicovideo.jp", HTTPCookiePropertyKey.path: "/"])
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func test01_allocation() {
		let playerstatus: PlayerStatus = PlayerStatus(program: liveNumber, cookies: [cookie])
		XCTAssertNotNil(playerstatus, "player status is nil")
	}

	func test02_properties() {
		let playerstatus: PlayerStatus = PlayerStatus(program: liveNumber, cookies: [cookie])
		XCTAssertNotNil(playerstatus, "player status is nil")
		XCTAssertNotNil(playerstatus.number, "property programNumber is nil")
		XCTAssertNotNil(playerstatus.title, "property title is nil")
		XCTAssertNotNil(playerstatus.desc, "property desc is nil")
		XCTAssertNotNil(playerstatus.socialType, "property socialType is nil")
		XCTAssertNotNil(playerstatus.community, "property socialType is nil")
		XCTAssertTrue(playerstatus.isOwner, "property isOwner is not true")
		XCTAssertNotNil(playerstatus.ownerIdentifier, "property owner identifier is nil")
		XCTAssertNotNil(playerstatus.ownerName, "property owner name is nil")
		XCTAssertNotNil(playerstatus.baseTime, "property base time is nil")

		XCTAssertNotNil(playerstatus.listenerIdentifier, "property listener identifier is nil")
		XCTAssertNotNil(playerstatus.listenerName, "property listener name is nil")
		XCTAssertTrue(playerstatus.listenerIsPremium, "property listenerIsPremium is false")
		XCTAssertEqual(playerstatus.listenerLanguage, .en, "property listener language is not english")
		XCTAssertFalse(playerstatus.listenerIsVIP, "property listener is VIP is not true")
		XCTAssertGreaterThan(playerstatus.messageServers.count, 0, "property message servers is empty")
	}

	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measure {
			// Put the code you want to measure the time of here.
		}
	}
}
