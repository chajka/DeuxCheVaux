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
	case quotePermissionError
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
public enum MixingMode: Int {
	case main = 1
	case sub = 2
	case soundOnly = 3
	case swap = 4
	case swapSoundOnly = 5
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

internal struct MetaResult: Codable {
	let meta: MetaInformation
}// end struct QuoteResult

internal struct MovieInfo: Codable {
	let id: String
	let length: Int
	let title: String
	let userId: String
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
public enum StreamControl {
	enum key: String {
		case state = "state"
	}// end enum Key
	public enum value: String, Codable {
		case start = "on_air"
		case end = "end"
	}// end enum value
}// end enum StreamControl

public enum NextProgramStatus: String, Codable {
	case onAir = "on_air"
	case ended = "end"
}// end enum ProgramStatus

enum CommentKeys: String {
	case comment = "text"
	case name = "userName"
	case color = "color"
	case perm = "isPermanent"
	case link = "link"
}// end enum CommentKeys

extension StreamControl.key: StringEnum { }
extension StreamControl.value: StringEnum { }
extension CommentKeys: StringEnum { }

fileprivate let Timeout: Double = 2.0
fileprivate let DefaultVolume: Float = 0.5
fileprivate let Success: String = "OK"
internal let SmileVideoPrefix: String = "sm"
internal let NicoMoviewPrefix: String = "nm"
internal let SmileOfficialPrefix: String = "so"
internal let NicoNicoLivePrefix: String = "lv"

public enum Color {
	public enum normal: String, Codable {
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
	public enum premium: String, Codable {
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

internal struct OperatorComment: Codable {
	let text: String
	let userName: String?
	let color: Color.premium?
	let isPermanent: Bool?
	let link: String?
}// end struct OperatorComment

public enum CommentPostError: Error {
	case EmptyComment
	case NameUndefined
	case InvalidColor(String)
}// end public enum CommentPostError

private let UserAgentKey: String = "User-Agent"
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
private let QuoteSuffix: String = "/quotation"
private let QuoteLayout: String = "/quotation/layout"
private let QuoteContents: String = "/quotation/contents"

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
	public func postOwnerComment (comment: String, name: String?, color: Color.premium?, isPerm: Bool? = false, link: String? = nil) -> ResultStatus {
		if comment.isEmpty { return .argumentError }
		if (comment.starts(with: clear)) {
			return clearOwnerComment()
		}// end if comment is clear command
		guard let url = URL(string: apiBaseString + operatorComment) else { return .argumentError }
		let commentToPost: OperatorComment = OperatorComment(text: comment, userName: name, color: color, isPermanent: isPerm, link: link)

		var status: ResultStatus = .unknownError
		var request: URLRequest = makeRequest(url: url, method: .put, contentsType: ContentTypeJSON)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		do {
			let encoder: JSONEncoder = JSONEncoder()
			request.httpBody = try encoder.encode(commentToPost)
			let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
					semaphore.signal()
					return
				}// end guard
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let meta: MetaResult = try decoder.decode(MetaResult.self, from: data)
					status = weakSelf.checkMetaInformation(meta.meta)
				} catch let error {
					status = .decodeResultError
					print(error.localizedDescription)
				}// end do try - catch decode recieved data
				semaphore.signal()
			}// end closure of request completion handler
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			if timeout == .timedOut {
				status = .timeout
			}// end if timeout
		} catch let error {
			status = .encodeRequestError
			print(error.localizedDescription)
		}// end try - catch JSONSerialization

		return status
	}// end func owner comment

