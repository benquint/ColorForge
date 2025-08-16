//
//  VectorScope.metal
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "GlobalHelperFunctions.ci.metal"

using namespace metal;

extern "C" {
    
    
    // MARK: - Boiler plate kernels
    
    /*
     
     float4 name(coreimage::sample_t s) {
     float3 rgb = float3(s.r, s.g, s.b);
     
     
     return float4(rgb, s.a);
     }
     
     */
    
    // MARK: - YUV Float 4
    
    constant float uScale = 1.14678899;
    constant float vScale = 0.81300813;
    
    // Float 4
    float4 RGBtoYUV(coreimage::sample_t s) {
        float3 rgb = float3(s.r, s.g, s.b);
        
        // Matrix from RGB to YUV (from screenshot 1)
        float3x3 rgbToYuv = float3x3(
                                     float3( 0.299,  0.587,  0.114),
                                     float3(-0.147, -0.289,  0.436),
                                     float3( 0.615, -0.515, -0.100)
                                     );
        
        float3 yuv = applyMatrix(rgb, rgbToYuv);
        
        // Next - Normalise the U value which are currently in a range of
        // -0.436 to 0.436 (0.872 span)
        yuv.y += 0.436;
        yuv.y *= uScale;
        
        // Next - Normalise the V values which are currently in a range of
        // -0.615 to 0.615 (1.23 span)
        yuv.z += 0.615;
        yuv.z *= vScale;
        
        return float4(yuv, s.a);
    }
    
    float4 YUVtoRGB(coreimage::sample_t s) {
        float3 yuv = float3(s.r, s.g, s.b);
        
        // First undo normalisation
        yuv.y -= 0.436;
        yuv.y /= uScale;
        
        yuv.z -= 0.615;
        yuv.z /= vScale;
        
        // Matrix from YUV to RGB (from screenshot 2)
        float3x3 yuvToRgb = float3x3(
                                     float3(1.000,  0.000,  1.140),
                                     float3(1.000, -0.395, -0.581),
                                     float3(1.000,  2.032,  0.000)
                                     );
        
        float3 rgb = applyMatrix(yuv, yuvToRgb);
        return float4(rgb, s.a);
    }
    
    
    float4 UVtoRGB(coreimage::sample_t s) {
        float2 uv = s.yz;
        float y = s.x;
        y = mix(y, 0.5, 0.3);
        
        float3 yuv = float3(y, uv.x, uv.y);
        
        // First undo normalisation
        yuv.y -= 0.436;
        yuv.y /= uScale;
        
        yuv.z -= 0.615;
        yuv.z /= vScale;
        
        // Matrix from YUV to RGB (from screenshot 2)
        float3x3 yuvToRgb = float3x3(
                                     float3(1.000,  0.000,  1.140),
                                     float3(1.000, -0.395, -0.581),
                                     float3(1.000,  2.032,  0.000)
                                     );
        
        float3 rgb = applyMatrix(yuv, yuvToRgb);
        return float4(rgb, s.a);
    }
    
    
    // MARK: - YUV Float3
    
    // Float 4
    float3 RGBtoYUVF3(float3 rgb) {
        
        // Matrix from RGB to YUV (from screenshot 1)
        float3x3 rgbToYuv = float3x3(
                                     float3( 0.299,  0.587,  0.114),
                                     float3(-0.147, -0.289,  0.436),
                                     float3( 0.615, -0.515, -0.100)
                                     );
        
        float3 yuv = applyMatrix(rgb, rgbToYuv);
        
        // Next - Normalise the U value which are currently in a range of
        // -0.436 to 0.436 (0.872 span)
        yuv.y += 0.436;
        yuv.y *= uScale;
        
        // Next - Normalise the V values which are currently in a range of
        // -0.615 to 0.615 (1.23 span)
        yuv.z += 0.615;
        yuv.z *= vScale;
        
        return yuv;
    }
    
    float3 YUVtoRGBF3(float3 yuv) {

        
        // First undo normalisation
        yuv.y -= 0.436;
        yuv.y /= uScale;
        
        yuv.z -= 0.615;
        yuv.z /= vScale;
        
        // Matrix from YUV to RGB (from screenshot 2)
        float3x3 yuvToRgb = float3x3(
                                     float3(1.000,  0.000,  1.140),
                                     float3(1.000, -0.395, -0.581),
                                     float3(1.000,  2.032,  0.000)
                                     );
        
        float3 rgb = applyMatrix(yuv, yuvToRgb);
        return rgb;
    }
    
    
    
    // MARK: - Draw Circle

    
    float4 drawcircleFilter(float2 fragCoord, float2 circleCenter, float radiusPx, float4 circleColor, float4 bgColor) {
        float dist = distance(fragCoord, circleCenter);
        
        // Soften the edge over 1 pixel using smoothstep
        float alpha = 1.0 - smoothstep(radiusPx - 1.0, radiusPx + 1.0, dist);
        
        // Blend the white circle over the background using alpha
        return mix(bgColor, circleColor, alpha);
    }

    
}
