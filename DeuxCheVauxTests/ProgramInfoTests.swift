//
//  ProgramInfoTests.swift
//  DeuxCheVauxTests
//
//  Created by Чайка on 2018/08/19.
//  Copyright © 2018 Чайка. All rights reserved.
//

import XCTest

class ProgramInfoTests: XCTestCase {

	var user_session: HTTPCookie!

    override func setUp() {
        super.setUp()

		user_session = HTTPCookie(properties: [HTTPCookiePropertyKey.domain : "nicovideo.jp", HTTPCookiePropertyKey.path : "/", HTTPCookiePropertyKey.name : "user_session", HTTPCookiePropertyKey.value : user_session_value])!
	}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
		do {
			let programInfo: ProgramInfo = try ProgramInfo(programNumber: liveNumber, cookies: [user_session])
			XCTAssertNotNil(programInfo, "programInfo can not allocated")
		} catch {
		}
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
