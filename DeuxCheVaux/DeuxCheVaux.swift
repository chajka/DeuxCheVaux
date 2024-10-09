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
fileprivate let FrameworkVersionMinor: Int = 3
fileprivate let FrameworkVersionFix: Int = 0

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

		// MARK: - Member variables

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
	}// end private init

		// MARK: - Override
		// MARK: - Public methods
	public func setFirstLaucn () {
		firstLaunch = true
	}// end setFirstLaucn
		// MARK: - Internal methods
		// MARK: - Private methods
		// MARK: - Delegates
}// end class DeuxCheVaux
