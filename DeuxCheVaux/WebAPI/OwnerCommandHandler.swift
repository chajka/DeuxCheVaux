//
//  OwnerCommentHandler.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/25.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

	// MARK: common structure
public enum ResultStatus: Equatable {
	case success
	case clientError(Int, String?, String?)
	case serverError(Int, String?, String?)
	case apiAddressError
	case argumentError
	case encodeRequestError
	case decodeResultError
	case recieveDetaNilError
	case timeout
	case unknownError
}// end enum ResultStatus

internal struct MetaInformation: Codable {
	let status: Int
	let errorCode: String?
	let errorMessage: String?
}// end struct MetaInformation

internal struct ProgramState: Codable {
	var state: NextProgramStatus
}// end struct ProgramState

	// MARK: miixing / quote specific structure
public enum MixingMode {
	case main
	case sub
	case soundOnly
	case swap
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

	// MARK: Old mixing api specific definition
public struct Mixing: Codable {
	let mixing: Array<Context>
}// end struct Mixing

public struct MixInfo: Codable {
	let data: Mixing?
	let meta: MetaInformation
}// end struct MixInfo

	// MARK: New mixing api specific definition
public enum QuateSource: String, Codable {
	case `self` = "self"
	case quote = "quote"
}// end enum QuateSource

internal struct Source: Codable {
	let source: QuateSource
	let volume: Float
	let isSoundOnly: Bool?
}// end struct Source

public enum ConteentType: String, Codable {
	case video = "video"
	case live = "live"
}// end enum ConteentsType

internal struct Content: Codable {
	let id: String
	let type: ConteentType
}// end struct Contents

internal struct Layout: Codable {
	let main: Source
	let sub: Source
}// end struct Layout

internal struct Quotation: Codable {
	let layout: Layout
	let contents: Array<Content>
}// end struct Quatation

internal struct UpdatteQuotation: Codable {
	let layout: Layout
	let `repeat`: Bool
}// end struct UpdatteQuotation

internal struct CurrentQuotation: Codable {
	let meta: MetaInformation
	let layout: Layout?
	let currentContent: Content?
}// end struct CurrentQuatation

internal struct UpdateLayout: Codable {
	let layout: Layout
}// end struct UpdateLayout

internal struct UpdateContents: Codable {
	let contents: Array<Content>
}// end struct UpdateContents

internal struct QuoteResult: Codable {
	let meta: MetaInformation
}// end struct QuoteResult

internal struct MovieInfo: Codable {
	let id: String
	let length: Int
	let title: String
	let userIdentifier: String
	let quotable: Bool
}// end struct MovieInfo

internal struct QuatableResult: Codable {
	let meta: MetaInformation
	let data: MovieInfo?
}// end struct QuatableResult

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
fileprivate let DefaultVolume: Float = 0.5
fileprivate let Success: String = "OK"
internal let SmileVideoPrefix: String = "sm"
internal let NicoMoviewPrefix: String = "nm"
internal let SmileOfficialPrefix: String = "so"
internal let NicoNicoLivePrefix: String = "lv"

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

private let ApiBase: String = "https://live2.nicovideo.jp/watch/"
private let UserNamaAPIBase: String = "https://live2.nicovideo.jp/unama/watch/"
private let QuateAPIBase: String = "https://lapi.spi.nicovideo.jp/v1/tools/live/contents/"
private let QuatableAPIBase: String = "https://lapi.spi.nicovideo.jp/v1/tools/live/quote/services/video/contents/"

private let StartStopStream: String = "/segment"
private let operatorComment: String = "/operator_comment"
private let programExtension: String = "/extension"
private let statistics: String = "/statistics"
private let contents: String = "/contents"
private let Questionary: String = "/enquete"
private let QuestionaryResult: String = "/enquete/result"
private let QuateSuffix: String = "/quotation"
private let QuateLayout: String = "/quotation/layout"
private let QuateContents: String = "/quotation/contents"

private let perm: String = "/perm "
private let clear: String = "/clear"

public enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
	case patch = "PATCH"
}// end enum httpMehod

public extension URLRequest {
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
				self.httpMethod = HTTPMethod.get.rawValue
			}// end optional binding check for new value is member of enum HTTPMethod
		}// end set
	}// end computed property extension of URLRequest
}// end of extension of URLRequest

public final class OwnerCommandHandler: NSObject {
		// MARK: - Properties
		// MARK: - Member variables
	private let program: String
	private let apiBaseString: String
	private let videoPrefixSet: Set<String>
	private let capableVolumeRange: Range<Float> = Range(uncheckedBounds: (lower: 0.0, upper: 1.0))
	private let cookies: Array<HTTPCookie>
	private let session: URLSession

