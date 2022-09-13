//
//  BasicDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/13.
//

import Foundation
import AVFoundation

final class BasicDemo: PlayerItemMaker {

    func makePlayerItem() -> AVPlayerItem? {
        guard
            // For handling how all the tracks(video/audio) are played with their specific time ranges.
            let composition: AVComposition = makeComposition()
        else {
            return nil
        }
        // For getting more granular control for how the frames are rendered.
        let videoComposition: AVVideoComposition? = makeVideoComposition()
        // For getting more granular control for how the sounds are played.
        let audioMix: AVAudioMix? = makeAudioMix()

        return AVPlayerItem(asset: composition)
            .set(\.videoComposition, to: videoComposition)
            .set(\.audioMix, to: audioMix)
    }
}

// MARK: - Private functions
extension BasicDemo {

    private func makeComposition() -> AVComposition? {
        guard
            let asset = makeAVAsset(for: "IMG_1007", with: "MOV"),
            // Only call this method without blocking the current thread when the data in the tracks property is already loaded.
            // Otherwise, please load tracks asynchronously using loadTracks(withMediaType:completionHandler:) instead.
            let videoAssetTrack = asset.tracks(withMediaType: .video).first, // This Video is original with no compositing, meaning it will only have one video track.
            let audioAssetTrack = asset.tracks(withMediaType: .audio).first // Also, it will only have one audio track for the same reason.
        else {
            return nil
        }

        let composition = AVMutableComposition()

        // You can set a specific TrackID for the CompositionTrack.
        // Also, if you don’t need to specify a preferred track ID, just pass kCMPersistentTrackID_Invalid
        // and the system will generate an appropriate identifier.
        let videoTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
        let videoTrack: AVMutableCompositionTrack? = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: videoTrackID
        )

        let audioTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
        let audioTrack: AVMutableCompositionTrack? = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: audioTrackID
        )

        let start = CMTime(seconds: 8, preferredTimescale: 600)
        let timeRange = CMTimeRange(
            start: start,
            duration: CMTime(
                seconds: asset.duration.seconds - start.seconds,
                preferredTimescale: 600
            )
        )

        guard let videoTrack = videoTrack, let audioTrack = audioTrack else {
            return nil
        }

        do {
            try videoTrack.insertTimeRange(
                timeRange, // The time range you want to play the video.
                // ex: The asset will only play from seconds 2 to 6 if you set CMTimeRange(start: CMTime(seconds: 2, preferredTimescale: 600), duration: 4) to here.
                of: videoAssetTrack,
                at: .zero // The start time for playing
                // ex: The video will start to play after 2 seconds if you set CMTime(seconds: 2, preferredTimescale: 600) to here.
            )

            // Same as the descriptions for video
            try audioTrack.insertTimeRange(
                timeRange,
                of: audioAssetTrack,
                at: .zero
//                at: CMTime(seconds: 4, preferredTimescale: 600)
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
        return composition
    }

    private func makeVideoComposition() -> AVVideoComposition? {
        // Don't need to use it in this sample case.
        return nil
    }

    private func makeAudioMix() -> AVAudioMix? {
        // Don't need to use it in this sample case as well.
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
