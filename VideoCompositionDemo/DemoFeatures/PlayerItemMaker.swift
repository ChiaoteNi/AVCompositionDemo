//
//  PlayerItemMaker.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/13.
//

import Foundation
import AVFoundation

protocol PlayerItemMaker {
    func makePlayerItem() -> AVPlayerItem?
}

// This protocol is made to let us focus on how the VideoComposition works
// I only designed 2 function interfaces, which are required and variations about demo making VideoComposition
// In the meantime, I made 2 default function implementations for making AVPlayerItem and AVComposition, which are needed but we've already known how they work by the previous demos (ex: BasicDemo, SequentialPlayDemo)
protocol FocusedOnVideoCompositionDemoPlayerItemMaker: PlayerItemMaker {
    associatedtype TrackContext: TrackContextProtocol
    func makeTrackContexts() -> [TrackContext]
    func makeVideoComposition(with trackContexts: [TrackContext]) -> AVVideoComposition?
}

extension FocusedOnVideoCompositionDemoPlayerItemMaker {

    func makePlayerItem() -> AVPlayerItem? {
        let manipulators: [TrackContext] = makeTrackContexts()
        guard !manipulators.isEmpty else { return nil }

        let composition = makeComposition(with: manipulators)
        let videoComposition = makeVideoComposition(with: manipulators)

        return AVPlayerItem(asset: composition)
            .set(\.videoComposition, to: videoComposition)
    }

    func makeComposition(with trackContexts: [TrackContextProtocol]) -> AVMutableComposition {
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
}
