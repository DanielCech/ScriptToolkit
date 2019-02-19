//
//  String+Substrings.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 08.11.2018.
//  Copyright © 2018 STRV. All rights reserved.
//

import Foundation

public extension String {
    public subscript(value: NSRange) -> Substring {
        return self[value.lowerBound ..< value.upperBound]
    }
}

// MARK: - Subscripts

public extension String {
    public subscript(value: CountableClosedRange<Int>) -> Substring {
        return self[index(at: value.lowerBound) ... index(at: value.upperBound)]
    }

    public subscript(value: CountableRange<Int>) -> Substring {
        return self[index(at: value.lowerBound) ..< index(at: value.upperBound)]
    }

    public subscript(value: PartialRangeUpTo<Int>) -> Substring {
        return self[..<index(at: value.upperBound)]
    }

    public subscript(value: PartialRangeThrough<Int>) -> Substring {
        return self[...index(at: value.upperBound)]
    }

    public subscript(value: PartialRangeFrom<Int>) -> Substring {
        return self[index(at: value.lowerBound)...]
    }

    public func index(at offset: Int) -> String.Index {
        return index(startIndex, offsetBy: offset)
    }
}

// MARK: - Safe subscripts

public extension String {
    public subscript(safe value: CountableClosedRange<Int>) -> Substring {
        let lowerBound = max(value.lowerBound, 0)
        let upperBound = min(value.upperBound, max(count - 1, 0))
        return self[index(at: lowerBound) ... index(at: upperBound)]
    }

    public subscript(safe value: CountableRange<Int>) -> Substring {
        let lowerBound = max(value.lowerBound, 0)
        let upperBound = min(value.upperBound, max(count, 0))
        return self[index(at: lowerBound) ..< index(at: upperBound)]
    }

    public subscript(safe value: PartialRangeUpTo<Int>) -> Substring {
        let upperBound = min(value.upperBound, max(count, 0))
        return self[..<index(at: upperBound)]
    }

    public subscript(safe value: PartialRangeThrough<Int>) -> Substring {
        let upperBound: Int
        if value.upperBound >= 0 {
            upperBound = min(value.upperBound, max(count - 1, 0))
        }
        else {
            upperBound = max(0, count - 1 + value.upperBound)
        }

        return self[...index(at: upperBound)]
    }

    public subscript(safe value: PartialRangeFrom<Int>) -> Substring {
        let lowerBound = max(value.lowerBound, 0)
        return self[index(at: lowerBound)...]
    }
}
