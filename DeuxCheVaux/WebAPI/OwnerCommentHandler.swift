//
//  OwnerCommentHandler.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/25.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

	// MARK: common structure
internal struct MetaInformation: Codable {
	let status: Int
	let errorCode: String
	let errorMessage: String?
}// end struct MetaInformation

internal struct ProgramState: Codable {
	var state: String
}// end struct ProgramState

// MARK: miixing / quote specific structure
public enum MixingMode {
	case main
	case sub
	case soundOnly
	case swap
	case swapSoundOnly
}// end enum MixingMode

public enum MixingState: String {
	case main = "main"
	case sub = "sub"
	case soundonly = "none"
}// end enum MixingState

public struct Context: Codable {
	let content: String
	var audio: Float
	var display: String

	var displayType: MixingState {
		get {
			if let type: MixingState = MixingState(rawValue: display) {
				return type
			} else {
				return MixingState.soundonly
			}// end if optional binding check for current display type
		}// end get
		set {
			display = newValue.rawValue
		}// end set
	}// end computed property MixingState
}// end struct Context

public struct Mixing: Codable {
	let mixing: Array<Context>
}// end struct Mixing

public struct MixInfo: Codable {
	let data: Mixing?
	let meta: MetaInformation
}// end struct MixInfo

	// MARK: end time enhancement specific definition
internal struct ExtendMehtod: Codable {
	var minutes: Int
	var type: String
}// end ExtendMehtod

internal struct ExtendMethods: Codable {
	var methods: Array<ExtendMehtod>?
}// end struct ExtendMethods

internal struct TimeExtension: Codable {
	var data: ExtendMethods?
	var meta: MetaInformation
}// end struct TimeExtension

internal struct ExtendTime: Codable {
	var minutes: Int
}// end struct ExtendTime

internal struct NewEndTime: Codable {
	var end_time: TimeInterval
}// end struct NewEndTime

internal struct TimeExtendResult: Codable {
	var data: NewEndTime?
	var meta: MetaInformation
}// end struct TimeExtendResult

internal struct NewTimes: Codable {
	var start_time: TimeInterval
	var end_time: TimeInterval
}// end struct NewTimes

internal struct UpdateStateResult: Codable {
	var data: NewTimes?
	var meta: MetaInformation
}// end struct UpdateStateResult

	// MAR: Questioonary specific definition
public enum EnqueteError {
	case noError
	case itemCountUnderTwo
	case itemCountOverNine
	case encodeError
	case urlError
	case timeoutError
	case apiError
}// end enum EnqueteError

internal struct Enquete: Codable {
	let question: String
	let items: Array<String>
}// end struct Enquete

public struct EnqueteItem: Codable {
	public let name: String
	public let rate: Float
}// end struct EnqueteItem

internal struct EnqueteData: Codable {
	let title: String
	let items: Array<EnqueteItem>
}// end struct EnqueteData

internal struct EnqueteResult: Codable {
	let data: EnqueteData?
	let meta: MetaInformation
}// end struct EnqueteResult

	// MARK: State control specfic definition
enum StreamControl {
	enum Key: String {
		case state = "state"
	}// end enum Key
	enum Value: String {
		case start = "on_air"
		case end = "end"
	}// end enum value
}// end enum StreamControl

enum CommentKeys: String {
	case comment = "text"
	case name = "userName"
	case color = "color"
	case perm = "isPermanent"
	case link = "link"
}// end enum CommentKeys

extension StreamControl.Key: StringEnum { }
extension StreamControl.Value: StringEnum { }
extension CommentKeys: StringEnum { }

fileprivate let Timeout: Double = 2.0
fileprivate let Success: String = "OK"

public enum Color {
	enum normal: String {
		case white = "white"
		case red = "red"
		case pink = "pink"
		case orange = "orange"
		case yellow = "yellow"
		case green = "green"
		case cyan = "cyan"
		case blue = "bule"
		case purple = "purple"
		case black = "black"
	}// end enum normal member usable comment color
	enum premium: String {
		case white = "white"
		case red = "red"
		case pink = "pink"
		case orange = "orange"
		case yellow = "yellow"
		case green = "green"
		case cyan = "cyan"
		case blue = "bule"
		case purple = "purple"
		case black = "black"
		case white2 = "white2"
		case red2 = "red2"
		case pink2 = "pink2"
		case orange2 = "orange2"
		case yellow2 = "yellow2"
		case green2 = "green2"
		case cyan2 = "cyan2"
		case blue2 = "bule2"
		case purple2 = "purple2"
		case black2 = "black2"
	}// end enum premium member usable comment color
}// end usable color for comment

