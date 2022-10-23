//
//  WatermarkDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/13.
//

import Foundation
import AVFoundation

struct WatermarkTrackContext: TrackContextProtocol {
    let asset: AVAsset
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTrackID: CMPersistentTrackID
}

final class WatermarkDemo: FocusedOnVideoCompositionDemoPlayerItemMaker {

    typealias TrackContext = WatermarkTrackContext

    func makeTrackContexts() -> [TrackContext] {
        guard let asset = AVAsset(for: "IMG_1007", withExtension: "MOV") else {
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
            TrackContext(
                asset: asset,
                preferredTimeRange: makeTimeRangeFromZero(3),
                preferredStartTime: makeCMTime(.zero),
                preferredTrackID: 1
            )
        ]
    }
}

// MARK: - About making VideoComposition
extension WatermarkDemo {

    func makeVideoComposition(with trackContexts: [TrackContext]) -> AVVideoComposition? {
        guard !trackContexts.isEmpty else {
            return nil
        }

        let videoComposition: AVVideoComposition? = {
            guard let instruction = makeInstruction(with: trackContexts) else {
                return nil
            }
            let composition = AVMutableVideoComposition()
            composition.customVideoCompositorClass = WatermarkDemoVideoCompositor.self // The difference
            composition.instructions = [instruction]
            composition.renderSize = Constants.demoVideoSize // It's required.
            composition.frameDuration = CMTime(seconds: 1/600, preferredTimescale: 600) // It's required.
            return composition
        }()

        return videoComposition
    }

    private func makeInstruction(with trackContexts: [TrackContext]) -> AVVideoCompositionInstructionProtocol? {
        guard let watermarkURL = Bundle.main.url(forResource: "good", withExtension: "png") else {
            return nil
        }

        let timeRange: CMTimeRange = trackContexts
            .enumerated()
            .reduce(into: .zero) { partialResult, element in
                let trackContext = element.element

                let timeRange = CMTimeRange(
                    start: trackContext.preferredStartTime,
                    duration: trackContext.preferredTimeRange.duration
                )
                partialResult = CMTimeRangeGetUnion(partialResult, otherRange: timeRange)
            }

        let videoInstruction = WatermarkCompositionInstruction(
            watermarkURL: watermarkURL,
            timeRange: timeRange
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
