//
//  ParallelPlayWithMetalVideoCompositor.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

import Foundation
import AVFoundation

private struct ParallelPlayWithMetalError: Error {
    let description: String
}

final class ParallelPlayWithMetalVideoCompositor: NSObject, AVVideoCompositing {

    // MARK: AVVideoCompositing properties

    var sourcePixelBufferAttributes: [String : Any]? = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    // MARK: Private properties

    // The primary part for the part III demo
    private var metalRenderer = ParallelPlayMetalRenderer()

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
extension ParallelPlayWithMetalVideoCompositor {

    private func newRenderedPixelBufferForRequest(_ request: AVAsynchronousVideoCompositionRequest) throws -> CVPixelBuffer {

        guard let instruction = request.videoCompositionInstruction as? ParallelPlayWithMetalCompositionInstruction else {
            let error: VideoCompositingError = .incorrectVideoCompositionInstructionType(
                currentInstruction: request.videoCompositionInstruction
            )
            throw error
        }
        guard let outputBuffer: CVPixelBuffer = request.renderContext.newPixelBuffer() else {
            let error: VideoCompositingError = .generateOutputPixelBufferFailed
            throw error
        }
        
        let sources = instruction
            .videoLayerInstructions
            .compactMap { layerInstructions in
                return request.sourceFrame(
                    byTrackID: layerInstructions.trackID
                )
            }

        metalRenderer?.renderPixelBuffer(outputBuffer, sources: sources)
        return outputBuffer
    }
}

