//
//  Texture.metal
//  ColorForge
//
//  Created by Ben Quinton on 21/08/2025.
//

#include <metal_stdlib>
using namespace metal;


inline float cubicWeight(float x) {
    x = abs(x);
    if (x <= 1.0) {
        return (-2.0 * x*x*x + 3.0 * x*x + 1.0);
    } else if (x <= 2.0) {
        return (-1.0 * x*x*x + 5.0 * x*x - 8.0 * x + 4.0);
    }
    return 0.0;
}

inline float3 sampleBicubic(texture2d<float, access::read> tex, float2 coord) {
    float2 texSize = float2(tex.get_width(), tex.get_height());
    float2 pixelCoord = coord * texSize - 0.5;
    int2 center = int2(floor(pixelCoord));
    float2 f = fract(pixelCoord);
    
    float3 result = float3(0.0);
    float weightSum = 0.0;
    
    // 4x4 kernel for bicubic
    for (int y = -1; y <= 2; y++) {
        for (int x = -1; x <= 2; x++) {
            int2 samplePos = clamp(center + int2(x, y), int2(0), int2(texSize) - 1);
            float2 offset = float2(x, y) - f;
            
            float weight = cubicWeight(offset.x) * cubicWeight(offset.y);
            result += tex.read(uint2(samplePos)).rgb * weight;
            weightSum += weight;
        }
    }
    
    return result / weightSum;
}

inline float3 downsampleAndUpsample(texture2d<float, access::read> tex, uint2 gid, float downsampleFactor) {
    float2 texSize = float2(tex.get_width(), tex.get_height());
    float2 normalizedCoord = float2(gid) / texSize;
    
    // Downsample coordinates
    float2 downsampledCoord = normalizedCoord * downsampleFactor;
    
    // Sample at the downsampled position using bicubic for smoothness
    float3 downsampledPixel = sampleBicubic(tex, downsampledCoord);
    
    return downsampledPixel;
}
