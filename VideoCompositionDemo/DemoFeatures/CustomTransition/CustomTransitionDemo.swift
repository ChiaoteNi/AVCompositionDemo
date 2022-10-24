//
//  CustomTransitionDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/13.
//

import Foundation
import AVFoundation

struct CustomTransitionTrackContext: TrackContextProtocol {
    let asset: AVAsset
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTrackID: CMPersistentTrackID
}

final class CustomTransitionDemo: FocusedOnVideoCompositionDemoPlayerItemMaker {

    typealias TrackContext = CustomTransitionTrackContext

    func makeTrackContexts() -> [TrackContext] {
        let assets = [
            AVAsset(for: "IMG_1007", withExtension: "MOV"),
            AVAsset(for: "IMG_7459", withExtension: "MOV"),
            AVAsset(for: "IMG_9420", withExtension: "MOV")
        ]

        let makeCMTime: (_ seconds: Double) -> CMTime = { seconds in
            CMTime(
                seconds: seconds,
                preferredTimescale: 30
            )
        }

        let (_, assetTracks): (CMTime, [CustomTransitionTrackContext]) = assets
            .compactMap { $0 }
            .enumerated()
            .reduce(into: (.zero, [])) { partialResult, enumeratedElement in
                let index = enumeratedElement.offset
                let asset = enumeratedElement.element

                let startTime = partialResult.0
                let timeRange = CMTimeRange(
                    start: startTime,
                    duration: makeCMTime(Double(index + 2))
                )
                let trackContext = CustomTransitionTrackContext(
                    asset: asset,
                    preferredTimeRange: timeRange,
                    preferredStartTime: startTime,
                    preferredTrackID: CMPersistentTrackID(index + 1)
                )

                partialResult.0 = timeRange.end
                partialResult.1.append(trackContext)
            }

        return assetTracks
    }
}

// MARK: - About making VideoComposition
extension CustomTransitionDemo {

    func makeVideoComposition(with trackContexts: [TrackContext]) -> AVVideoComposition? {
        guard !trackContexts.isEmpty else {
            return nil
        }

        let videoComposition: AVVideoComposition? = {
            guard let instruction = makeInstruction(with: trackContexts) else {
                return nil
            }
            let composition = AVMutableVideoComposition()
            composition.customVideoCompositorClass = CustomTransitionVideoCompositor.self // The difference
            composition.instructions = [instruction]
            composition.renderSize = Constants.demoVideoSize // It's required.
            composition.frameDuration = CMTime(seconds: 1/30, preferredTimescale: 30) // It's required.
            return composition
        }()

        return videoComposition
    }

    private func makeInstruction(with trackContexts: [TrackContext]) -> AVVideoCompositionInstructionProtocol? {

        let result: (CMTimeRange, [CustomTransitionLayerInstruction]) = trackContexts
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

                let instruction = CustomTransitionLayerInstruction(
                    trackID: trackContext.preferredTrackID,
                    startTime: trackContext.preferredStartTime,
                    timeRange: trackContext.preferredTimeRange
                )
                partialResult.1.append(instruction)
            }

        let videoInstruction = CustomTransitionCompositionInstruction(
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
