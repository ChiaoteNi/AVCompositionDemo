//
//  VideoCompositingError.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/10/23.
//

import Foundation
import AVFoundation

enum VideoCompositingError: Error {
    case generateOutputPixelBufferFailed
    case incorrectVideoCompositionInstructionType(currentInstruction: AVVideoCompositionInstructionProtocol)
    case currentLayerInstructionNotFound
    case targetSourceFrameNotFound
}