		// MARK: - Constructor/Destructor
	public init (program: String, cookies: Array<HTTPCookie>) {
		self.program = program
		self.cookies = cookies
		videoPrefixSet = Set(arrayLiteral: SmileVideoPrefix, NicoMoviewPrefix, SmileOfficialPrefix)
		apiBaseString = ApiBase + self.program
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
			request.method = .put
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
			request.method = .put
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
			request.method = .put
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
		request.method = .delete
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

		// MARK: quote
	public func checkQuotable (_ video: String) -> Bool {
		guard let url: URL = URL(string: QuatableAPIBase + video) else { return false }

		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		request.method = .delete
		var quotable: Bool = false
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let decoder: JSONDecoder = JSONDecoder()
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard check data is not nil
			do {
				let result: QuatableResult = try decoder.decode(QuatableResult.self, from: data)
				if let info: MovieInfo = result.data {
					quotable = info.quotable
				}// end optional binding check for have data section from decoded json structure
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode recieved json
			
		}// end closure for url request result data handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut || !quotable { quotable = false }

		return quotable
	}// end checkQuotable

	public func startQuatation (quote quoteContent: String, mode mixingMode: MixingMode, mainVolume main: Float, quoteVolume quote: Float) -> Bool {
		var type: ConteentType? = nil
		let quoteContentPrefix: String = String(quoteContent.prefix(2))
		if videoPrefixSet.contains(quoteContentPrefix) { type = .video }
		else if quoteContentPrefix == NicoNicoLivePrefix { type = .live }
		guard let url: URL = URL(string: QuateAPIBase + program + QuateSuffix), let contentType: ConteentType = type else { return false }

		var mainSource: Source
		var subSource: Source
		let content: Content = Content(id: quoteContent, type: contentType)
		let mainVolume: Float = capableVolumeRange.contains(main) ? main : DefaultVolume
		let quoteVolume: Float = capableVolumeRange.contains(quote) ? quote : DefaultVolume
		switch mixingMode {
		case .main:
			mainSource = Source(source: .quote, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .mySelf, volume: quoteVolume, isSoundOnly: true)
		case .sub:
			mainSource = Source(source: .mySelf, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .quote, volume: quoteVolume, isSoundOnly: false)
		case .soundOnly:
			mainSource = Source(source: .mySelf, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .quote, volume: quoteVolume, isSoundOnly: true)
		case .swap:
			mainSource = Source(source: .quote, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .mySelf, volume: quoteVolume, isSoundOnly: false)
		}// end switch case by quote mode
		let layout: Layout = Layout(main: mainSource, sub: subSource)
		let quotation: Quatation = Quatation(layout: layout, contents: [content])

		let encoder: JSONEncoder = JSONEncoder()
		var quotationJSON: Data
		do {
			quotationJSON = try encoder.encode(quotation)
		} catch let error {
			print(error.localizedDescription)
			return false
		}// end do try - catch encode layout struct to json
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var request: URLRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		request.httpBody = quotationJSON
		request.method = .post
		var success: Bool = false
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, req:  URLResponse?, err:  Error?) in
			guard let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard is not satisfied
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let result: QuoteResult = try decoder.decode(QuoteResult.self, from: data)
				if result.meta.status == NoError { success = true }
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode reesult data to meta information
		}// end closure completion handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut { success = false }

		return success
	}// end startQuatation

		// MARK: end time extension
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
	internal func makeRequest (url requestURL: URL, method requestMethod: HTTPMethod, contentsType type: String? = nil) -> URLRequest {
		var request: URLRequest = URLRequest(url: requestURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(UserAgent, forHTTPHeaderField: UserAgentKey)
		if let contentsType: String = type {
			request.addValue(contentsType, forHTTPHeaderField: ContentTypeKey)
		}// end optional binding check for contents type
		request.method = requestMethod
		
		return request
	}// end makeRequest
	
		// MARK: - Private methods
	private func checkMetaInformation (_ meta: MetaInformation) -> ResultStatus {
		var status: ResultStatus
		var errorCode: String? = nil
		if let code: String = meta.errorCode { errorCode = code }
		var errorMessage: String? = nil
		if let message: String = meta.errorMessage { errorMessage = message }
		let statusCode: Int = meta.status / 100
		switch statusCode {
		case 2:
			status = .success
		case 4:
			status = .clientError(meta.status, errorCode, errorMessage)
		case 5:
			status = .serverError(meta.status, errorCode, errorMessage)
		default:
			status = .unknownError
		}// end switch case by first digit of status code

		return status
	}// end checkMetaInformation

	private func makeLayers (mode mixingMode: MixingMode, mainVolume main: Float, quoteVolume quote: Float) -> (main: Source, sub: Source) {
		var mainSource: Source
		var subSource: Source
		let mainVolume: Float = capableVolumeRange.contains(main) ? main : DefaultVolume
		let quoteVolume: Float = capableVolumeRange.contains(quote) ? quote : DefaultVolume
		switch mixingMode {
		case .main:
			mainSource = Source(source: .quote, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .`self`, volume: quoteVolume, isSoundOnly: true)
		case .sub:
			mainSource = Source(source: .`self`, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .quote, volume: quoteVolume, isSoundOnly: false)
		case .soundOnly:
			mainSource = Source(source: .`self`, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .quote, volume: quoteVolume, isSoundOnly: true)
		case .swap:
			mainSource = Source(source: .quote, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .`self`, volume: quoteVolume, isSoundOnly: false)
		}// end switch case by quote mode

		return (mainSource, subSource)
	}// end makeLayers

		// MARK: - Delegates
}// end class OwnerAndVIPCommentHandler
