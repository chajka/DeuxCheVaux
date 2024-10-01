//
//  DeuxCheVaux.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/11.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

fileprivate let FrameworkName: String = "DeuxCheVaux"
fileprivate let FrameworkVersionMajor: Float = 0.7
fileprivate let FrameworkVersionMinor: Int = 1
fileprivate let FrameworkVersionFix: Int = 1

fileprivate let QueueLabel: String = "tv.from.chajka.DeuxCheVaux"

public enum StatusError: Error {
	case XMLParseError
}// end StatusError

public final class DeuxCheVaux: NSObject {
		// MARK:   Class Variable
	public static let shared: DeuxCheVaux = DeuxCheVaux()

		// MARK: - Properties
	public var applicationName: String
	public var applicationVersionMajor: Float
	public var applicationVersionMinor: Int
	public var applicationVersionFix: Int
	public private(set) var firstLaunch: Bool
	public let frameworkName: String
	public let frameworkVersionMajor: Float
	public let frameworkVersionMinor: Int
	public let frameworkVersionFix: Int
	public var userAgent: String {
		get {
			let applicationNameVersion = "\(applicationName)/\(applicationVersionMajor).\(applicationVersionMinor).\(applicationVersionFix)"
			let frameworkNameVersion = "\(frameworkName)/\(frameworkVersionMajor).\(frameworkVersionMinor).\(frameworkVersionFix)"
			return "\(applicationNameVersion) (\(frameworkNameVersion))"
		}// end get
	}// end computed property

	public private (set) var runLoop: RunLoop?

		// MARK: - Member variables
	private var queue: DispatchQueue?
	private var finishRunLoop: Bool = true
	private let nullDevice: OutputStream?

		// MARK: - Constructor/Destructor
	private override init() {
		applicationName = ""
		applicationVersionMajor = 0.0
		applicationVersionMinor = 0
		applicationVersionFix = 0
		firstLaunch = false
		frameworkName = FrameworkName
		frameworkVersionMajor = FrameworkVersionMajor
		frameworkVersionMinor = FrameworkVersionMinor
		frameworkVersionFix = FrameworkVersionFix
		let url: URL = URL(fileURLWithPath: nullDevicePath)
		if let outputStream: OutputStream = OutputStream(url: url, append: true) {
			self.nullDevice = outputStream
		} else {
			self.nullDevice = nil
		}// end if make null device output stream is success or not.
		super.init()
		startRunLoop()
		if let nullDevice: OutputStream = nullDevice, let runLoop = runLoop {
			nullDevice.open()
			nullDevice.schedule(in: runLoop, forMode: RunLoop.Mode.common)
		}// end if output stream of null device is there
	}// end private init

	deinit {
		if let nullDevice: OutputStream = nullDevice, let runLoop = runLoop {
			nullDevice.remove(from: runLoop, forMode: RunLoop.Mode.common)
			nullDevice.close()
		}// end if output stream of null device is there
		stopRunLoop()
	}// end deinit

		// MARK: - Override
		// MARK: - Public methods
	public func setFirstLaucn () {
		firstLaunch = true
	}// end setFirstLaucn
		// MARK: - Internal methods
		// MARK: - Private methods
		// MARK: - Delegates
}// end class DeuxCheVaux
