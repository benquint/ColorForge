//
//  Helpers.metal
//  ColorForge
//
//  Created by Ben Quinton on 21/08/2025.
//

#include <metal_stdlib>
using namespace metal;


inline float bellCurve(float in, float center, float width) {
    float distance = abs(in - center);
    float exponent = - pow(distance, 2) / pow(width, 2);
    return exp(exponent);
}

// A bell curve that loops around the edges, great for hue selection
inline float bellCurveLooping(float in, float center, float width) {
    float curve = bellCurve(in, center, width);
    float startCurve = bellCurve(in, center-1, width);
    float endCurve = bellCurve(in, center+1, width);
    
    return fmax(fmax(curve, startCurve), endCurve);
}
