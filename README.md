# HTMLLexer

A lexer (or tokenizer) to parse a string containing HTML elements into tokens representing the order of the various elements. It is written in Swift and depends on [swift-parsing](https://github.com/pointfreeco/swift-parsing).

Note that this is _not_ a full HTML parser and it performs no validation. This means it will not check if the HTML structure is valid, but it _will_ check if the syntax of the parsed HTML elements is valid according to the [HTML syntax specification](https://html.spec.whatwg.org/multipage/syntax.html). Elements that are invalid or could not be parsed are output as text.

The typical use-case for this library is strings using HTML for formatting where full control of the processing and rendering is required.

Example: The string `"A <b>bold</b> move"` will output
```
[
  .text("A "),
  .tagStart(name: "b", attributes: [], isSelfClosing: false),
  .text("bold"),
  .tagEnd(name: "b"),
  .text(" move")
]
```