public enum CommentPostError: Error {
	case EmptyComment
	case NameUndefined
	case InvalidColor(String)
}// end public enum CommentPostError

private let UserAgentKey: String = "User-Agent"
private let UserAgent: String = "Charleston/0.6 (DeuxCheVaux 0.3.4.0)"
private let ContentTypeKey: String = "Content-type"
private let ContentTypeJSON: String = "application/json"

private let apiBase: String = "https://live2.nicovideo.jp/watch/"
private let UserNamaAPIBase: String = "https://live2.nicovideo.jp/unama/watch/"

private let StartStopStream: String = "/segment"
private let operatorComment: String = "/operator_comment"
private let programExtension: String = "/extension"
private let vipComment: String = "/bsp_comment"
private let statistics: String = "/statistics"
private let contents: String = "/contents"
private let mixing: String = "/broadcast/mixing"
private let Questionary: String = "/enquete"
private let QuestionaryResult: String = "/enquete/result"

private let perm: String = "/perm "
private let clear: String = "/clear"

public extension URLRequest {
	enum HTTPMethod: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
	}// end enum httpMehod
	
	var method: HTTPMethod? {
		get {
			if let method: String = self.httpMethod {
				return HTTPMethod(rawValue: method)
			}// end get
			return nil
		}// end get
		set {
			if let httpMehtod: HTTPMethod = newValue {
				self.httpMethod = httpMehtod.rawValue
			} else {
				self.httpMethod = ""
			}// end if
		}// end set
	}// end property extension of URLRequest
}// end of extension of URLRequest

public final class OwnerCommentHandler: NSObject {
		// MARK: - Properties
		// MARK: - Member variables
	private let program: String
	private let apiBaseString: String
	private let cookies: Array<HTTPCookie>
	private let session: URLSession

		// MARK: - Constructor/Destructor
	public init (program: String, cookies: Array<HTTPCookie>) {
		self.program = program
		self.cookies = cookies
		apiBaseString = apiBase + self.program
		session = URLSession(configuration: URLSessionConfiguration.default)
	}// end init

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
	public func startStreaming () -> Void {
		guard let url = URL(string: apiBaseString + StartStopStream) else { return }
		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
		var jsonDict: Dictionary<String, Any> = Dictionary()
		jsonDict[StreamControl.Key.state] = StreamControl.Value.start.rawValue
		do {
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
			request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
			request.setValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
			request.method = URLRequest.HTTPMethod.put
			request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
			let task = session.dataTask(with: request)
			task.resume()
		} catch {
			print("Program \(program) can not serialize")
		}// end try - catch JSONSerialization
	}// end func startStreaming

	public func stopStreaming () -> Void {
		guard let url = URL(string: apiBaseString + StartStopStream) else { return }
		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
		var jsonDict: Dictionary<String, Any> = Dictionary()
		jsonDict[StreamControl.Key.state] = StreamControl.Value.end.rawValue
		do {
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
			request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
			request.setValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
			request.method = URLRequest.HTTPMethod.put
			request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
			let task = session.dataTask(with: request)
			task.resume()
		} catch {
			print("Program \(program) can not serialize")
		}// end try - catch JSONSerialization
	}// end func startStreaming

