//
//  GrainV4.metal
//  ColorForge
//
//  Created by admin on 10/08/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" {



    
    float4 grainMix(coreimage::sample_t s,
                    coreimage::sample_t b1,
                    float fade
                    )
    {
        // Float3 setup
        float3 noise = s.rgb;
        float3 blur = b1.rgb;
        float3 result = float3(0.5);
            
        // First subtract the regular noise from the blur
        // to get the high freq
        float3 delta = blur - noise;
        
        // Then multiply by the fade
        float3 addImage = delta * fade;
        
        // Now add back before repeating
        result = blur + addImage;
            
    
        
        return float4(result, 1.0);
    }
    
    
    float4 maskGrain(coreimage::sample_t g1,
                     coreimage::sample_t g2,
                     coreimage::sample_t g3,
                     coreimage::sample_t p1,
                     coreimage::sample_t p2,
                     coreimage::sample_t p3) {
        float3 grain1 = g1.rgb;
        float3 grain2 = g2.rgb;
        float3 grain3 = g3.rgb;
        float3 perlin1 = p1.rgb;
        float3 perlin3 = p3.rgb;
        
        
        
        float3 grey = float3(0.5);
        
        float maskStrength = 0.33;
        
   
        grain1 = mix(grey, grain1, maskStrength);
        grain2 = mix(grey, grain2, maskStrength);
        grain3 = mix(grey, grain3, maskStrength);

        float3 result = mix(grain1, grain2, perlin1);
//        result = mix(result, grain2, perlin2);
        result = mix(result, grain3, perlin3);
        
        return float4(result, 1.0);
    }
    
    
    
	
}
