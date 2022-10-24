//
//  ParallelPlayDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/12.
//

import UIKit
import AVFoundation

private struct ParallelTrackContext: TrackContextProtocol {
    let asset: AVAsset
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTransform: CGAffineTransform
    let preferredTrackID: CMPersistentTrackID
}

final class ParallelPlayDemo: PlayerItemMaker {

    func makePlayerItem() -> AVPlayerItem? {
        let manipulators = makeTrackContexts()
        guard !manipulators.isEmpty else { return nil }

        // For handling how all the tracks(video/audio) are played with their specific time ranges.
        let composition: AVComposition = makeComposition(with: manipulators)
        // For getting more granular control for how the frames are rendered.
        let videoComposition: AVVideoComposition? = makeVideoComposition(with: manipulators)
        // For getting more granular control for how the sounds are played.
        let audioMix: AVAudioMix? = makeAudioMix(with: manipulators)

        return AVPlayerItem(asset: composition)
            .set(\.seekingWaitsForVideoCompositionRendering, to: true)
            .set(\.videoComposition, to: videoComposition)
            .set(\.audioMix, to: audioMix)
    }
}

// MARK: - Private functions
extension ParallelPlayDemo {

    private func makeTrackContexts() -> [ParallelTrackContext] {
        guard
            let topLeftAsset = AVAsset(for: "IMG_1007", withExtension: "MOV"),
            let topRightAsset = AVAsset(for: "IMG_7459", withExtension: "MOV"),
            let bottomLeftAsset = AVAsset(for: "IMG_7459", withExtension: "MOV"),
            let bottomRightAsset = AVAsset(for: "IMG_1007", withExtension: "MOV")
        else {
            return []
        }

        let makeCMTime: (_ seconds: Double) -> CMTime = { seconds in
            CMTime(
                seconds: seconds,
                preferredTimescale: 600
            )
        }
        let makeTimeRangeFromZero: (_ duration: Double) -> CMTimeRange = { duration in
            CMTimeRange(
                start: .zero,
                duration: makeCMTime(duration)
            )
        }

        return [
            ParallelTrackContext(
                asset: topLeftAsset,
                preferredTimeRange: makeTimeRangeFromZero(3),
                preferredStartTime: makeCMTime(.zero),
                preferredTransform: .identity,
                preferredTrackID: 1
            ),
            ParallelTrackContext(
                asset: topRightAsset,
                preferredTimeRange: makeTimeRangeFromZero(4),
                preferredStartTime: makeCMTime(.zero),
                preferredTransform: CGAffineTransform(
                    translationX: Constants.demoVideoSize.width,
                    y: 0
                ),
                preferredTrackID: 2
            ),
            ParallelTrackContext(
                asset: bottomLeftAsset,
                preferredTimeRange: makeTimeRangeFromZero(5),
                preferredStartTime: makeCMTime(.zero),
                preferredTransform: CGAffineTransform(
                    translationX: 0,
                    y: Constants.demoVideoSize.height
                ),
                preferredTrackID: 3
            ),
            ParallelTrackContext(
                asset: bottomRightAsset,
                preferredTimeRange: makeTimeRangeFromZero(6),
                preferredStartTime: makeCMTime(.zero),
                preferredTransform: CGAffineTransform(
                    translationX: Constants.demoVideoSize.width,
                    y: Constants.demoVideoSize.height
                ),
                preferredTrackID: 4
            )
        ]
    }

    private func makeComposition(with trackContexts: [TrackContextProtocol]) -> AVComposition {
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
        return nil
    }
}

// MARK: - About making VideoComposition
extension ParallelPlayDemo {

    private func makeVideoComposition(with trackContexts: [ParallelTrackContext]) -> AVVideoComposition? {
        guard !trackContexts.isEmpty else {
            return nil
        }

        let videoComposition: AVVideoComposition? = {
            guard let instruction = makeInstruction(with: trackContexts) else {
                return nil
            }
            let composition = AVMutableVideoComposition()
            composition.instructions = [instruction]
            composition.renderSize = Constants.demoVideoSize * 2 // It's required.
            composition.frameDuration = CMTime(seconds: 1/600, preferredTimescale: 600) // It's required.
            return composition
        }()

        return videoComposition
    }

    private func makeInstruction(with trackContexts: [ParallelTrackContext]) -> AVVideoCompositionInstruction? {

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
                partialResult.0 = CMTimeRangeGetUnion(partialResult.0, otherRange: timeRange)
                partialResult.1.append(layerInstruction)
            }

        let videoInstruction = AVMutableVideoCompositionInstruction()
        videoInstruction.timeRange = timeRange
        videoInstruction.layerInstructions = layerInstructions

        return videoInstruction
    }

    private func makeLayerInstruction(with trackContext: ParallelTrackContext) -> AVVideoCompositionLayerInstruction? {
        let trackID = trackContext.trackID(for: .video)
        guard let assetTrack = trackContext.asset.track(withTrackID: trackID) else {
            return nil
        }

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
        layerInstruction.setTransform(
            trackContext.preferredTransform,
            at: trackContext.preferredStartTime
        )
        return layerInstruction
    }
}

// MARK: - Constants and Util functions

private enum Constants {

    // ⬇️ Just to easier make the demo and make the demo more focused on the video composition.
    //    Generally, you'll need to get the size by yourself in run-time but not hardcode it as a constant.
    static var demoVideoSize: CGSize {
        CGSize(width: 1920, height: 1080)
    }
}

private extension CGSize {

    static func *(_ lhs: CGSize, _ rhs: CGFloat) -> CGSize {
        CGSize(
            width: lhs.width * rhs,
            height: lhs.height * rhs
        )
    }
}
