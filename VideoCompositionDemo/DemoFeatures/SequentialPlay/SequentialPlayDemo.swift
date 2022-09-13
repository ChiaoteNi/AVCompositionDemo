//
//  SequentialPlayDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/13.
//

import Foundation
import AVFoundation

fileprivate struct TrackManipulator {
    let asset: AVAsset
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTrackID: CMPersistentTrackID

    func trackID(for mediaType: AVMediaType) -> CMPersistentTrackID {
        // ⬇️ Just for convenience to make the demo, you should not create the trackID like this.
        return mediaType == .video
        ? preferredTrackID
        : preferredTrackID + 1000
    }

    func addTrack(
        to composition: AVMutableComposition,
        withMediaType mediaType: AVMediaType
    ) throws {
        guard
            // The demo asset is original with no compositing, meaning it will only have one video and one audio track.
            let assetTrack = asset.tracks(withMediaType: mediaType).first
        else {
            return
        }

        let compositionTrack: AVMutableCompositionTrack? = {
            // In case the track is already created, use that track.
            if let track = composition.track(withTrackID: trackID(for: mediaType)) {
                return track
            }
            // Otherwise, add a mutableTrack with the specific trackID into the composition.
            return composition.addMutableTrack(
                withMediaType: mediaType,
                // Pass kCMPersistentTrackID_Invalid to automatically generate an appropriate identifier by the systems.
                preferredTrackID: trackID(for: mediaType)
            )
        }()

        try compositionTrack?.insertTimeRange(
            preferredTimeRange,
            of: assetTrack,
            at: preferredStartTime
        )
    }
}

final class SequentialPlayDemo: PlayerItemMaker {

}
