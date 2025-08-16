//
//  EdgeAwareFilter.metal
//  ColorForge
//
//  Created by Ben Quinton on 08/08/2025.
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
    
    
    inline float sigmoid_lab(float t) {
        float softness = 10.0;
        
        // Base sigmoid
        float s = 1.0 / (1.0 + exp(-softness * (t - 0.5)));

        // Normalize to 0–1
        float s0 = 1.0 / (1.0 + exp(-softness * (0.0 - 0.5)));
        float s1 = 1.0 / (1.0 + exp(-softness * (1.0 - 0.5)));
        float norm = (s - s0) / (s1 - s0);


        // Apply gamma to the normalized sigmoid
        return norm;
    }
    
    
    // Accepts:
    //
    // s  = Source
    // m  = Mask as is
    // mb = Mask blurred (for larger area than original mask
    // sp = Source average pixel in RGB
    // mp = Masked area average pixel in RGB
    
    float4 edgeAwareFilter(coreimage::sample_t s, coreimage::sample_t m, coreimage::sample_t mb, coreimage::sample_t sp, coreimage::sample_t mp) {

        
        // ***** Variable Setup ***** //
        
        // Image
        float3 rgb = s.rgb;
        float3 labSrc = adobeEncodedToLab(rgb);
        
        // Mask = Single float as black and white
        float maskNorm = m.g;
        float maskBlurred = mb.g;
        float mask = maskBlurred - maskNorm; // Only the areas greater than the original
        mask = clamp(mask, 0.0, 1.0);
        
        // Background and foreground averaged pixels in RGB
        float3 bgPixel = sp.rgb;
        float3 fgPixel = mp.rgb;
        
        
        
        // ***** Lab calculations ***** //
        
        // Convert pixels to lab
        bgPixel = adobeEncodedToLab(bgPixel);
        fgPixel = adobeEncodedToLab(fgPixel);
        
        float feather = 1.2;
        
        // Find min / max values for both
        float L_max = (max(bgPixel.x, fgPixel.x)) * feather;
        float L_min = (min(bgPixel.x, fgPixel.x)) / feather;
        float A_max = (max(bgPixel.y, fgPixel.y)) * feather;
        float A_min = (min(bgPixel.y, fgPixel.y)) / feather;
        float B_max = (max(bgPixel.z, fgPixel.z)) * feather;
        float B_min = (min(bgPixel.z, fgPixel.z)) / feather;
        
        
        
        // ***** Clamp input to min / max ***** //
        
        labSrc.x = clamp(labSrc.x, L_min, L_max);
        labSrc.y = clamp(labSrc.y, A_min, A_max);
        labSrc.z = clamp(labSrc.z, B_min, B_max);
        
        
        // Apply Sigmoid curve
        labSrc.x = sigmoid_lab(labSrc.x);
        labSrc.y = sigmoid_lab(labSrc.y);
        labSrc.z = sigmoid_lab(labSrc.z);
        
        
        // Average the pixels to get a single float
        float labMask = (labSrc.x + labSrc.y + labSrc.z) / 3.0;
        
        // Now mix onto black, using the subtracted mask as mix
        float finalMask = mix(0.0, labSrc.x, mask);
        
        // Finally mix with the original mask (which may already be feathered)
        // to limit it to just the featheered areas
        finalMask = mix(0.0, finalMask, maskNorm);
        
        
        finalMask = clamp(finalMask, 0.0, 1.0);
        
        
        return float4(finalMask, finalMask, finalMask, 1.0);
    }
    
    
    
    // Chat GPT idea
    
    // Map normalized Lab (0..1) back to standard Lab for ΔE math
    inline float3 denormLab(float3 labNorm) {
        return float3(
            labNorm.x * 100.0f,
            labNorm.y * 255.0f - 128.0f,
            labNorm.z * 255.0f - 128.0f
        );
    }

    // Simple ΔE76 between normalized Lab triplets
    inline float deltaE76_norm(float3 labNormA, float3 labNormB) {
        float3 A = denormLab(labNormA);
        float3 B = denormLab(labNormB);
        float3 d = A - B;
        return length(d);
    }
//
//    // Optional: a mild sigmoid for Lab channels if you still want it
//    inline float sigmoid_lab(float x, float k, float x0) {
//        // logistic centered at x0 in 0..1
//        return 1.0f / (1.0f + exp(-k * (x - x0)));
//    }
//
//    float4 edgeAwareFilter(coreimage::sample_t s,
//                           coreimage::sample_t m,
//                           coreimage::sample_t mb,
//                           coreimage::sample_t sp,
//                           coreimage::sample_t mp)
//    {
//        // ---- Inputs ----
//        float3 rgb          = s.rgb;   // assumed AdobeRGB-encoded
//        float  maskNorm     = m.g;
//        float  maskBlurred  = mb.g;
//
//        // Edge band: only where blurred mask extends beyond the hard mask
//        float edgeBand = clamp(maskBlurred - maskNorm, 0.0f, 1.0f);
//
//        // Convert source / bg / fg to normalized Lab (0..1) using your helpers
//        float3 labSrc = adobeEncodedToLab(rgb);
//        float3 labBG  = adobeEncodedToLab(sp.rgb);
//        float3 labFG  = adobeEncodedToLab(mp.rgb);
//
//        // ---- ΔE-based affinities ----
//        // Distances in perceptual space
//        float dBG = deltaE76_norm(labSrc, labBG);
//        float dFG = deltaE76_norm(labSrc, labFG);
//
//        // Convert distances to affinities. Smaller distance => larger affinity.
//        // sigma sets how quickly affinity falls off with ΔE.
//        const float sigma = 5.0f; // ΔE units; tune 3..10 depending on your content
//        float inv2s2 = 1.0f / (2.0f * sigma * sigma);
//        float aBG = exp(-(dBG * dBG) * inv2s2);
//        float aFG = exp(-(dFG * dFG) * inv2s2);
//
//        // Normalize affinities; wFG ~ probability this pixel belongs to FG color
//        float sum = aBG + aFG + 1e-6f;
//        float wFG = aFG / sum;
//
//        // Optional: emphasize the edge band with a soft ramp and a power
//        float edge = smoothstep(0.0f, 1.0f, edgeBand);
//        edge = pow(edge, 0.8f); // slightly widen effective band
//
//        // Optional: nonlinearity on Lab L/a/b before reducing (gentle contrast)
//        // (Leave these off if you don't want any curve shaping.)
//        // labSrc.x = sigmoid_lab(labSrc.x, 10.0f, 0.5f);
//        // labSrc.y = sigmoid_lab(labSrc.y, 10.0f, 0.5f);
//        // labSrc.z = sigmoid_lab(labSrc.z, 10.0f, 0.5f);
//
//        // Final mask logic:
//        // - Start from 0 in edge ring, rise toward 1 by how FG-like the pixel is.
//        // - Confine to the ring via `edge`.
//        float edgeMask = mix(0.0f, wFG, edge);
//
//        // Combine with the original mask to respect any base feather you already have.
//        // This limits the effect to the original mask's support.
//        float finalMask = mix(0.0f, edgeMask, maskNorm);
//
//        finalMask = clamp(finalMask, 0.0f, 1.0f);
//        return float4(finalMask, finalMask, finalMask, 1.0f);
//    }
//    
    
    
    
}
