import Foundation
import CommonCrypto

extension Data {
	public static func sha256(
		_ string: String,
		encoding: String.Encoding = .utf8
	) -> Data? {
		return string.data(using: encoding).flatMap(Self.sha256)
	}

	public static func sha256(_ data: Data) -> Data {
		let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
		var hash = [UInt8](repeating: 0, count: digestLength)
		_ = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
			CC_SHA256(pointer.baseAddress, UInt32(data.count), &hash)
		}
		return Data(bytes: hash, count: digestLength)
	}
}

extension String {
	public static func sha256(
		_ string: String,
		encoding: String.Encoding = .utf8
	) -> String? {
		return Data.sha256(string, encoding: encoding).flatMap(Self.hexString)
	}

	public static func hexString(from data: Data) -> String {
		var bytes = [UInt8](repeating: 0, count: data.count)
		data.copyBytes(to: &bytes, count: data.count)

		var hexString = ""
		for byte in bytes {
			hexString += String(format:"%02x", UInt8(byte))
		}

		return hexString
	}
}
