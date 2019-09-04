//
//  DeuxCheVaux.swift
//  Charleston
//
//  Created by Я Чайка on 2019/08/11.
//  Copyright © 2019 Чайка. All rights reserved.
//

import Cocoa

internal let FramewrokName: String = "DeuxCheVaux"

fileprivate let QueueLabel: String = "tv.from.chajka.DeuxCheVaux"

public final class DeuxCheVaux: NSObject {
		// MARK:   Class Variable
	public static let shared: DeuxCheVaux = DeuxCheVaux()

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

	public private (set) var runLoop: RunLoop?

		// MARK: - Member variables
	private var queue: DispatchQueue?
	private var finishRunLoop: Bool = true

		// MARK: - Constructor/Destructor
	private override init() {
		applicationName = ""
		applicationVersionMajor = 0.0
		applicationVersionMinor = 0
		applicationVersionFix = 0
		frameworkName = FramewrokName
		framewrokVersionMajor = 0.3
		framewrokVersionMinor = 5
		framerokVersionFix = 1
		super.init()
		startRunLoop()
	}// end private init

	deinit {
		stopRunLoop()
	}// end deinit

		// MARK: - Override
		// MARK: - Public methods
		// MARK: - Internal methods
		// MARK: - Private methods
	private func startRunLoop () -> Void {
		runLoop = nil
		let qos: DispatchQoS = DispatchQoS(qosClass: .default, relativePriority: 0)
		queue = DispatchQueue(label: QueueLabel, qos: qos, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
		guard let runLoopQueue: DispatchQueue = self.queue else { return }
		finishRunLoop = false
		var runLoop: RunLoop? = nil
		let semaaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		runLoopQueue.async { [weak self] in
			guard let weakSelf = self else {
				semaaphore.signal()
				return
			}// end guard
			runLoop = RunLoop.current
			semaaphore.signal()
			while (!weakSelf.finishRunLoop) {
				RunLoop.current.run(mode: RunLoop.Mode.default, before: Date.distantFuture)
			}// end keep runloop
			Swift.print("exit runloop")
		}// end block async
		semaaphore.wait()
		print("RunLoop \(String(describing: runLoop))")
		if let rl: RunLoop = runLoop {
			self.runLoop = rl
		}// end optional binding cheeck for runLoop is assigned?
	}// end makeRunLoop

	private func stopRunLoop () -> Void {
		guard let runLoop: RunLoop = self.runLoop else { return }
		finishRunLoop = true
		let timer: Timer = Timer(timeInterval: 0, target: self, selector: #selector(noop(timer: )), userInfo: nil, repeats: false)
		runLoop.add(timer, forMode: RunLoop.Mode.default)
	}// end function stopRunLoop

	@objc private func noop(timer: Timer) -> Void {
		// dummy noop function for terminate private run loop
	}// end function noop

		// MARK: - Delegates
}// end class DeuxCheVaux