	public func postOwnerComment (comment: String, name: String = "", color: String = "white", isPerm: Bool = false) throws -> Void {
		if comment.isEmpty { throw CommentPostError.EmptyComment }
		var commentToPost = String(comment)
		if (comment.starts(with: clear)) {
			clearOwnerComment()
			return
		}// end if comment is clear command
		let commentColor = Color.premium(rawValue: color)
		if commentColor == nil { throw CommentPostError.InvalidColor(color)}
		var permanent: Bool = isPerm

		guard let url = URL(string: apiBaseString + operatorComment) else { return }
		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		if (comment.starts(with: perm)) {
			permanent = true
			commentToPost = String(comment.suffix(comment.count - perm.count))
		}// end if comment include permanent command

		var jsonDict: Dictionary<String, Any> = Dictionary()
		jsonDict[CommentKeys.comment] = commentToPost
		if permanent { jsonDict[CommentKeys.perm] = true }
		if !name.isEmpty { jsonDict[CommentKeys.name] = name }
		if !color.isEmpty { jsonDict[CommentKeys.color] = color }

		do {
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
			request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
			request.method = URLRequest.HTTPMethod.put
			request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
			request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
			let task: URLSessionDataTask = session.dataTask(with: request)
			task.resume()
		} catch {
			print("Comment \(jsonDict) can not serialize")
		}// end try - catch JSONSerialization
	}// end func owner comment

	public func clearOwnerComment () -> Void {
		guard let url = URL(string: apiBaseString + operatorComment) else { return }
		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		request.setValue(nil, forHTTPHeaderField: ContentTypeKey)
		request.method = URLRequest.HTTPMethod.delete
		request.httpBody = nil
		let task: URLSessionDataTask = session.dataTask(with: request)
		task.resume()
	}// end clearOwnerComment

