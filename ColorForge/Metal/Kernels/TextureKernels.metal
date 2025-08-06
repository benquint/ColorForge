//
//  TextureKernels.metal
//  ColorForge
//
//  Created by admin on 23/05/2025.
//


#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

extern "C" {
	
	
	// MARK: - Boiler plate kernels
	
	/*
	 
	 float4 name(coreimage::sample_t s) {
		 float3 rgb = float3(s.r, s.g, s.b);
		 
		 
		 return float4(rgb, s.a);
	 }
	 
	 */
	
    float4 blendPaper(coreimage::sample_t b, coreimage::sample_t s, coreimage::sample_t m, coreimage::sample_t x, int convertToNeg) {
        float3 base = b.rgb;
        float3 shrunk = s.rgb;
        float3 mask = m.rgb;
        float3 blurred = x.rgb;
        
        // if true
        if (convertToNeg == 1) {
            base = 1.0 - base;
            base += blurred * 0.1;
        } else {
            base -= blurred * 0.3;
        }
        
        mask = (mask * 1.2) - 0.2; // increase contrast
        mask = clamp(mask, 0.0, 1.0);
        
        float3 final = mix(base, shrunk, mask);
        
        
        
        return float4(final, s.a);
    }
    
    
}

