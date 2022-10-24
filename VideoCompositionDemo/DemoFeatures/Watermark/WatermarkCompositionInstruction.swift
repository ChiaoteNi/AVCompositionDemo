//
//  WatermarkCompositionInstruction.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/10/23.
//

import Foundation
import AVFoundation

final class WatermarkCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {

    let watermarkImageURL: URL

    /// The number of bits to use for each component of a pixel in memory.
    ///
    /// For example, for a 32-bit pixel format and an RGBA color space, you would specify a value of 8 bits per component.
    /// That means R = 8bit, G = 8bit, B = 8bit, and A = 8bit
    /// component: R/G/B/A
    /// For the list of supported pixel formats, you can see
    /// [Supported Pixel Formats](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB)
    let bitsPerComponent: Int = 8

    var colorSpace: CGColorSpace {
        CGColorSpaceCreateDeviceRGB()
    }

    /// Storage options for alpha component data.
    ///
    /// (1) whether a bitmap contains an alpha channel
    /// (2) where the alpha bits are located in the image data
    /// (3) whether the alpha value is premultiplied.
    let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue // RGBA

    // MARK: Properties for AVVideoCompositionInstructionProtocol

    /// Indicates the timeRange during which the instruction is effective.
    /// Note requirements for the timeRanges of instructions described in connection with AVVideoComposition's instructions key above.
    var timeRange: CMTimeRange

    /// If NO, indicates that post-processing should be skipped for the duration of this instruction.
    var enablePostProcessing: Bool = false

    /// If YES, rendering a frame from the same source buffers and the same composition instruction at 2 different compositionTime may yield different output frames.
    /// If NO, 2 such compositions would yield the same frame.
    /// The media pipeline may me able to avoid some duplicate processing when containsTweening is NO
    var containsTweening: Bool = true

    /// List of video track IDs required to compose frames for this instruction. If the value of this property is nil, all source tracks will be considered required for composition
    var requiredSourceTrackIDs: [NSValue]?

    /// If for the duration of the instruction, the video composition result is one of the source frames, this property should
    /// return the corresponding track ID. The compositor won't be run for the duration of the instruction and the proper source
    /// frame will be used instead. The dimensions, clean aperture and pixel aspect ratio of the source buffer will be matched to the required values automatically
    var passthroughTrackID: CMPersistentTrackID

    init(
        watermarkURL: URL,
        timeRange: CMTimeRange,
        requiredSourceTrackIDs: [NSValue]? = nil,
        passthroughTrackID: CMPersistentTrackID? = nil
    ) {
        self.watermarkImageURL = watermarkURL
        self.timeRange = timeRange
        self.requiredSourceTrackIDs = requiredSourceTrackIDs
        self.passthroughTrackID = passthroughTrackID ?? kCMPersistentTrackID_Invalid
    }
}
