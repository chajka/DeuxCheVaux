//
//  OwnerCommentHandler.swift
//  DeuxCheVaux
//
//  Created by Чайка on 2018/06/25.
//  Copyright © 2018 Чайка. All rights reserved.
//

import Cocoa

	// MARK: public type definitions
public typealias OwnerOperationHandler = (ResultStatus) -> Void

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

private enum StatusValue: Int {
	case noError = 2
	case clientError = 4
	case serverError = 5
}// end enum StatusValue

internal struct MetaInformation: Codable {
	let status: Int
	let errorCode: String?
	let errorMessage: String?
}// end struct MetaInformation

internal struct MetaResult: Codable {
	let meta: MetaInformation
}// end struct MetaResult

internal struct ProgramState: Codable {
	var state: NextProgramStatus
}// end struct ProgramState

	// MARK: owner specific NG settings
public enum NGType: String, Codable {
	case word = "word"
	case user = "user"
	case command = "command"
}// end enum NGType

public struct NGRequest: Codable {
	let type: NGType
	let body: String
}// end struct NGRequest

public struct NGData: Codable {
	public let id: Int
	public let type: NGType
	public let body: String
}// end struct NGData

internal struct NGWrodList: Codable {
	let meta: MetaInformation
	let data: Array<NGData>
}// end struct NGWordList

internal struct NGWordIdentifiers: Codable {
	let id: Array<Int>
}// end struct

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

internal let UserAgentKey: String = "User-Agent"
internal let ContentTypeKey: String = "Content-type"
internal let ContentTypeJSON: String = "application/json"

private let ApiBase: String = "https://live2.nicovideo.jp/watch/"
private let UserNamaAPIBase: String = "https://live2.nicovideo.jp/unama/watch/"
private let UserNamaAPITool: String = "https://live2.nicovideo.jp/unama/tool/v2/programs"
private let QuateAPIBase: String = "https://lapi.spi.nicovideo.jp/v1/tools/live/contents/"
private let QuatableAPIBase: String = "https://lapi.spi.nicovideo.jp/v1/tools/live/quote/services/video/contents/"

private let StartStopStream: String = "/segment"
private let operatorComment: String = "/operator_comment"
private let programExtension: String = "/extension"
private let statistics: String = "/statistics"
private let contents: String = "/contents"
private let Questionary: String = "/enquete"
private let QuestionaryResult: String = "/enquete/result"
private let NGWordSetting: String = "/ssng"
private let QuoteSuffix: String = "/quotation"
private let QuoteLayout: String = "/quotation/layout"
private let QuoteContents: String = "/quotation/contents"

private let perm: String = "/perm "
private let clear: String = "/clear"

public final class OwnerCommandHandler: HTTPCommunicatable {
		// MARK: - Properties
		// MARK: - Member variables
	private let program: String
	private let apiBaseString: String
	private let videoPrefixSet: Set<String>
	private let capableVolumeRange: Range<Float> = Range(uncheckedBounds: (lower: 0.0, upper: 1.0))

