//
//  BinaryStream.swift
//  Charleston
//
//  Created by Чайка on 2024/09/14.
//  Copyright © 2024 Чайка. All rights reserved.
//

import Cocoa

final class BinaryStream {
	private var buffer: [UInt8]
	private var offset: Int

	init (data: Data) {
		self.buffer = data.map { $0 }
		self.offset = 0
	}

	private func decodeVarint (offset: inout Int) -> (value: Int, offset: Int)? {
		var value = 0
		var shift = 0
		let length = buffer.count - 1
		var more = false

		repeat {
			if length < offset {
				return nil
			}
			let byte = buffer[offset]
			more = (byte & 128) != 0
			value |= Int(byte & 127) << shift
			if more {
				offset += 1
				shift += 7
			}
		} while more

		return (value: value, offset: offset)
	}

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

	func addBuffer (data: Data) {
		let newBuffer = data.map { $0 }
		self.buffer.append(contentsOf: newBuffer)
	}

	func tryClearBuffer () {
		if buffer.count == offset {
			self.buffer = []
			self.offset = 0
		}
	}
}
