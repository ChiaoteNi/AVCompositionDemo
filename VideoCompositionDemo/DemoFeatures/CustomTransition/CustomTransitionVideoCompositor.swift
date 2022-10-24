//
//  CustomTransitionVideoCompositor.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/10/23.
//

import Foundation
import AVFoundation

private struct CustomTransitionError: Error {
    let description: String
}

final class CustomTransitionVideoCompositor: NSObject, AVVideoCompositing {

    // MARK: AVVideoCompositing properties

    var sourcePixelBufferAttributes: [String : Any]? = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    // MARK: Private properties

    // In the partII demo, we won't be going to focused on metalRendering yet,
    // I use the demo code made by Apple as the alternatively for now,
    // so that we can focused on how to make a CustomVideoCompositor first.
    private var metalRenderer: APLMetalRenderer = APLDiagonalWipeRenderer()! // APLCrossDissolveRenderer()!

    // Dispatch Queue used to issue custom compositor rendering work requests.
    private var renderingQueue = DispatchQueue(label: "com.videoCompositionDemo.renderingQueue")

    // MARK: AVVideoCompositing functions

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // The renderContext won't change in our demo case
    }

    /*
     - This delegate function will be invoke for every frame
     - If you intend to finish rendering the frame after your handling of this message returns, you must retain the instance of AVAsynchronousVideoCompositionRequest until after composition is finished.
     - If the custom compositor's implementation of -startVideoCompositionRequest: returns without finishing the composition immediately, it may be invoked again with another composition request before the prior request is finished; therefore in such cases the custom compositor should be prepared to manage multiple composition requests.
     - The above description is also the reason why most of the libs, which do this with Metal, will put this procedure into a queue, and make the procedure to be cancelable.
     */
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async {
            do {
                let result = try self.newRenderedPixelBufferForRequest(asyncVideoCompositionRequest)
                asyncVideoCompositionRequest.finish(withComposedVideoFrame: result)
            } catch {
                asyncVideoCompositionRequest.finish(with: error)
            }
        }
    }
}

// MARK: - Private functions
extension CustomTransitionVideoCompositor {

    private func newRenderedPixelBufferForRequest(_ request: AVAsynchronousVideoCompositionRequest) throws -> CVPixelBuffer {

        guard let instruction = request.videoCompositionInstruction as? CustomTransitionCompositionInstruction else {
            let error: VideoCompositingError = .incorrectVideoCompositionInstructionType(
                currentInstruction: request.videoCompositionInstruction
            )
            throw error
        }
        // Get the current frame time.
        let currentTime = request.compositionTime
        // It's not required, just to make the reduce process easier to read. (initialPair)
        let initialPair: (CustomTransitionLayerInstruction?, CustomTransitionLayerInstruction?) = (nil, nil)

        let (target, previous) = instruction.videoLayerInstructions
            .reduce(into: initialPair) { partialResult, instruction in
                guard partialResult.0 == nil else {
                    return
                }
                if currentTime > instruction.timeRange.end {
                    partialResult.1 = instruction
                } else {
                    partialResult.0 = instruction
                }
            }

        guard let targetLayerInstruction = target else {
            throw VideoCompositingError.currentLayerInstructionNotFound
        }
        guard let targetBuffer = request.sourceFrame(byTrackID: targetLayerInstruction.trackID) else {
            throw VideoCompositingError.targetSourceFrameNotFound
        }

        let tweenFactor: Float = {
            let elapsed = CMTimeSubtract(currentTime, targetLayerInstruction.startTime)
            let progress = elapsed.seconds / 2 // animation on 0 -> 2 seconds
            return Float(min(progress, 1))
        }()

        guard
            // Check if the frame needs to be rendered.
            tweenFactor < 1,
            // Get the foreground buffer
            let previousLayerInstruction = previous,
            let previousFrameBuffer = request.sourceFrame(byTrackID: previousLayerInstruction.trackID),
            // Get a blank buffer to render.
            let outputBuffer: CVPixelBuffer = request.renderContext.newPixelBuffer()
        else {
            return targetBuffer
        }

        metalRenderer.renderPixelBuffer(
            outputBuffer,
            usingForegroundSourceBuffer:previousFrameBuffer,
            andBackgroundSourceBuffer:targetBuffer,
            forTweenFactor:tweenFactor
        )
        return outputBuffer
    }
}
