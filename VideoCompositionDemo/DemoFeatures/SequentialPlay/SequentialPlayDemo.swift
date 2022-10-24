//
//  SequentialPlayDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/13.
//

import Foundation
import AVFoundation

private struct SequentialTrackContext: TrackContextProtocol {
    let asset: AVAsset
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTrackID: CMPersistentTrackID
}

final class SequentialPlayDemo: PlayerItemMaker {

    func makePlayerItem() -> AVPlayerItem? {
        let manipulators: [TrackContextProtocol] = makeTrackContexts()
        guard !manipulators.isEmpty else { return nil }

        // For handling how all the tracks(video/audio) are played with their specific time ranges.
        let composition: AVComposition = makeComposition(with: manipulators)
        // For getting more granular control for how the frames are rendered.
        let videoComposition: AVVideoComposition? = makeVideoComposition(with: manipulators)
        // For getting more granular control for how the sounds are played.
        let audioMix: AVAudioMix? = makeAudioMix(with: manipulators)

        return AVPlayerItem(asset: composition)
            .set(\.videoComposition, to: videoComposition)
            .set(\.audioMix, to: audioMix)
    }
}

// MARK: - Private functions
extension SequentialPlayDemo {

    private func makeTrackContexts() -> [TrackContextProtocol] {
        guard
            let firstAsset = makeAVAsset(for: "IMG_1007", with: "MOV"),
            let secondAsset = makeAVAsset(for: "IMG_7459", with: "MOV")
        else {
            return []
        }

        let duration = CMTime(seconds: 3, preferredTimescale: 600)
        let start = CMTime(seconds: .zero, preferredTimescale: 600)

        let firstTrackContext: TrackContextProtocol = {
            return SequentialTrackContext(
                asset: firstAsset,
                preferredTimeRange: CMTimeRange(start: .zero, duration: duration),
                preferredStartTime: start,
                preferredTrackID: 1
            )
        }()
        let secondTrackContext: TrackContextProtocol = {
            return SequentialTrackContext(
                asset: secondAsset,
                preferredTimeRange: CMTimeRange(start: .zero, duration: duration),
                // For the case with multiple compositionTrack
                preferredStartTime: CMTimeRangeGetEnd(firstTrackContext.preferredTimeRange),
                preferredTrackID: 2
                //                // For the case with only one compositionTrack
                //                preferredStartTime: CMTimeRangeGetEnd(firstTrackContext.preferredTimeRange),
                //                preferredTrackID: 1
            )
        }()

        return [
            firstTrackContext,
            secondTrackContext
        ]
    }

    private func makeComposition(with trackContexts: [TrackContextProtocol]) -> AVMutableComposition {
        let composition = AVMutableComposition()

        trackContexts.forEach { trackContext in
            do {
                try trackContext.addTrack(to: composition, withMediaType: .video)
                try trackContext.addTrack(to: composition, withMediaType: .audio)
            } catch {
                debugPrint(error)
                assertionFailure()
            }
        }
        return composition
    }

    private func makeAudioMix(with trackContexts: [TrackContextProtocol]) -> AVAudioMix? {
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

    private func makeVideoComposition(with trackContexts: [TrackContextProtocol]) -> AVVideoComposition? {
        guard !trackContexts.isEmpty else {
            return nil
        }

//        let videoComposition: AVVideoComposition? = nil

        let videoComposition: AVVideoComposition? = {
            guard let instruction = makeInstruction(with: trackContexts) else {
                return nil
            }
            let composition = AVMutableVideoComposition()
            composition.instructions = [instruction]
            // The size at which the video composition should render.
            // ex: if the video size is 1000 * 500, and you set the renderSize to 500 * 250
            // Then the video will only render the 1/4 top left side
            composition.renderSize = CGSize(width: 1200, height: 800) // It's required.
            // A time interval for which the video composition should render composed video frames.
            composition.frameDuration = CMTime(seconds: 1/600, preferredTimescale: 600) // It's required.
            return composition
        }()

        return videoComposition
    }

    private func makeInstruction(with trackContexts: [TrackContextProtocol]) -> AVVideoCompositionInstruction? {

        let (timeRange, layerInstructions): (CMTimeRange, [AVVideoCompositionLayerInstruction]) = trackContexts
            .enumerated()
            .reduce(into: (.zero, [])) { partialResult, element in
                let trackContext = element.element
                guard let layerInstruction = makeLayerInstruction(with: trackContext) else {
                    return
                }
                let timeRange = CMTimeRange(
                    start: trackContext.preferredStartTime,
                    duration: trackContext.preferredTimeRange.duration
                )
                partialResult.0 = CMTimeRangeGetUnion(
                    partialResult.0,
                    otherRange: timeRange
                )
                partialResult.1.append(layerInstruction)
            }

        let videoInstruction = AVMutableVideoCompositionInstruction()
        videoInstruction.timeRange = timeRange
        videoInstruction.layerInstructions = layerInstructions

        return videoInstruction
    }

    private func makeLayerInstruction(with trackContext: TrackContextProtocol) -> AVVideoCompositionLayerInstruction? {
        let trackID = trackContext.trackID(for: .video)
        guard let assetTrack = trackContext.asset.track(withTrackID: trackID) else {
            return nil
        }

        let startTime = trackContext.preferredStartTime
        let timeRange = CMTimeRange(
            start: startTime,
            duration: trackContext.preferredTimeRange.duration
        )

        // Disappear when finish
        let instruction: AVVideoCompositionLayerInstruction = { // An object used to modify the transform, cropping, and opacity ramps applied to a given track in a composition.
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
            layerInstruction.setOpacity(1, at: startTime)
            layerInstruction.setOpacity(0, at: timeRange.end)
            return layerInstruction
        }()

//        // Fade in/out
//        let instruction: AVVideoCompositionLayerInstruction = {
//            let fadeInTimeRange = CMTimeRange(
//                start: timeRange.start,
//                duration: CMTime(seconds: 1, preferredTimescale: 1)
//            )
//            let fadeOutTimeRange = CMTimeRange(
//                start: timeRange.end - 1,
//                duration: CMTime(seconds: 1, preferredTimescale: 1)
//            )
//            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
//            layerInstruction.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: fadeInTimeRange)
//            layerInstruction.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: fadeOutTimeRange)
//            return layerInstruction
//        }()

//        // Overlap
//        let instruction: AVVideoCompositionLayerInstruction = {
//            let timeRange = CMTimeRange(
//                start: timeRange.end - 1,
//                duration: CMTime(seconds: 3, preferredTimescale: 1)
//            )
//            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
//            // A layerInstruction can only be set up one time for each kind of ramp.
//            // That means if you setTransformRamp first with scale-up, then setTransformRamp again with translation in the same time range
//            // , the scale-up transform will be override
//            layerInstruction.setOpacityRamp(
//                fromStartOpacity: 1,
//                toEndOpacity: 0,
//                timeRange: timeRange
//            )
//            layerInstruction.setTransformRamp(
//                fromStart: .identity,
//                toEnd: CGAffineTransform(scaleX: 3, y: 3),
//                timeRange: timeRange
//            )
//            return layerInstruction
//        }()

        return instruction
    }
}

// MARK: - Util functions

extension CMTime {
    fileprivate static func - (_ lhs: CMTime, _ rhs: Double) -> CMTime {
        CMTime(
            seconds: lhs.seconds - rhs,
            preferredTimescale: lhs.timescale
        )
    }
}
