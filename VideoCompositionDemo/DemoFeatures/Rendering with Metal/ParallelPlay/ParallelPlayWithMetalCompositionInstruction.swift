//
//  ParallelPlayWithMetalCompositionInstruction.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

import Foundation
import AVFoundation

enum VideoPosition {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct ParallelPlayWithMetalLayerInstruction {
    // In the current case, we only need trackID to get all other necessary information
    // However, most of the time, you will need to do much more detailed control for each video track
    // That means it will be required to do like this, define a VideoLayerInstruction to store more detailed information
    // Considering that this project is made to demo how to work with video composition,
    // I decided to do this, even though it looks not that required in this case.
    let trackID: CMPersistentTrackID
    let startTime: CMTime
    let timeRange: CMTimeRange
    let index: Int
}

final class ParallelPlayWithMetalCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {

    var videoLayerInstructions: [ParallelPlayWithMetalLayerInstruction]

    /// Indicates the timeRange during which the instruction is effective.
    /// Note requirements for the timeRanges of instructions described in connection with AVVideoComposition's instructions key above.
    var timeRange: CMTimeRange
    /// If NO, indicates that post-processing should be skipped for the duration of this instruction.
    var enablePostProcessing: Bool = true
    /// If YES, rendering a frame from the same source buffers and the same composition instruction at 2 different compositionTime may yield different output frames.
    /// If NO, 2 such compositions would yield the same frame.
    /// The media pipeline may me able to avoid some duplicate processing when containsTweening is NO
    var containsTweening: Bool = true
    /// List of video track IDs required to compose frames for this instruction.
    /// If the value of this property is nil, all source tracks will be considered required for composition
    var requiredSourceTrackIDs: [NSValue]?
    /// If for the duration of the instruction, the video composition result is one of the source frames, this property should
    /// return the corresponding track ID. The compositor won't be run for the duration of the instruction and the proper source
    /// frame will be used instead. The dimensions, clean aperture and pixel aspect ratio of the source buffer will be matched to the required values automatically
    var passthroughTrackID: CMPersistentTrackID

    init(
        videoLayerInstructions: [ParallelPlayWithMetalLayerInstruction],
        timeRange: CMTimeRange,
        requiredSourceTrackIDs: [NSValue]? = nil,
        passthroughTrackID: CMPersistentTrackID? = nil
    ) {
        self.videoLayerInstructions = videoLayerInstructions
        self.timeRange = timeRange
        self.requiredSourceTrackIDs = requiredSourceTrackIDs
        self.passthroughTrackID = passthroughTrackID ?? kCMPersistentTrackID_Invalid
    }
}

