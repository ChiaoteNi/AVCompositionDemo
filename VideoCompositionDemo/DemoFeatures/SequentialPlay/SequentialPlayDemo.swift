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

    func makePlayerItem() -> AVPlayerItem? {
        let manipulators: [TrackManipulator] = makeTrackManipulators()
        guard !manipulators.isEmpty else { return nil }

        // For handling how all the tracks(video/audio) are played with their specific time ranges.
        let composition = makeComposition(with: manipulators)
        // For getting more granular control for how the frames are rendered.
        let videoComposition = makeVideoComposition(with: manipulators)
        // For getting more granular control for how the sounds are played.
        let audioMix = makeAudioMix(with: manipulators)

        return AVPlayerItem(asset: composition)
            .set(\.videoComposition, to: videoComposition)
            .set(\.audioMix, to: audioMix)
    }
}

// MARK: - Private functions
extension SequentialPlayDemo {

    private func makeTrackManipulators() -> [TrackManipulator] {
        guard
            let firstAsset = makeAVAsset(for: "IMG_1007", with: "MOV"),
            let secondAsset = makeAVAsset(for: "IMG_7459", with: "MOV")
        else {
            return []
        }

        let duration = CMTime(seconds: 5, preferredTimescale: 600)
        let start = CMTime(seconds: .zero, preferredTimescale: 600)

        let firstTrackManipulator: TrackManipulator = {
            return TrackManipulator(
                asset: firstAsset,
                preferredTimeRange: CMTimeRange(start: .zero, duration: duration),
                preferredStartTime: start,
                preferredTrackID: 1
            )
        }()
        let secondTrackManipulator: TrackManipulator = {
            return TrackManipulator(
                asset: secondAsset,
                preferredTimeRange: CMTimeRange(start: .zero, duration: duration),
//                // For the case with multiple compositionTrack
//                preferredStartTime: CMTimeRangeGetEnd(firstTrackManipulator.preferredTimeRange),
//                preferredTrackID: 2
                // For the case with only one compositionTrack
                preferredStartTime: CMTimeRangeGetEnd(firstTrackManipulator.preferredTimeRange),
                preferredTrackID: 1
            )
        }()

        return [
            firstTrackManipulator,
            secondTrackManipulator
        ]
    }

    private func makeComposition(with trackManipulators: [TrackManipulator]) -> AVMutableComposition {
        let composition = AVMutableComposition()

        trackManipulators.forEach { trackManipulator in
            do {
                try trackManipulator.addTrack(to: composition, withMediaType: .video)
                try trackManipulator.addTrack(to: composition, withMediaType: .audio)
            } catch {
                debugPrint(error)
                assertionFailure()
            }
        }
        return composition
    }

    private func makeAudioMix(with trackManipulators: [TrackManipulator]) -> AVAudioMix? {
        // Don't need to use it in this sample case.
        return nil
    }

    private func makeAVAsset(
        for resource: String,
        with fileExtension: String
    ) -> AVAsset? {
        guard let url = Bundle.main.url(
            forResource: resource,
            withExtension: fileExtension
        ) else {
            return nil
        }
        let asset = AVAsset(url: url)
        return asset
    }
}

// It's the part that is not important for Part I Sharing
// MARK: - About making VideoComposition
extension SequentialPlayDemo {

    private func makeVideoComposition(with trackManipulators: [TrackManipulator]) -> AVVideoComposition? {
        nil
    }
}
