//
//  PublishStatusTest.swift
//  DeuxCheVauxTests
//
//  Created by Чайка on 2018/06/24.
//  Copyright © 2018 Чайка. All rights reserved.
//

import XCTest

class PublishStatusTest: XCTestCase {
	private let user_session_value:String = "user_session_6347612_a0c800610aa6bbe0f20ad9edb3ab94d3b8b0b369f96eb0fcfcf70f1ed69e097a"
	
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
		let publishStatus:PublishStatus = PublishStatus(program: liveNumber, cookies: [cookie])
		XCTAssertNotNil(publishStatus, "class PublishStatus initialize failed")
    }

	func test01_properties() {
		let publishStatus:PublishStatus = PublishStatus(program: liveNumber, cookies: [cookie])
		XCTAssertNotNil(publishStatus, "class PublishStatus initialize failed")

		XCTAssertEqual(publishStatus.number, liveNumber, "property number is wrong")
		XCTAssertNotNil(publishStatus.token, "property token can not parsed")
		XCTAssertFalse(publishStatus.canVote, "property canVote cannot parsed")
		XCTAssertNotNil(publishStatus.rtmpURL, "property rtmp url can not parsed")
	}

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
