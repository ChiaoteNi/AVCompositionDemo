/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 APLCrossDissolveRenderer subclass of APLMetalRenderer, renders the given source buffers to perform a cross
  dissolve over the time range of the transition.
 */

import Foundation
import CoreVideo
import MetalKit

class APLCrossDissolveRenderer: APLMetalRenderer {

    /// Vertex coordinates used for drawing our geomentric primitives (triangles).
    fileprivate let vertexArray: [Float] = [
        -1.0, 1.0, 0, 1,
        -1.0, -1.0, 0, 1,
        1.0, -1.0, 0, 1,
        -1.0, 1.0, 0, 1,
        1.0, -1.0, 0, 1,
        1.0, 1.0, 0, 1
    ]

    /// Texture coordinates used for drawing textures in the texture coordinate system.
    fileprivate let textureCoordsArray: [Float] = [
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 1.0,
        1.0, 0.0
    ]

    /// The colors for each vertex coordinate.
    fileprivate let colorArray: [Float] = [
        1, 0, 0, 1,
        0, 1, 0, 1,
        0, 0, 1, 1,
        1, 0, 0, 1,
        0, 0, 1, 1,
        1, 0, 1, 1
    ]

    /// MTLRenderPipelineState objects that contains compiled rendering state, including vertex and fragment shaders.
    fileprivate var foregroundRenderPipelineState: MTLRenderPipelineState!
    fileprivate var backgroundRenderPipelineState: MTLRenderPipelineState!

    /// MTLBuffer used for vertex data.
    fileprivate var vertexBuffer: MTLBuffer?
    /// MTLBuffer used for texture data.
    fileprivate var textureCoordBuffer: MTLBuffer?
    /// MTLBuffer used for color data.
    fileprivate var colorBuffer: MTLBuffer?

    /*
     Instance of RenderPixelBuffers to maintain references to pixel buffers until they are no longer
     needed.
    */
    fileprivate var pixelBuffers: RenderPixelBuffers?

    override init?() {

        super.init()
        // The default library contains all of the shader functions that were compiled into our app bundle.
        guard let library = device.makeDefaultLibrary() else { return nil }

        // Retrieve the functions that will comprise our pipeline.

        // Load the vertex program into the library
        guard let vertexFunc = library.makeFunction(name: "passthroughVertexShader") else { return nil }

        // Load the fragment program into the library
        guard let fragmentFunc = library.makeFunction(name: "texturedQuadFragmentShader") else { return nil }

        vertexBuffer = device.makeBuffer(
            bytes: vertexArray,
            length: vertexArray.count * MemoryLayout.size(ofValue: vertexArray[0]),
            options: .storageModeShared
        )
        textureCoordBuffer = device.makeBuffer(
            bytes: textureCoordsArray,
            length: textureCoordsArray.count * MemoryLayout.size(ofValue: textureCoordsArray[0]),
            options: .storageModeShared
        )
        colorBuffer = device.makeBuffer(
            bytes: colorArray,
            length: colorArray.count * MemoryLayout.size(ofValue: colorArray[0]),
            options: .storageModeShared
        )

        // Compile the functions and other state into a pipeline object.
        do {
            foregroundRenderPipelineState = try buildForegroundRenderPipelineState(
                vertexFunc,
                fragmentFunction: fragmentFunc
            )
            backgroundRenderPipelineState = try buildBackgroundRenderPipelineState(
                vertexFunc,
                fragmentFunction: fragmentFunc
            )
        } catch {
            print("Unable to compile render pipeline state due to error:\(error)")
            return nil
        }
    }

