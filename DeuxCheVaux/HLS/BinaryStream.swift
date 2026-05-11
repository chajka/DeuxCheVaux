//
//  BinaryStream.swift
//  Charleston
//
//  Created by Чайка on 2024/09/14.
//  Copyright © 2024 Чайка. All rights reserved.
//

import Cocoa

final class BinaryStream {
		// MARK: Static properties
		// MARK: - Class Method
		// MARK: - Outlets
		// MARK: - Properties
		// MARK: - Member variables
	private var buffer: [UInt8]

		// MARK: - Constructor/Destructor
	init (data: Data) {
		self.buffer = Array(data)
	}

		// MARK: - Override
		// MARK: - Actions
		// MARK: - Public methods
	func addBuffer (data: Data) {
		buffer.append(contentsOf: data)
	}// end func addBuffer

	func read () -> AnyIterator<[UInt8]> {
		var offset = 0

		return AnyIterator {
			while true {
				let frameOffset = offset

				guard let length = self.decodeVariant(offset: &offset) else {
					offset = frameOffset
					break
				}// end guard

				let end = offset + length
				guard end <= self.buffer.count else {
					offset = frameOffset
					break
				}// end guard

				let binaryData = Array(self.buffer[offset..<end])
				offset = end
				return binaryData
			}// end while

			if offset > 0 {
				self.buffer.removeFirst(offset)
			}// end if offset > 0

			return nil
		}// end while
	}// end func read

		// MARK: - Private methods
	private func decodeVariant (offset: inout Int) -> Int? {
		var value = 0
		var shift = 0

		while offset < buffer.count {
			let byte = buffer[offset]
			offset += 1
			value |= Int(byte & 0x7f) << shift

			if (byte & 0x80) == 0 {
				return value
			}// end if

			shift += 7
		}// end while

		return nil
	}// end func decodeVariant

	func tryClearBuffer () {
		if buffer.count == offset {
			self.buffer = []
			self.offset = 0
		}
	}
}
		// MARK: - Delegates
}// end class BinaryStream
