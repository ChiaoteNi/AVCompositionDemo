//
//  DissolvedShaders.metal
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

#include <metal_stdlib>
using namespace metal;

// More detail about the Metal Shading Language, you can see here:
// https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf

/*
 Vertex input/output structure for passing results
 from a vertex shader to a fragment shader.
 */
struct VertexInOut
{
    float4 position [[position]];
    float2 foregroundTextureCoord [[user(textureCoord)]];
    float2 backgroundTextureCoord [[user(textureCoord2)]];
};

// Vertex shader
vertex VertexInOut dissolved_vertex_point_func(uint vid [[ vertex_id ]],
                                               constant float4* position [[ buffer(0) ]],
                                               constant packed_float2* foregroundTexCoords [[ buffer(1) ]],
                                               constant packed_float2* backgroundTexCoords [[ buffer(2) ]])
{
    VertexInOut outVertex;
    outVertex.position = position[vid];
    outVertex.foregroundTextureCoord = foregroundTexCoords[vid];
    outVertex.backgroundTextureCoord = backgroundTexCoords[vid];
    return outVertex;
};

// Fragment shader
fragment half4 dissolved_fragment_point_func(VertexInOut fragmentInput [[ stage_in ]],
                                             constant float2& tweenFactor [[ buffer(2) ]],
                                             texture2d<half> foregroundTexture [[texture(0)]],
                                             texture2d<half> backgroundTexture [[texture(1)]])
{
    constexpr sampler sampler;

//    // 1. demo this first to describe how it works
//    if (fragmentInput.foregroundTextureCoord.x > 0.5) {
//        return foregroundTexture.sample(sampler, fragmentInput.foregroundTextureCoord);
//    }

    // 2. then demo this to show how to choose the color from different texture
    int rankX = int(tweenFactor.x * 100);
    int rankY = int(tweenFactor.y * 100);
    int x = int(fragmentInput.foregroundTextureCoord.x * 100);
    int y = int(fragmentInput.foregroundTextureCoord.y * 100);

    // Sample the texture to get the surface color at this point.
    if (x % (rankX) == 0 && y % (rankY) == 0) {
        return foregroundTexture.sample(sampler, fragmentInput.foregroundTextureCoord);
    }
    return backgroundTexture.sample(sampler, fragmentInput.backgroundTextureCoord);
}
