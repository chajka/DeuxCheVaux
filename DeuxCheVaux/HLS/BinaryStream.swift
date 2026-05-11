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
			while let result = self.decodeVarint(offset: &offset) {
				let value = result.value
				let newOffset = result.offset
				let start = newOffset + 1
				let end = start + value

				if self.buffer.count < end {
					break
				}

				offset = end
				let binaryData = Array(self.buffer[start..<end])
				return binaryData
			}

			if offset > 0 {
				self.buffer = Array(self.buffer.dropFirst(offset))
			}

			return nil
		}
	}

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