	public func questionary (title question: String, choices items: Array<String>) -> EnqueteError {
		let capableItemSount: Set = Set(2...9)
		let itemCount: Int = items.count
		if !capableItemSount.contains(itemCount) {
			if itemCount < 2 { return .itemCountUnderTwo }
			else { return .itemCountOverNine }
		}// end if items count is invalid
		guard let url: URL = URL(string: UserNamaAPIBase + program + Questionary) else { return .urlError }

		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		request.setValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		request.method = .post
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let enquetee: Enquete = Enquete(question: question, items: items)
		let encoder: JSONEncoder = JSONEncoder()
		let decoder: JSONDecoder = JSONDecoder()
		do {
			var result: EnqueteResult?
			let data: Data = try encoder.encode(enquetee)
			request.httpBody = data
			let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, req: URLResponse?, err: Error?) in
				guard let data: Data = dat else {
					semaphore.signal()
					return
				}// end guard
				do {
					result = try decoder.decode(EnqueteResult.self, from: data)
					semaphore.signal()
				} catch let error {
					print(error.localizedDescription)
				}// end do try - catch decode result data
			}// end closure
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: .now() + Timeout)
			if timeout == .timedOut { return .timeoutError }
			if let result: EnqueteResult = result {
				if result.meta.status == 200 { return .noError }
				else { return .apiError }
			}// end if check result
		} catch let error {
			print(error.localizedDescription)
		}// end do try - catch encode Enquete struct to JSON string data

		return .encodeError
	}// end questionary

	public func displayQuestionaryResult () -> (success: Bool, answers: Array<EnqueteItem>?) {
		guard let url: URL = URL(string: UserNamaAPIBase + program + QuestionaryResult) else { return (false, nil) }

		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		request.method = .post
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let decoder: JSONDecoder = JSONDecoder()
		var success: Bool = false
		var answers: Array<EnqueteItem>?
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, req: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard
			do {
				let result: EnqueteResult = try decoder.decode(EnqueteResult.self, from: data)
				if let data: EnqueteData = result.data, result.meta.status == 200 {
					success = true
					answers = data.items
				}// end if
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode result
			semaphore.signal()
		}// end closurre
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: .now() + Timeout)
		if timeout == .timedOut || !success { success = false }

		return (success, answers)
	}// end displayQuestionaryResult

	public func endQuestionary () -> Bool {
		guard let url: URL = URL(string: UserNamaAPIBase + program + Questionary) else { return false }

		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		request.method = .delete
		var success: Bool = false
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let decoder: JSONDecoder = JSONDecoder()
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, req: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard
			do {
				let result: EnqueteResult = try decoder.decode(EnqueteResult.self, from: data)
				if result.meta.status == 200 {
					success = true
				}// end if
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode result
		}// end closurre
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: .now() + Timeout)
		if timeout == .timedOut || !success { success = false }

		return success
	}// end endQuestionary

	public func currentMovieStatus () -> Array<Context> {
		guard let url: URL = URL(string: apiBaseString + program + mixing) else { return Array() }
		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		request.setValue(nil, forHTTPHeaderField: ContentTypeKey)
		request.method = URLRequest.HTTPMethod.get
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var mixInfor: Array<Context> = Array()
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat, resp, err) in
			if let data: Data = dat {
				do {
					let info: MixInfo = try JSONDecoder().decode(MixInfo.self, from: data)
					if info.meta.errorCode == Success, let mixing: Array<Context> = info.data?.mixing {
						mixInfor.append(contentsOf: mixing)
					}// end check error and optional binding check for mixing state
				} catch let error {
					print(error.localizedDescription)
				}// end do try - catch json decode
			}// end optional binding check for recieved data
		}// end closure
		task.resume()
		let _ = semaphore.wait(wallTimeout: DispatchWallTime.now() + Timeout)

		return mixInfor
	}// end currentMovieStatus

	public func mixingVideoOrOtherStreaming (target quote: String, mode mixingMode: MixingMode, volume streamingVolume: Float = 1.0, quotedVolume mixingVolume: Float = 0.1) -> Bool {
		var broadcast: String
		var quoted: String
		switch mixingMode {
		case .sub:
			broadcast = MixingState.main.rawValue
			quoted = MixingState.sub.rawValue
		case .soundOnly:
			broadcast = MixingState.main.rawValue
			quoted = MixingState.soundonly.rawValue
		case .swap:
			broadcast = MixingState.sub.rawValue
			quoted = MixingState.main.rawValue
		case .swapSoundOnly:
			broadcast = MixingState.soundonly.rawValue
			quoted = MixingState.main.rawValue
		case .main: fallthrough
		default:
			broadcast = MixingState.sub.rawValue
			quoted = MixingState.main.rawValue
		}// end switch case by selected tag

		let streaming: Context = Context(content: program, audio: streamingVolume, display: broadcast)
		let mixed: Context = Context(content: quote, audio: mixingVolume, display: quoted)
		let mix: Mixing = Mixing(mixing: [streaming, mixed])
		var success = false
		do {
			let encoder: JSONEncoder = JSONEncoder()
			encoder.outputFormatting = JSONEncoder.OutputFormatting.prettyPrinted
			let json: Data = try encoder.encode(mix)
			if let url: URL = URL(string: apiBaseString + mixing) {
				var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
				request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
				request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
				request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
				request.method = URLRequest.HTTPMethod.put
				request.httpBody = json
				let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
				let task: URLSessionDataTask = session.dataTask(with: request) { (dat, resp, err) in
					guard let data: Data = dat else { return }
					do {
						let result: MixInfo = try JSONDecoder().decode(MixInfo.self, from: data)
						if result.meta.errorCode == Success { success = true }
					} catch let error {
						print(error.localizedDescription)
					}// end do try - catch
					semaphore.signal()
				}// end closure
				task.resume()
				let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
				if timeout == DispatchTimeoutResult.success { success = true }
			}// end opttioonal checking for create url
		} catch let error {
			print(error.localizedDescription)
		}// end do try - catch json encoding

		return success
	}// end mixing

	public func mixingOff () -> Bool {
		let streaming: Context = Context(content: program, audio: 1.0, display: MixingState.main.rawValue)
		let mix: Mixing = Mixing(mixing: [streaming])
		var success = false

		do {
			let encoder: JSONEncoder = JSONEncoder()
			encoder.outputFormatting = JSONEncoder.OutputFormatting.prettyPrinted
			let json: Data = try encoder.encode(mix)
			if let url: URL = URL(string: apiBaseString + mixing) {
				var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
				request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
				request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
				request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
				request.method = URLRequest.HTTPMethod.put
				request.httpBody = json
				let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
				let task: URLSessionDataTask = session.dataTask(with: request) { (dat, resp, err) in
					guard let data: Data = dat else { return }
					do {
						let result: MixInfo = try JSONDecoder().decode(MixInfo.self, from: data)
						if result.meta.errorCode == Success { success = true }
					} catch let error {
						print(error.localizedDescription)
					}// end do try - catch
					semaphore.signal()
				}// end closure
				task.resume()
				let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
				if timeout == DispatchTimeoutResult.success { success = true }
			}// end opttioonal checking for create url
		} catch let error {
			print(error.localizedDescription)
		}// end do try - catch json encoding

		return success
	}// end mixingOff

	public func extendableTimes () -> Array<String> {
		var extendableTimes: Array<String> = Array()
		if let url: URL = URL(string: apiBaseString + programExtension) {
			var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
			request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
			request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
			request.method = .get
			var success: Bool = false
			repeat {
				Thread.sleep(forTimeInterval: 10)
				let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
				let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
					guard let data: Data = dat else { return }
					do {
						let decoder: JSONDecoder = JSONDecoder()
						let extendableList: TimeExtension = try decoder.decode(TimeExtension.self, from: data)
						if let methods: Array<ExtendMehtod> = extendableList.data?.methods {
							for method: ExtendMehtod in methods {
								extendableTimes.append(String(method.minutes))
							}// end foreach methods
						}// end optional binding for
					} catch let error {
						print(error)
					}// end do try - catch decode result json
					semaphore.signal()
				}// end closure of request completion handler
				task.resume()
				let result: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
				if result == .success && extendableTimes.count > 0 { success = true }
			} while (!success)
		}// end optional binding check for make extension api url

		return extendableTimes
	}// end extendableTimes

	public func extendTime (minutes min: String) -> (status: Int, newEndTime: Date?) {
		guard let minutesToExtend: Int = Int(min) else { return (0, nil) }
		let extend: ExtendTime = ExtendTime(minutes: minutesToExtend)
		let encoder: JSONEncoder = JSONEncoder()
		do {
			let extendTimeData: Data = try encoder.encode(extend)
			if let url: URL = URL(string: apiBaseString + programExtension) {
				var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
				request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
				request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
				request.method = .post
				request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
				request.httpBody = extendTimeData
				let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
				var status: Int = 0
				var newEndTime: Date? = nil
				let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
					guard let data: Data = dat else { return }
					let decoder: JSONDecoder = JSONDecoder()
					do {
						let extendResult: TimeExtendResult = try decoder.decode(TimeExtendResult.self, from: data)
						status = extendResult.meta.status
						if let newEnd: TimeInterval = extendResult.data?.end_time {
							newEndTime = Date(timeIntervalSince1970: newEnd)
						}// end optional binding check for
					} catch let error {
						print(error)
					}// end do try - catch decode json data to result
					semaphore.signal()
				}// end closure of request completion handler
				task.resume()
				_ = semaphore.wait(timeout: DispatchTime.now() + Timeout)
				return (status, newEndTime)
			}// end optional binding check for make extension api url
		} catch let error {
			print(error)
		}// end do try - catch json encode

		return (200, nil)
	}// end extendTime

	public func updateProgramState (newState state: String) -> (startTime: Date, endTime: Date) {
		let nextState = ProgramState(state: state)
		let encoder: JSONEncoder = JSONEncoder()
		var startTime = Date()
		var endTime = startTime
		do {
			let extendTimeData: Data = try encoder.encode(nextState)
			if let url: URL = URL(string: apiBaseString + StartStopStream) {
				var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: Timeout)
				request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
				request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
				request.method = .put
				request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
				request.httpBody = extendTimeData
				let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
				let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
					guard let data: Data = dat else { return }
					let decoder: JSONDecoder = JSONDecoder()
					do {
						let updateStatedResult: UpdateStateResult = try decoder.decode(UpdateStateResult.self, from: data)
						if let newStart: TimeInterval = updateStatedResult.data?.start_time, let newEnd: TimeInterval = updateStatedResult.data?.end_time {
							startTime = Date(timeIntervalSince1970: newStart)
							endTime = Date(timeIntervalSince1970: newEnd)
						}// end optional binding
					} catch let error {
						print(error)
					}// end do try - catch decode json data to result
					semaphore.signal()
				}// end closure of request completion handler
				task.resume()
				_ = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			}// end optional binding check for make extension api url
		} catch let error {
			print(error)
		}// end do try - catch json encode

		return (startTime, endTime)
	}// eend updateProgramState

		// MARK: - Internal methods
		// MARK: - Private methods
		// MARK: - Delegates
}// end class OwnerAndVIPCommentHandler
