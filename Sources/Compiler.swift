import Foundation

public struct Compiler {
  public typealias InitialFunc = ([Style] -> [Style])
  public typealias IntermediateFunc = (IntermediateCollection -> IntermediateCollection)
  public typealias PostFunc = (String -> String)

  let initial: [InitialFunc]
  let intermediate: [IntermediateFunc]
  let post: [PostFunc]

  public init(initial: [InitialFunc] = [], intermediate: [IntermediateFunc] = [], post: [PostFunc] = []) {
    self.initial = initial
    self.intermediate = intermediate
    self.post = post
  }

  func compile(style: Style) -> String {
    return compile([style])
  }

  public func compile(package: StylePackage) -> String {
    return compile(package.styles)
  }

  public func compile(styles: [Style]) -> String {
    let initialStyles = self.initial.reduce(styles) {$1($0)}
    let extensionStyles = self.extractExtensions(initialStyles)

    let simpleStyles = IntermediateCollection(flatten(initialStyles + extensionStyles))
    let intermediateSyles = self.intermediate.reduce(simpleStyles) {$1($0)}

    let buffer: [String] = intermediateSyles.styles.reduce([]) {memo, style in
      let props: [String] = style.properties.reduce([]) {memo, prop in
        let pairs = prop.allValues.map { (label, value) in
          return "  \(label): \(value);"
        }
        return memo + pairs
      }
      return memo + ["\(style.selector.stringValue) {"] + props + ["}"]
    }

    let output = buffer.joinWithSeparator("\r\n")
    let postStyles = self.post.reduce(output) {$1($0)}

    return postStyles
  }

  private func extractExtensions(styles: [Style]) -> [Style] {
    let extensions = styles.flatMap { style in
      return style.extensions.map {($0, style)}
    }

    let grouped: [StyleExtension: [Style]] = extensions.reduce([:]) { memo, pair in
      let entry = memo[pair.0]
      let update = (entry ?? []) + [pair.1]
      return memo.merge([pair.0: update])
    }

    return grouped.map {ext, styles in
      let selector = styles.reduce(SelectorStatement([])) { memo, style in
        if memo.selectors.isEmpty {
          return style.selector
        }
        else {
          return memo |& style.selector
        }
      }

      return Style(
        selector,
        properties: ext.properties,
        children: ext.children
      )
    }
  }

  private func flatten(styles: [Style], output: [IntermediateStyle] = []) -> [IntermediateStyle] {
    return styles.reduce(output) {memo, style in
      let props = style.mixins.flatMap {$0.properties} + style.properties
      let simple = IntermediateStyle(selector: style.selector, properties: props)
      let children = (style.mixins.flatMap {$0.children} + style.children).map {$0.prependSelector(style.selector)}
      return [simple] + flatten(children, output: memo)
    }
  }
}

extension Dictionary {
  func merge(dictionary: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
    var output = self
    for (key, value) in dictionary {
      output[key] = value
    }

    return output
  }
}
