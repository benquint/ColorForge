//
//  Histogram.metal
//  ColorForge
//
//  Created by Ben Quinton on 04/08/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "GlobalHelperFunctions.metal"

using namespace metal;


extern "C" {
    
    

    
    float4 histogram(coreimage::sampler src, float bins) {
        float2 coord = src.coord();
        float2 imageSize = src.size();
        
        float3 rgb = sample(src, coord).rgb;
        


        // If the pixel itself is outside the image, output transparent
        if (coord.x < 0.0f || coord.y < 0.0f || coord.x >= imageSize.x || coord.y >= imageSize.y) {
            return float4(0.0, 0.0, 0.0, 0.0); // Transparent
        }
        
        return float4(rgb, 1.0);
    }
 
}