	public func clearOwnerComment () -> ResultStatus {
		guard let url = URL(string: apiBaseString + operatorComment) else { return .apiAddressError }
		var status: ResultStatus = .unknownError
		let request: URLRequest = makeRequest(url: url, method: .delete)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
				semaphore.signal()
				return
			}// end guard
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let meta: MetaResult = try decoder.decode(MetaResult.self, from: data)
				status = weakSelf.checkMetaInformation(meta.meta)
			} catch let error {
				status = .decodeResultError
				print(error.localizedDescription)
			}// end do try - catch decode recieved data
			semaphore.signal()
		}// end closure of request completion handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut {
			status = .timeout
		}// end if timeout

		return status
	}// end clearOwnerComment

		// MARK: questionary
	public func questionary (title question: String, choices items: Array<String>) -> ResultStatus {
		let capableItemSount: Set<Int> = Set(2...9)
		let itemCount: Int = items.count
		if !capableItemSount.contains(itemCount) { return .argumentError }
		guard let url: URL = URL(string: UserNamaAPIBase + program + Questionary) else { return .apiAddressError }

		var status: ResultStatus = .unknownError
		var request: URLRequest = makeRequest(url: url, method: .post, contentsType: ContentTypeJSON)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let enquetee: Enquete = Enquete(question: question, items: items)
		do {
			let encoder: JSONEncoder = JSONEncoder()
			let data: Data = try encoder.encode(enquetee)
			request.httpBody = data
			let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, req: URLResponse?, err: Error?) in
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
					semaphore.signal()
					return
				}// end guard
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let result: EnqueteResult = try decoder.decode(EnqueteResult.self, from: data)
					status = weakSelf.checkMetaInformation(result.meta)
					semaphore.signal()
				} catch let error {
					status = .decodeResultError
					print(error.localizedDescription)
				}// end do try - catch decode result data
			}// end closure
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			if timeout == .timedOut {
				status = .timeout
			}// end if timeout
		} catch let error {
			status = .encodeRequestError
			print(error.localizedDescription)
		}// end do try - catch encode Enquete struct to JSON string data

		return status
	}// end questionary

	public func displayQuestionaryResult () -> (answers: Array<EnqueteItem>?, status: ResultStatus) {
		guard let url: URL = URL(string: UserNamaAPIBase + program + QuestionaryResult) else { return (nil, .apiAddressError) }

		var status: ResultStatus = .unknownError
		let request: URLRequest = makeRequest(url: url, method: .post)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let decoder: JSONDecoder = JSONDecoder()
		var answers: Array<EnqueteItem>?
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, req: URLResponse?, err: Error?) in
			guard let weakSelf = self, let data: Data = dat else {
				semaphore.signal()
				return
			}// end guard
			do {
				let result: EnqueteResult = try decoder.decode(EnqueteResult.self, from: data)
				status = weakSelf.checkMetaInformation(result.meta)
				answers = result.data?.items
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode result
			semaphore.signal()
		}// end closurre
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut {
			status = .timeout
		}// end if timeout

		return (answers, status)
	}// end displayQuestionaryResult

	public func endQuestionary () -> ResultStatus {
		guard let url: URL = URL(string: UserNamaAPIBase + program + Questionary) else { return .apiAddressError }

		let request: URLRequest = makeRequest(url: url, method: .delete)
		var status: ResultStatus = .unknownError
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let decoder: JSONDecoder = JSONDecoder()
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, req: URLResponse?, err: Error?) in
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
				semaphore.signal()
				return
			}// end guard
			do {
				let result: EnqueteResult = try decoder.decode(EnqueteResult.self, from: data)
				status = weakSelf.checkMetaInformation(result.meta)
			} catch let error {
				status = .decodeResultError
				print(error.localizedDescription)
			}// end do try - catch decode result
		}// end closurre
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut {
			status = .timeout
		}// end if timeout

		return status
	}// end endQuestionary

		// MARK: quote
	public func checkQuotable (_ video: String) -> (quotable: Bool, status: ResultStatus) {
		guard let url: URL = URL(string: QuatableAPIBase + video) else { return (false, .apiAddressError) }

		let request: URLRequest = makeRequest(url: url, method: .get)
		var status: ResultStatus = .unknownError
		var quotable: Bool = false
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
				semaphore.signal()
				return
			}// end guard check data is not nil
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let result: QuatableResult = try decoder.decode(QuatableResult.self, from: data)
				status = weakSelf.checkMetaInformation(result.meta)
				if let info: MovieInfo = result.data {
					quotable = info.quotable
				}// end optional binding check for have data section from decoded json structure
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode recieved json
			semaphore.signal()
		}// end closure for url request result data handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut {
			quotable = false
			status = .timeout
		}// end if timeout

		return (quotable, status)
	}// end checkQuotable

	public func startQuotation (quote quoteContent: String, mode mixingMode: MixingMode, mainVolume main: Float, quoteVolume quote: Float) -> ResultStatus {
		var type: ConteentType? = nil
		let quoteContentPrefix: String = String(quoteContent.prefix(2))
		if videoPrefixSet.contains(quoteContentPrefix) { type = .video }
		else if quoteContentPrefix == NicoNicoLivePrefix { type = .live }
		guard let url: URL = URL(string: QuateAPIBase + program + QuoteSuffix), let contentType: ConteentType = type else { return .apiAddressError }

		var mainSource: Source
		var subSource: Source
		(mainSource, subSource) = makeLayers(mode: mixingMode, mainVolume: main, quoteVolume: quote)
		let content: Content = Content(id: quoteContent, type: contentType)
		let layout: Layout = Layout(main: mainSource, sub: subSource)
		let quotation: Quotation = Quotation(layout: layout, contents: [content])

		var status: ResultStatus = .unknownError
		do {
			let encoder: JSONEncoder = JSONEncoder()
			var quotationJSON: Data
			quotationJSON = try encoder.encode(quotation)
			var request: URLRequest = makeRequest(url: url, method: .post, contentsType: ContentTypeJSON)
			request.httpBody = quotationJSON
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, req:  URLResponse?, err:  Error?) in
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
					semaphore.signal()
					return
				}// end guard is not satisfied
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let result: MetaResult = try decoder.decode(MetaResult.self, from: data)
					status = weakSelf.checkMetaInformation(result.meta)
				} catch let error {
					status = .decodeResultError
					print(error.localizedDescription)
				}// end do try - catch decode reesult data to meta information
				semaphore.signal()
			}// end closure completion handler
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			if timeout == .timedOut {
				status = .timeout
			}// end if timeout
		} catch let error {
			print(error.localizedDescription)
			return .encodeRequestError
		}// end do try - catch encode layout struct to json

		return status
	}// end startQuotation

	public func layoutQuotation (mode mixingMode: MixingMode, mainVolume main: Float, quoteVolume quote: Float, repeat enableRepeat: Bool) -> ResultStatus {
		guard let url: URL = URL(string: QuateAPIBase + program + QuoteLayout) else { return .apiAddressError }

		var mainSource: Source
		var subSource: Source
		(mainSource, subSource) = makeLayers(mode: mixingMode, mainVolume: main, quoteVolume: quote)
		let layout: Layout = Layout(main: mainSource, sub: subSource)
		let newLayout: UpdatteQuotation = UpdatteQuotation(layout: layout, repeat: enableRepeat)
		var status: ResultStatus = .unknownError
		var layoutJSON: Data
		do {
			let encoder: JSONEncoder = JSONEncoder()
			layoutJSON = try encoder.encode(newLayout)
			var request: URLRequest = makeRequest(url: url, method: .patch, contentsType: ContentTypeJSON)
			request.httpBody = layoutJSON
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, req:  URLResponse?, err:  Error?) in
				guard let weakSelf = self, let data: Data = dat else {
					semaphore.signal()
					return
				}// end guard is not satisfied
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let result: MetaResult = try decoder.decode(MetaResult.self, from: data)
					status = weakSelf.checkMetaInformation(result.meta)
				} catch let error {
					status = .decodeResultError
					print(error.localizedDescription)
				}// end do try - catch decode reesult data to meta information
				semaphore.signal()
			}// end closure completion handler
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			if timeout == .timedOut {
				status = .timeout
			}// end if timeout
		} catch let error {
			status = .encodeRequestError
			print(error.localizedDescription)
		}// end do try - catch encode layout change request to json

		return status
	}// end layoutQuotation

	public func stopQuotation () -> ResultStatus {
		guard let url: URL = URL(string: QuateAPIBase + program + QuoteSuffix) else { return .apiAddressError }

		let request: URLRequest = makeRequest(url: url, method: .delete)
		var status: ResultStatus = .unknownError
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, req:  URLResponse?, err:  Error?) in
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
				semaphore.signal()
				return
			}// end guard is not satisfied
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let meta: MetaResult = try decoder.decode(MetaResult.self, from: data)
				status = weakSelf.checkMetaInformation(meta.meta)
			} catch let error {
				status = .decodeResultError
				print(error.localizedDescription)
			}// end do try - catch decode reesult data to meta information
			semaphore.signal()
		}// end closure completion handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut {
			status = .timeout
		}// end if timeout

		return status
	}// end stopQuotation

		// MARK: end time extension
	public func extendableTimes () -> (times: Array<String>, status: ResultStatus) {
		guard let url: URL = URL(string: apiBaseString + programExtension) else { return (Array(), .apiAddressError) }
		var status: ResultStatus = .unknownError
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var extendableMinutes: Array<String> = Array()
		let request: URLRequest = makeRequest(url: url, method: .get)
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, rest: URLResponse?, err: Error?) in
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
				semaphore.signal()
				return
			}// end guard
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let extendableList: TimeExtension = try decoder.decode(TimeExtension.self, from: data)
				status = weakSelf.checkMetaInformation(extendableList.meta)
				if let methods: Array<ExtendMehtod> = extendableList.data?.methods {
					for method: ExtendMehtod in methods {
						extendableMinutes.append(String(method.minutes))
					}// end foreach methods
				}// end optional binding for
				semaphore.signal()
			} catch let error {
				status = .decodeResultError
				print(error.localizedDescription)
			}// end do try - catch decode recived json to struct
		}// end closure of request completion handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut {
			status = .timeout
		}// end if timeout

		return (extendableMinutes, status)
	}// end extendableTimes

	public func extendTime (minutes min: String) -> (newEndTime: Date?, status: ResultStatus) {
		guard let url: URL = URL(string: apiBaseString + programExtension), let minutesToExtend: Int = Int(min) else { return (nil, .apiAddressError) }
		let extend: ExtendTime = ExtendTime(minutes: minutesToExtend)
		var newEndTime: Date? = nil
		var status: ResultStatus = .unknownError
		do {
			let encoder: JSONEncoder = JSONEncoder()
			let extendTimeData: Data = try encoder.encode(extend)
			var request: URLRequest = makeRequest(url: url, method: .post, contentsType: ContentTypeJSON)
			request.httpBody = extendTimeData
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
					semaphore.signal()
					return
				}// end guard
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let extendResult: TimeExtendResult = try decoder.decode(TimeExtendResult.self, from: data)
					status = weakSelf.checkMetaInformation(extendResult.meta)
					if let newEnd: TimeInterval = extendResult.data?.end_time {
						newEndTime = Date(timeIntervalSince1970: newEnd)
					}// end optional binding check for
				} catch let error {
					print(error)
					status = .decodeResultError
				}// end do try - catch decode json data to result
				semaphore.signal()
			}// end closure of request completion handler
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			if timeout == .timedOut {
				status = .timeout
			}// end if timeout
		} catch let error {
			print(error)
			return (nil, .encodeRequestError)
		}// end do try - catch json encode

		return (newEndTime, status)
	}// end extendTime

	public func updateProgramState (newState state: NextProgramStatus) -> (startTime: Date, endTime: Date, status: ResultStatus) {
		let nextState = ProgramState(state: state)
		var startTime = Date()
		var endTime = startTime
		guard let url: URL = URL(string: apiBaseString + StartStopStream) else { return (startTime, endTime, .apiAddressError) }
		var status: ResultStatus = .unknownError
		do {
			let encoder: JSONEncoder = JSONEncoder()
			let extendTimeData: Data = try encoder.encode(nextState)
			var request: URLRequest = makeRequest(url: url, method: .put, contentsType: ContentTypeJSON)
			request.httpBody = extendTimeData
			let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
			let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
					semaphore.signal()
					return
				}// end guard
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let updateStatedResult: UpdateStateResult = try decoder.decode(UpdateStateResult.self, from: data)
					status = weakSelf.checkMetaInformation(updateStatedResult.meta)
					if let newStart: TimeInterval = updateStatedResult.data?.start_time, let newEnd: TimeInterval = updateStatedResult.data?.end_time {
						startTime = Date(timeIntervalSince1970: newStart)
						endTime = Date(timeIntervalSince1970: newEnd)
					}// end optional binding
				} catch let error {
					print(error)
					status = .decodeResultError
				}// end do try - catch decode json data to result
				semaphore.signal()
			}// end closure of request completion handler
			task.resume()
			let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
			if timeout == .timedOut {
				status = .timeout
			}// end if timeout
		} catch let error {
			print(error)
			status = .encodeRequestError
		}// end do try - catch json encode

		return (startTime, endTime, status)
	}// eend updateProgramState

		// MARK: - Internal methods
		// MARK: - Private methods
	private func makeRequest (url requestURL: URL, method requestMethod: HTTPMethod, contentsType type: String? = nil) -> URLRequest {
		let deuxCheVaux: DeuxCheVaux = DeuxCheVaux.shared
		let userAgent: String = deuxCheVaux.userAgent
		var request: URLRequest = URLRequest(url: requestURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Timeout)
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
		request.addValue(userAgent, forHTTPHeaderField: UserAgentKey)
		if let contentsType: String = type {
			request.addValue(contentsType, forHTTPHeaderField: ContentTypeKey)
		}// end optional binding check for contents type
		request.method = requestMethod

		return request
	}// end makeRequest

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
		case .swapSoundOnly:
			mainSource = Source(source: .quote, volume: mainVolume, isSoundOnly: nil)
			subSource = Source(source: .`self`, volume: quoteVolume, isSoundOnly: true)
		}// end switch case by quote mode

		return (mainSource, subSource)
	}// end makeLayers

		// MARK: - Delegates
}// end class OwnerAndVIPCommentHandler
