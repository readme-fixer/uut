public protocol SimpleProperty {
  var label: String { get }
  var value: String { get }
  var stringValue: String { get }
}

extension SimpleProperty {
  public var stringValue: String {
    return "\(self.label): \(self.value);"
  }
}