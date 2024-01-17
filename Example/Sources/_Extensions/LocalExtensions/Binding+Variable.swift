import SwiftUI

extension Binding {
	public static func variable(_ initialValue: Value) -> Binding {
		var value = initialValue
		return Binding(
			get: { value },
			set: { value = $0 }
		)
	}
}
