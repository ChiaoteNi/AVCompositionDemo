//
//  WatermarkDemoVideoCompositor.swift.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/10/23.
//

import UIKit
import AVFoundation

private struct WatermarkCompositorError: Error {
    let description: String
}

final class WatermarkDemoVideoCompositor: NSObject, AVVideoCompositing {

    var sourcePixelBufferAttributes: [String : Any]? = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // TODO: leave some notes here about why/why not
    }

    /*
     - This delegate function will be invoke for every frame
     - If you intend to finish rendering the frame after your handling of this message returns, you must retain the instance of AVAsynchronousVideoCompositionRequest until after composition is finished.
     - If the custom compositor's implementation of -startVideoCompositionRequest: returns without finishing the composition immediately,
     it may be invoked again with another composition request before the prior request is finished; therefore in such cases the custom compositor should be prepared to manage multiple composition requests.
     - The above description is also the reason why most of the libs, which do this with Metal, will put this procedure into a queue, and make the procedure to be cancelable.
     */
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        let request = asyncVideoCompositionRequest

        guard let instruction = request.videoCompositionInstruction as? WatermarkCompositionInstruction else {
            let error: VideoCompositingError = .incorrectVideoCompositionInstructionType(
                currentInstruction: request.videoCompositionInstruction
            )
            asyncVideoCompositionRequest.finish(with: error)
            return
        }
        guard let image = UIImage(contentsOfFile: instruction.watermarkImageURL.path)?.cgImage else {
            let error = WatermarkCompositorError(
                description: "image init fail, path: \(instruction.watermarkImageURL.path)"
            )
            asyncVideoCompositionRequest.finish(with: error)
            return
        }

        /*
         The PixelBuffer, which is from renderContext.newPixelBuffer, will be given to you with a blank pixelBuffer to draw.
         In this demo, we're now focus on demo how to make a watermark, so it will be simpler to get the buffer from current video frame
         */
        //        let pixelBuffer: CVPixelBuffer? = request.renderContext.newPixelBuffer()

        // Like the above comment, in this demo, I want to focus on demo how to make a watermark
        // That means it's better to ignore multiple video tracks with variant transform or some other things,
        // so I designed the demo with only one video track existing, which can make the demo simpler
        // and easier to understand the primary part of this demo
        // However, you should not do this in most other situations
        let pixelBuffer: CVPixelBuffer? = request.sourceTrackIDs
            .compactMap { id in
                let trackID = CMPersistentTrackID(
                    truncating: id
                )
                return request.sourceFrame(byTrackID: trackID)
            }.first

        guard let pixelBuffer = pixelBuffer else {
            let error: VideoCompositingError = .generateOutputPixelBufferFailed
            asyncVideoCompositionRequest.finish(with: error)
            return
        }

        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)

        let watermarkLength = CGFloat(bufferWidth / 10)
        let watermarkFrame = CGRect(
            origin: CGPoint(
                x: CGFloat(bufferWidth) - watermarkLength,
                y: .zero
            ),
            size: CGSize(
                width: watermarkLength,
                height: watermarkLength
            )
        )

        // lock the buffer, then create a new context to draw the watermark
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: bufferWidth,
            height: bufferHeight,
            bitsPerComponent: instruction.bitsPerComponent,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: instruction.colorSpace,
            bitmapInfo: instruction.bitmapInfo
        )
        context?.draw(image, in: watermarkFrame)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        request.finish(withComposedVideoFrame: pixelBuffer)
    }
}
