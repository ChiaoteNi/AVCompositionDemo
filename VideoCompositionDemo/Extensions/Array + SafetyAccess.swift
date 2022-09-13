//
//  Array + Safety Access.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/11.
//  Copyright (c) 2022 iOS@Taipei. All rights reserved.

import Foundation

public extension Array {
    
    subscript(safe index: Int) -> Element? {
        get {
            guard index >= 0, index < count else { return nil }
            return self[index]
        }
        set {
            guard index >= 0, index < count, let newValue = newValue else { return }
            self[index] = newValue
        }
    }
}
