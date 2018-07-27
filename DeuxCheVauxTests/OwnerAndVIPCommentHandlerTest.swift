//
//  OwnerAndVIPCommentHandlerTest.swift
//  DeuxCheVauxTests
//
//  Created by Чайка on 2018/06/25.
//  Copyright © 2018 Чайка. All rights reserved.
//

import XCTest

class OwnerAndVIPCommentHandlerTest: XCTestCase {

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
		let operatorCommentor: OwnerAndVIPCommentHandler = OwnerAndVIPCommentHandler(program: liveNumber, cookies: [cookie])
		XCTAssertNotNil(operatorCommentor, "operatorCommentor can not initialized")
    }

	func test02_ownerComment() {
		let operatorCommentor: OwnerAndVIPCommentHandler = OwnerAndVIPCommentHandler(program: liveNumber, cookies: [cookie])
		do {
			try operatorCommentor.postOwnerComment(comment: "test comment", name: "Чайка", color: "green", isPerm: false)
			Thread.sleep(forTimeInterval: 10)
			try operatorCommentor.postOwnerComment(comment: "/perm test comment", color: "red", isPerm: false)
			Thread.sleep(forTimeInterval: 20)
			operatorCommentor.clearOwnerComment()
			try operatorCommentor.postVIPComment(comment: "BSP Comment test", name: "Чайка", color: "cyan")
		} catch {
			XCTAssertTrue(false, "JSON serialization throw error")
		}
	}

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
