import Foundation

struct CharacterReader<Input>
where Input: Collection, Input.Element == Character {
    let input: Input

    var isAtEnd: Bool {
        return readIndex == input.endIndex
    }

    private(set) var readIndex: Input.Index

    init(input: Input) {
        self.input = input
        self.readIndex = input.startIndex
    }

    mutating func consume() -> Character? {
        guard readIndex < input.endIndex
        else { return nil }
        let character = input[readIndex]
        input.formIndex(after: &readIndex)
        return character
    }

    mutating func consume(upTo character: Character) -> Input.SubSequence {
        return consume(while: { $0 != character })
    }

    mutating func consume(while predicate: (Character) -> Bool) -> Input.SubSequence {
        let startIndex = readIndex
        skip(while: predicate)
        return input[startIndex..<readIndex]
    }

    func peek() -> Character? {
        guard readIndex < input.endIndex
        else { return nil }
        return input[readIndex]
    }

    mutating func setReadIndex(_ index: Input.Index) {
        if index < input.startIndex {
            readIndex = input.startIndex
        } else if index > input.endIndex {
            readIndex = input.endIndex
        }
        readIndex = index
    }

    mutating func skip(_ count: Int) {
        for _ in 0..<count {
            guard readIndex < input.endIndex
            else { break }
            input.formIndex(after: &readIndex)
        }
    }

    mutating func skip(while predicate: (Character) -> Bool) {
        while let character = peek(), predicate(character) {
            input.formIndex(after: &readIndex)
        }
    }
}