		// MARK: - Constructor/Destructor
	public init (program: String, cookies: Array<HTTPCookie>) {
		self.program = program
		videoPrefixSet = Set(arrayLiteral: SmileVideoPrefix, NicoMoviewPrefix, SmileOfficialPrefix)
		apiBaseString = ApiBase + self.program
		super.init(cookies)
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
				defer { semaphore.signal() } // must increment semaphore when exit from closure
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
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

	public func postOwnerComment (comment: String, name: String?, color: Color.premium?, isPerm: Bool? = false, link: String? = nil, with handler: @escaping OwnerOperationHandler) -> Void {
		var status: ResultStatus = .unknownError
		guard !comment.isEmpty else { handler(status); return }
		if comment == clear {
			clearOwnerComment(with: handler)
		}// end if comment is clear command

		guard let url = URL(string: apiBaseString + operatorComment) else { handler(status); return }
		let commentToPost: OperatorComment = OperatorComment(text: comment, userName: name, color: color, isPermanent: isPerm, link: link)
		var request: URLRequest = makeRequest(url: url, method: .put, contentsType: ContentTypeJSON)
		do {
			let encoder: JSONEncoder = JSONEncoder()
			request.httpBody = try encoder.encode(commentToPost)
			let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
				defer { handler(status) } // must increment semaphore when exit from closure
				guard let data: Data = dat else { status = .recieveDetaNilError; return }// end guard
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let meta: MetaResult = try decoder.decode(MetaResult.self, from: data)
					status = self.checkMetaInformation(meta.meta)
				} catch let error {
					status = .decodeResultError
					print(error.localizedDescription)
				}// end do try - catch decode recieved data
			}// end closure of request completion handler
			task.resume()
		} catch let error {
			status = .encodeRequestError
			print(error.localizedDescription)
			handler(status)
		}// end try - catch JSONSerialization
	}// end postOwnerComment

	public func clearOwnerComment () -> ResultStatus {
		guard let url = URL(string: apiBaseString + operatorComment) else { return .apiAddressError }
		var status: ResultStatus = .unknownError
		let request: URLRequest = makeRequest(url: url, method: .delete)
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
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
		}// end closure of request completion handler
		task.resume()
		let timeout: DispatchTimeoutResult = semaphore.wait(timeout: DispatchTime.now() + Timeout)
		if timeout == .timedOut {
			status = .timeout
		}// end if timeout

		return status
	}// end clearOwnerComment

	public func clearOwnerComment (with handler: @escaping OwnerOperationHandler) -> Void {
		guard let url = URL(string: apiBaseString + operatorComment) else { handler(.apiAddressError); return }
		var status: ResultStatus = .unknownError
		let request: URLRequest = makeRequest(url: url, method: .delete)
		let task: URLSessionDataTask = session.dataTask(with: request) { (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { handler(status) }
			guard let data: Data = dat else { status = .recieveDetaNilError; return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let meta: MetaResult = try decoder.decode(MetaResult.self, from: data)
				status = self.checkMetaInformation(meta.meta)
			} catch let error {
				status = .decodeResultError
				print(error.localizedDescription)
			}// end do try - catch decode recieved data
		}// end clrear request completion handler
		task.resume()
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
				defer { semaphore.signal() } // must increment semaphore when exit from closure
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
					return
				}// end guard
				do {
					let decoder: JSONDecoder = JSONDecoder()
					let result: EnqueteResult = try decoder.decode(EnqueteResult.self, from: data)
					status = weakSelf.checkMetaInformation(result.meta)
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
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else {
				return
			}// end guard
			do {
				let result: EnqueteResult = try decoder.decode(EnqueteResult.self, from: data)
				status = weakSelf.checkMetaInformation(result.meta)
				answers = result.data?.items
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode result
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
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
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

		// MARK: NG Word Handling
	public func addNGWord (_ word: String, type: NGType) -> Bool {
		guard let baseURL = URL(string: UserNamaAPITool) else { return false }
		let url = baseURL.appendingPathComponent(program, isDirectory: false).appendingPathComponent(NGWordSetting)
		let encoder: JSONEncoder = JSONEncoder()
		let wordToAppend: NGRequest = NGRequest(type: type, body: word)
		let wordList: Array<NGRequest> = Array(arrayLiteral: wordToAppend)
		guard let wordToAppendJson: Data = try? encoder.encode(wordList) else { return false }
		var success: Bool = false

		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var request: URLRequest = makeRequest(url: url, method: .post)
		request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		request.httpBody = wordToAppendJson
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else { return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let result: MetaResult = try decoder.decode(MetaResult.self, from: data)
				if .success == weakSelf.checkMetaInformation(result.meta) {
					success = true
				}// end if check meta information
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode result JSON structure
		}// end closure for request set NG Word owner command
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.now() + Timeout)	// no need action from timeout or success

		return success
	}// end addNGWord

	public func addNGWords (words: Array<(word: String, type: NGType)>) -> Bool {
		guard let baseURL = URL(string: UserNamaAPITool) else { return false }
		let url = baseURL.appendingPathComponent(program, isDirectory: false).appendingPathComponent(NGWordSetting)
		let encoder: JSONEncoder = JSONEncoder()
		var wordsList: Array<NGRequest> = Array()
		for word: (word: String, type: NGType) in words {
			let enry: NGRequest = NGRequest(type: word.type, body: word.word)
			wordsList.append(enry)
		}// end foreach make Array of NGRequest
		guard let wordsToAppenJson: Data = try? encoder.encode(wordsList) else { return false }
		var success: Bool = false

		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var request: URLRequest = makeRequest(url: url, method: .post)
		request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		request.httpBody = wordsToAppenJson
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, req: URLResponse?, err: Error?) in
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else { return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let result: MetaResult = try decoder.decode(MetaResult.self, from: data)
				if .success == weakSelf.checkMetaInformation(result.meta) {
					success = true
				}// end if check meta information result
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode result JSON strult
		}// end closure for request set NG Words owner command
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.now() + Timeout)

		return success
	}// end addNGWords

	public func allNGWords () -> Array<NGData> {
		guard let baseURL = URL(string: UserNamaAPITool) else { return Array() }
		let url = baseURL.appendingPathComponent(program, isDirectory: false).appendingPathComponent(NGWordSetting)
		var wordsList: Array<NGData> = Array()

		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let request: URLRequest = makeRequest(url: url, method: .get)
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else { return }
			do {
				let decoder: JSONDecoder = JSONDecoder()
				let list: NGWrodList = try decoder.decode(NGWrodList.self, from: data)
				guard .success == weakSelf.checkMetaInformation(list.meta) else { return }
				for foundWord: NGData in list.data {
					wordsList.append(foundWord)
				}// end foreach found word
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch
		}// end closure
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.now() + Timeout)

		return wordsList
	}// end allNGWords

	public func removeNGWords (identifiers: Array<Int>) -> Bool {
		guard identifiers.count > 0, let baseURL = URL(string: UserNamaAPITool) else { return false }
		let url = baseURL.appendingPathComponent(program, isDirectory: false).appendingPathComponent(NGWordSetting)
		let encoder: JSONEncoder = JSONEncoder()
		let removeNGWords: NGWordIdentifiers = NGWordIdentifiers(id: identifiers)
		guard let identifiersForRemove: Data = try? encoder.encode(removeNGWords) else { return false }
		var success = false

		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		var request: URLRequest = makeRequest(url: url, method: .delete)
		request.addValue(ContentTypeJSON, forHTTPHeaderField: ContentTypeKey)
		request.httpBody = identifiersForRemove
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else { return }
			do {
				let decoder = JSONDecoder()
				let result: MetaResult = try decoder.decode(MetaResult.self, from: data)
				if .success == weakSelf.checkMetaInformation(result.meta) {
					success = true
				}// end if result status is success
			} catch let error {
				print(error.localizedDescription)
			}// end do try - catch decode result JSON structure
		}// end closure for request remove NG words by array of identifiers
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.now() + Timeout)

		return success
	}// end removeNGWords

		// MARK: quote
	public func checkQuotable (_ video: String) -> (quotable: Bool, status: ResultStatus) {
		guard let url: URL = URL(string: QuatableAPIBase + video) else { return (false, .apiAddressError) }

		let request: URLRequest = makeRequest(url: url, method: .get)
		var status: ResultStatus = .unknownError
		var quotable: Bool = false
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (dat: Data?, resp: URLResponse?, err: Error?) in
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
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
				defer { semaphore.signal() } // must increment semaphore when exit from closure
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
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
				defer { semaphore.signal() } // must increment semaphore when exit from closure
				guard let weakSelf = self, let data: Data = dat else {
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
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
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
			defer { semaphore.signal() } // must increment semaphore when exit from closure
			guard let weakSelf = self, let data: Data = dat else {
				status = .recieveDetaNilError
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
				defer { semaphore.signal() } // must increment semaphore when exit from closure
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
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
				defer { semaphore.signal() } // must increment semaphore when exit from closure
				guard let weakSelf = self, let data: Data = dat else {
					status = .recieveDetaNilError
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
	private func checkMetaInformation (_ meta: MetaInformation) -> ResultStatus {
		let Base: Int = 10

		var status: ResultStatus
		var errorCode: String? = nil
		if let code: String = meta.errorCode { errorCode = code }
		var errorMessage: String? = nil
		if let message: String = meta.errorMessage { errorMessage = message }
		let statusCode: StatusValue? = StatusValue(rawValue: meta.status / (Base * Base))	// drop last 2 digit

		switch statusCode {
			case .noError:
				status = .success
			case .clientError:
				status = .clientError(meta.status, errorCode, errorMessage)
			case .serverError:
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
