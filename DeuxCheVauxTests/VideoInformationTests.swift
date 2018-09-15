//
//  VideoInformationTests.swift
//  DeuxCheVauxTests
//
//  Created by Я Чайка on 2018/09/15.
//  Copyright © 2018 Чайка. All rights reserved.
//

import XCTest

class VideoInformationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test01_allocation() {
		let sm9: VideoInformation = VideoInformation(videoNumber: "sm9")
		XCTAssertNotNil(sm9, "video sm9’s allocation failed")
		XCTAssertNoThrow(try sm9.parse(), "video information for sm9 throw assert")
		do {
			let success: Bool = try sm9.parse()

			XCTAssertNotNil(sm9.time, "video title fetch failed")
			XCTAssertNotNil(sm9.videoDescription, "video description fetch failed")
			XCTAssertNotNil(sm9.time, "video play time fetch failed")
			XCTAssertGreaterThan(sm9.commentCount, 0, "comment count fetch failed")
			XCTAssertGreaterThan(sm9.myListCount, 0, "my list count fetch failed")
			XCTAssertGreaterThan(sm9.viewCount, 0, "view count fetch failed")
			XCTAssertGreaterThan(sm9.tags.count, 0, "tags fetch failed")
		} catch {
			XCTAssert(false, "throw is happend")
		}
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
