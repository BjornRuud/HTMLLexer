extension BidirectionalCollection {
    func dropLast(while predicate: (Element) -> Bool) -> SubSequence {
        guard endIndex > startIndex else { return self[...] }
        var index = self.index(before: endIndex)
        while index >= startIndex, predicate(self[index]) {
            index = self.index(before: index)
        }
        return self[...index]
    }
}
