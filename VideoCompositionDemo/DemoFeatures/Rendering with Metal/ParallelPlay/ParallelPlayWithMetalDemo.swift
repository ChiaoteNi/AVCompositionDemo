//
//  ParallelPlayWithMetalDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

import Foundation
import AVFoundation

struct ParallelPlayWithMetalTrackContext: TrackContextProtocol {
    let asset: AVAsset
    let index: Int
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTrackID: CMPersistentTrackID
}

final class ParallelPlayWithMetalDemo: FocusedOnVideoCompositionDemoPlayerItemMaker {

    typealias TrackContext = ParallelPlayWithMetalTrackContext

    func makeTrackContexts() -> [TrackContext] {
        let assets = [
            AVAsset(for: "IMG_1007", withExtension: "MOV"),
            AVAsset(for: "IMG_7459", withExtension: "MOV"),
            AVAsset(for: "IMG_9420", withExtension: "MOV"),
            AVAsset(for: "IMG_0359", withExtension: "MOV")
        ]

        let makeCMTime: (_ seconds: Double) -> CMTime = { seconds in
            CMTime(
                seconds: seconds,
                preferredTimescale: 30
            )
        }

        let (assetTracks): ([ParallelPlayWithMetalTrackContext]) = assets
            .compactMap { $0 }
            .enumerated()
            .map { enumeratedElement in
                let index = enumeratedElement.offset
                let asset = enumeratedElement.element

                let timeRange = CMTimeRange(
                    start: .zero,
                    duration: makeCMTime(Double(index + 2))
                )
                let trackContext = ParallelPlayWithMetalTrackContext(
                    asset: asset,
                    index: index,
                    preferredTimeRange: timeRange,
                    preferredStartTime: .zero,
                    preferredTrackID: CMPersistentTrackID(index + 1)
                )
                return trackContext
            }

        return assetTracks
    }
}

// MARK: - About making VideoComposition
extension ParallelPlayWithMetalDemo {

    func makeVideoComposition(with trackContexts: [TrackContext]) -> AVVideoComposition? {
        guard !trackContexts.isEmpty else {
            return nil
        }

        let videoComposition: AVVideoComposition? = {
            guard let instruction = makeInstruction(with: trackContexts) else {
                return nil
            }
            let composition = AVMutableVideoComposition()
            composition.customVideoCompositorClass = ParallelPlayWithMetalVideoCompositor.self // The difference
            composition.instructions = [instruction]
            composition.renderSize = Constants.demoVideoSize // It's required.
            composition.frameDuration = CMTime(seconds: 1/30, preferredTimescale: 30) // It's required.
            return composition
        }()

        return videoComposition
    }

    private func makeInstruction(with trackContexts: [TrackContext]) -> AVVideoCompositionInstructionProtocol? {

        let result: (CMTimeRange, [ParallelPlayWithMetalLayerInstruction]) = trackContexts
            .reduce(into:(.zero, [])) { partialResult, trackContext in

                let currentTimeRange = partialResult.0
                let timeRange = CMTimeRange(
                    start: trackContext.preferredStartTime,
                    duration: trackContext.preferredTimeRange.duration
                )
                partialResult.0 = CMTimeRangeGetUnion(
                    currentTimeRange,
                    otherRange: timeRange
                )

                let instruction = ParallelPlayWithMetalLayerInstruction(
                    trackID: trackContext.preferredTrackID,
                    startTime: trackContext.preferredStartTime,
                    timeRange: trackContext.preferredTimeRange,
                    index: trackContext.index
                )
                partialResult.1.append(instruction)
            }

        let videoInstruction = ParallelPlayWithMetalCompositionInstruction(
            videoLayerInstructions: result.1,
            timeRange: result.0
        )
        return videoInstruction
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

private extension CMTime {
    static func - (_ lhs: CMTime, _ rhs: Double) -> CMTime {
        CMTime(
            seconds: lhs.seconds - rhs,
            preferredTimescale: lhs.timescale
        )
    }
}
