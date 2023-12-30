extension Result {
	static func unsafe(_ closure: () throws -> Success) -> Self {
		do {
			return .success(try closure())
		} catch {
			return .failure(error as! Failure)
		}
	}
}
