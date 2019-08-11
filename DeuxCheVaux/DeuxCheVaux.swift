//
//  DeuxCheVaux.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/11.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

internal let FramewrokName: String = "DeuxCheVaux"

public final class DeuxCheVaux: NSObject {
		// MARK:   Class Variable
		// MARK: - Properties
	public var applicationName: String
	public var applicationVersionMajor: Float
	public var applicationVersionMinor: Int
	public var applicationVersionFix: Int
	public var frameworkName: String
	public var framewrokVersionMajor: Float
	public var framewrokVersionMinor: Int
	public var framerokVersionFix: Int
	public var userAgent: String {
		get {
			let applicationNameVersion = "\(applicationName)/\(applicationVersionMajor).\(applicationVersionMinor).\(applicationVersionFix)"
			let frameworkNameVersiion = "\(framewrokVersionMajor) \(framewrokVersionMajor).\(framewrokVersionMinor).\(framerokVersionFix)"
			return "\(applicationNameVersion) (\(frameworkNameVersiion))"
		}// end get
	}// end computed property

		// MARK: - Member variables
		// MARK: - Constructor/Destructor
		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
		// MARK: - Internal methods
		// MARK: - Private methods
		// MARK: - Delegates
}// end class DeuxCheVaux