    override func renderPixelBuffer(
        _ destinationPixelBuffer: CVPixelBuffer,
        usingForegroundSourceBuffer foregroundPixelBuffer: CVPixelBuffer,
        andBackgroundSourceBuffer backgroundPixelBuffer: CVPixelBuffer,
        forTweenFactor tween: Float
    ) {

        // Create a MTLTexture from the CVPixelBuffer.
        guard let foregroundTexture = buildTextureForPixelBuffer(foregroundPixelBuffer) else { return }
        guard let backgroundTexture = buildTextureForPixelBuffer(backgroundPixelBuffer) else { return }
        guard let destinationTexture = buildTextureForPixelBuffer(destinationPixelBuffer) else { return }

        /*
         We must maintain a reference to the pixel buffer until the Metal rendering is complete. This is because the
         'buildTextureForPixelBuffer' function above uses CVMetalTextureCacheCreateTextureFromImage to create a
         Metal texture (CVMetalTexture) from the IOSurface that backs the CVPixelBuffer, but
         CVMetalTextureCacheCreateTextureFromImage doesn't increment the use count of the IOSurface; only the
         CVPixelBuffer, and the CVMTLTexture own this IOSurface. Therefore we must maintain a reference to either
         the pixel buffer or Metal texture until the Metal rendering is done. The MTLCommandBuffer completion
         handler below is then used to release these references.
         */
        pixelBuffers = RenderPixelBuffers(
            foregroundPixelBuffer,
            backgroundTexture: backgroundPixelBuffer,
            destinationTexture: destinationPixelBuffer
        )
        // Create a new command buffer for each renderpass to the current drawable.
        let commandBuffer = commandQueue.makeCommandBuffer()
        /*
         Obtain a drawable texture for this render pass and set up the renderpass
         descriptor for the command encoder to render into.
         */
        let renderPassDescriptor = setupRenderPassDescriptorForTexture(destinationTexture)
        // Create a render command encoder so we can render into something.
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        // Render foreground texture.
        renderTexture(
            renderEncoder!,
            texture: foregroundTexture,
            pipelineState: foregroundRenderPipelineState
        )
        renderEncoder?.setBlendColor(red: 1, green: 1, blue: 1, alpha: tween)

        // Render background texture.
        renderTexture(
            renderEncoder!,
            texture: backgroundTexture,
            pipelineState: backgroundRenderPipelineState
        )

        // We're done encoding commands.
        renderEncoder?.endEncoding()

        // Use the command buffer completion block to release the reference to the pixel buffers.
        commandBuffer?.addCompletedHandler({ _ in
            self.pixelBuffers = nil // Release the reference to the pixel buffers.
        })

        // Finalize rendering here & push the command buffer to the GPU.
        commandBuffer?.commit()
    }
}

// MARK: - Private function
extension APLCrossDissolveRenderer {

    private func setupRenderPassDescriptorForTexture(_ texture: MTLTexture) -> MTLRenderPassDescriptor {
        /*
         MTLRenderPassDescriptor contains attachments that are the rendering destination for pixels
         generated by a rendering pass.
        */
        let renderPassDescriptor = MTLRenderPassDescriptor()

        // Associate the texture object with the attachment.
        renderPassDescriptor.colorAttachments[0].texture = texture
        // Set color to use when the color attachment is cleared.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        return renderPassDescriptor
    }

    private func buildForegroundRenderPipelineState(_ vertexFunction: MTLFunction, fragmentFunction: MTLFunction) throws -> MTLRenderPipelineState {

        // A MTLRenderPipelineDescriptor object that describes the attributes of the render pipeline state.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()

        // A string to help identify this object.
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // Pixel format of the color attachments texture: BGRA.
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    private func buildBackgroundRenderPipelineState(_ vertexFunction: MTLFunction, fragmentFunction: MTLFunction) throws -> MTLRenderPipelineState {

        // A render pipeline descriptor describes the configuration of our programmable pipeline.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()

        // A string to help identify the object.
        pipelineDescriptor.label = "Render Pipeline - Blending"
        // Provide the vertex and shader function and the pixel format to be used.
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // Pixel format of the color attachments texture: BGRA.
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm

        /*
         Enable blending. The blend descriptor property values are then used to determine how source and
         destination color values are combined.
        */
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true

        // Specify custom blend operations to perform the cross dissolve effect.

        // Add portions of both source and destination pixel values.
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        // Use Blend factor of one.
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        // Blend factor of 1- alpha value.
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusBlendAlpha
        // Blend factor of alpha.
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .blendAlpha

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    private func renderTexture(
        _ renderEncoder: MTLRenderCommandEncoder,
        texture: MTLTexture,
        pipelineState: MTLRenderPipelineState
    ) {
        // Set the current render pipeline state object.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Specify vertex, color and texture buffers for the vertex shader function.
        renderEncoder.setVertexBuffer(vertexBuffer, offset:0, index:0)
        renderEncoder.setVertexBuffer(colorBuffer, offset:0, index:1)
        renderEncoder.setVertexBuffer(textureCoordBuffer, offset: 0, index: 2)

        // Set a texture for the fragment shader function.
        renderEncoder.setFragmentTexture(texture, index:0)

        // Tell the render context we want to draw our primitives.
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)
    }
}
