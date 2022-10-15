//
//  ParallelPlayDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/12.
//

import UIKit
import AVFoundation

fileprivate struct TrackManipulator {
    let asset: AVAsset
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTransform: CGAffineTransform

    func addTrack(
        to composition: AVMutableComposition,
        withMediaType mediaType: AVMediaType
    ) throws {
        guard
            // This asset is original with no compositing, meaning it will only have one video and one audio track.
            let assetTrack = asset.tracks(withMediaType: mediaType).first,
            let compositionTrack = composition.addMutableTrack(
                withMediaType: mediaType,
                // Pass kCMPersistentTrackID_Invalid to automatically generate an appropriate identifier by the systems.
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else {
            return
        }

        try compositionTrack.insertTimeRange(
            preferredTimeRange,
            of: assetTrack,
            at: preferredStartTime
        )
    }
}

final class ParallelPlayDemo: PlayerItemMaker {

    func makePlayerItem() -> AVPlayerItem? {
        nil
    }
}
