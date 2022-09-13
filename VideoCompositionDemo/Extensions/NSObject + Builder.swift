//
//  UIView + Builder.swift
//  Utilities
//
//  Created by Aaron Ni on 2019/8/7.
//  Copyright © 2019 Aaron_Ni. All rights reserved.
//

import Foundation

public protocol Buildable: AnyObject {}

public extension Buildable {
    
    @discardableResult
    func set<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, to value: T) -> Self {
        self[keyPath: keyPath] = value
        return self
    }
}

extension NSObject: Buildable {}
