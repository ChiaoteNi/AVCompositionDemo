//
//  PlayerItemMaker.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/13.
//

import Foundation
import AVFoundation

protocol PlayerItemMaker {
    func makePlayerItem() -> AVPlayerItem?
}
