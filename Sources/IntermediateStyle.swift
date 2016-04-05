// A version of the style without children or fancy initialization
public struct IntermediateStyle {
  public typealias PropertyUpdate = (IntermediateProperty -> (String, String)?)

  public let selector: SelectorStatement
  public let properties: [IntermediateProperty]
  public let queries: [MediaQueryStatement]

  public init(selector: SelectorStatement, properties: [Property], queries: [MediaQueryStatement] = []) {
    self.selector = selector
    self.properties = properties.map {IntermediateProperty(original: $0)}
    self.queries = queries
  }

  public init(selector: SelectorStatement, properties: [IntermediateProperty], queries: [MediaQueryStatement] = []) {
    self.selector = selector
    self.properties = properties
    self.queries = queries
  }

  public func prefixSelector(selector: SelectorStatementConvertible) -> IntermediateStyle {
    return IntermediateStyle(selector: selector.selectorStatement.concat(self.selector), properties: self.properties, queries: self.queries)
  }

  public func suffixSelector(selector: SelectorStatementConvertible) -> IntermediateStyle {
    return IntermediateStyle(selector: self.selector.concat(selector.selectorStatement), properties: self.properties, queries: self.queries)
  }

  public func replaceSelector(selector: SelectorStatementConvertible) -> IntermediateStyle {
    return IntermediateStyle(selector: selector.selectorStatement, properties: self.properties)
  }

  public func removeProperty(property: Property.Type) -> IntermediateStyle {
    let updates = self.properties.filter {$0.original.dynamicType != property}
    return IntermediateStyle(selector: self.selector, properties: updates, queries: self.queries)
  }

  public func replaceProperty(property: Property.Type, with replacement: Property) -> IntermediateStyle {
    let updates: [IntermediateProperty] = self.properties.map { prop in
      if prop.original.dynamicType == property {
        return IntermediateProperty(original: replacement)
      }
      else {
        return prop
      }
    }
    return IntermediateStyle(selector: self.selector, properties: updates, queries: self.queries)
  }

  public func addValueForProperty(property: Property.Type, _ f: PropertyUpdate) -> IntermediateStyle {
    let updates: [IntermediateProperty] = self.properties.map { prop in
      if prop.original.dynamicType == property {
        if let update = f(prop) {
          return prop.add(update)
        }
        else {
          return prop
        }
      }
      else {
        return prop
      }
    }

    return IntermediateStyle(selector: self.selector, properties: updates, queries: self.queries)
  }
}
