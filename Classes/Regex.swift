/*
	The MIT License (MIT)

	Copyright (c) 2015 Stephen J. Butler <stephen.butler@gmail.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

import Foundation

/** Class wrapping around NSRegularExpression, but with a Swift flavor. Inspired by
    Dollar & Cent, with some conventions taken from Python.
*/
public class Regex {
    private struct Static {
        static let metaChatacterRegex = Regex("[\\-\\[\\]\\/\\{\\}\\(\\)\\*\\+\\?\\.\\\\\\^\\$\\|]")!
    }

    /** Escapes the regular expression metacharacters in a string.

        :param: str String to search for metacharacters and escape.

        :returns: String with the metachacaters escaped.
    */
    public class func escapeString(str: String) -> String {
        if let matches = Static.metaChatacterRegex.findAll(str) {
            var buffer: String = ""
            var pos: String.Index = str.startIndex

            for match in matches {
                let range = match.ranges[0]

                buffer += str[pos..<range.startIndex]
                buffer += "\\"
                buffer += str[range]

                pos = range.endIndex
            }

            buffer += str[pos..<str.endIndex]

            return buffer
        } else {
            return str
        }
    }

    let expression: NSRegularExpression!
    let pattern: String

    /** A match result returned by one of the matching functions. */
    public class Match {
        /** The string that was matched. */
        public let subject: String
        /** Ranges of the matches, with the entire pattern match in 0. */
        public let ranges: [Range<String.Index>]
        /** Count of the capture groups, including the entire pattern match. */
        public var count: Int { return ranges.count }

        init(subject: String, matchResult: NSTextCheckingResult) {
            self.subject = subject

            var ranges: [Range<String.Index>] = []

            // Check the overall match first. Shouldn't happen
            if matchResult.range.location == NSNotFound {
                fatalError("Match result included NSNotFound")
            }

            // Get the capture groups
            for matchRangeIdx in 0..<matchResult.numberOfRanges {
                let matchRange = matchResult.rangeAtIndex(matchRangeIdx)
                let beginIndex = advance(subject.startIndex, matchRange.location)
                let endIndex = advance(beginIndex, matchRange.length)

                ranges.append(beginIndex..<endIndex)
            }

            self.ranges = ranges
        }

        /** Get a subscript for a capture group, with 0 being the entire pattern match.

            :param: index Index of the capture group, with 0 being the entire pattern match.

            :returns: Subscript for the capture group.
        */
        public subscript(index: Int) -> String {
            return subject[ranges[index]]
        }
    }

    /** Initializes with an already compiled NSRegularExpression object.

        :param: expression Regular expression used in matches.
    */
    public init(_ expression: NSRegularExpression) {
        self.pattern = expression.pattern
        self.expression = expression
    }

    /** Initializes a pattern. This can fail if the pattern is invalid.

        :param: pattern Regular expression to compile, in the same form as NSRegularExpression.
        :param: options Options for how the expression is interpreted.
    */
    public init?(_ pattern: String, options: NSRegularExpressionOptions = .allZeros) {
        self.pattern = pattern

        if let expression = NSRegularExpression(pattern: pattern, options: options, error: nil) {
            self.expression = expression
        } else {
            return nil
        }
    }

    /** Finds all matches in a string and returns them as an array. If there are no matches
        found then nil is returned.

        :param: subject String to match against.

        :returns: Array of Match object on success, else nil.
    */
    public func findAll(subject: String) -> [Match]? {
        let results = expression.matchesInString(subject, options: nil, range:NSMakeRange(0, countElements(subject))) as [NSTextCheckingResult]

        if results.count == 0 || results[0].range.location == NSNotFound {
            return nil
        } else {
            return results.map { Match(subject: subject, matchResult: $0) }
        }
    }

    /** Matches a string against the pattern, anchoring it at the start. This will return nil if
        the match fails.

        :param: subject The string to match against.

        :returns: A Match object on success, else nil.
    */
    public func match(subject: String) -> Match? {
        if let result = expression.firstMatchInString(subject, options: .Anchored, range: NSMakeRange(0, countElements(subject))) {
            if result.range.location != NSNotFound {
                return Match(subject: subject, matchResult: result)
            }
        }

        return nil
    }

    /** Matches a string against the pattern, not performing any special anchoring. This will return
        nil if the match fails.

        :param: subject The string to match against.

        :returns: A Match object on success, else nil.
    */
    public func search(subject: String) -> Match? {
        if let result = expression.firstMatchInString(subject, options: .allZeros, range: NSMakeRange(0, countElements(subject))) {
            if result.range.location != NSNotFound {
                return Match(subject: subject, matchResult: result)
            }
        }

        return nil
    }

    /** Tries to match a string, anchoring it at the start.

        :param: subject The string to match against.

        :returns: True if the string matches, anchoring at the start, else false.
    */
    public func testMatch(subject: String) -> Bool {
        return match(subject) != nil
    }

    /** Tries to match a string, not performing any special anchoring.

        :param: subject The string to match against.

        :returns: True if the string matches anywhere, else false.
    */
    public func testSearch(subject: String) -> Bool {
        return search(subject) != nil
    }
}

