//
//  Gamma.metal
//  ColorForge
//
//  Created by Ben Quinton on 21/08/2025.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Constants

// Constants for Log C encoding
constant float cut = 0.010591;
constant float a = 5.555556;
constant float b = 0.052272;
constant float c = 0.247190;
constant float d = 0.385537;
constant float e = 5.367655;
constant float f = 0.092809;







// MARK: - Functions


inline float3 Lin_to_LogC3(float3 linearRGB) {
    
    // Evaluate both expressions (always computed)
    float3 logPart = c * log10(a * linearRGB + b) + d;
    float3 linPart = e * linearRGB + f;
    
    // Create a mask where linearRGB > cut (1.0 if true, 0.0 if false)
    float3 mask = step(cut, linearRGB);
    
    // Use mix (or equivalent): result = linPart * (1 - mask) + logPart * mask
    float3 logC = mix(linPart, logPart, mask);
    
    return logC;
}

inline float3 LogC3_to_Lin(float3 logC) {

    // Calculate both paths:
    float3 powPart = (pow(10.0, (logC - d) / c) - b) / a;
    float3 linPart = (logC - f) / e;

    // Mask: step(edge, logC), where edge = e * cut + f
    float edge = e * cut + f;
    float3 mask = step(edge, logC);

    // Blend:
    float3 linearRGB = mix(linPart, powPart, mask);
    
    return linearRGB;
}
