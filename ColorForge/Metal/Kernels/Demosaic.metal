//
//  Demosaic.metal
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "GlobalHelperFunctions.metal"
using namespace metal;

extern "C" {
    
    
    // MARK: - Boiler plate kernels
    
    /*
     
     float4 name(coreimage::sample_t s) {
     float3 rgb = float3(s.r, s.g, s.b);
     
     
     return float4(rgb, s.a);
     }
     
     */
    
    enum FilterColor {
        FilterColor_R = 0,
        FilterColor_G = 1,
        FilterColor_B = 2
    };

    inline int get_filter_color(float2 xy) {
        int x = int(xy.x);
        int y = int(xy.y);
        
        bool isEvenX = (x % 2 == 0);
        bool isEvenY = (y % 2 == 0);

        if (isEvenX) {
            return isEvenY ? FilterColor_R : FilterColor_G;
        } else {
            return isEvenY ? FilterColor_G : FilterColor_B;
        }
    }
    
 
    // MARK: - Bilinear
    // Assume a pattern of RGGB for now
        // Main bilinear demosaic kernel
        float4 bilinearDemosaic(coreimage::sampler src) {
            float2 coord = src.coord();

            // Subtract the origin offset
            float2 baseOffset = float2(-2, -2); // Match whatever you inset by
            float2 adjustedCoord = coord - baseOffset;

            int x = adjustedCoord.x;
            int y = adjustedCoord.y;

            int fc = get_filter_color(float2(x, y)); // Now gives correct color

            float R = 0.0;
            float G = 0.0;
            float B = 0.0;

            // Read current pixel
            float center = sample(src, coord).r;

            if (fc == FilterColor_R) {
                R = center;

                // G: horizontal and vertical neighbors
                G = 0.25 * (
                    sample(src, coord + float2(-1,  0)).r +
                    sample(src, coord + float2( 1,  0)).r +
                    sample(src, coord + float2( 0, -1)).r +
                    sample(src, coord + float2( 0,  1)).r
                );

                // B: diagonal neighbors
                B = 0.25 * (
                    sample(src, coord + float2(-1, -1)).r +
                    sample(src, coord + float2(-1,  1)).r +
                    sample(src, coord + float2( 1, -1)).r +
                    sample(src, coord + float2( 1,  1)).r
                );

            } else if (fc == FilterColor_B) {
                B = center;

                // G: horizontal and vertical neighbors
                G = 0.25 * (
                    sample(src, coord + float2(-1,  0)).r +
                    sample(src, coord + float2( 1,  0)).r +
                    sample(src, coord + float2( 0, -1)).r +
                    sample(src, coord + float2( 0,  1)).r
                );

                // R: diagonal neighbors
                R = 0.25 * (
                    sample(src, coord + float2(-1, -1)).r +
                    sample(src, coord + float2(-1,  1)).r +
                    sample(src, coord + float2( 1, -1)).r +
                    sample(src, coord + float2( 1,  1)).r
                );

            } else { // Green pixel
                G = center;

                bool isEvenY = (y % 2 == 0);

                if (isEvenY) {
                    // Green pixel on red row
                    R = 0.5 * (
                        sample(src, coord + float2(-1, 0)).r +
                        sample(src, coord + float2( 1, 0)).r
                    );

                    B = 0.5 * (
                        sample(src, coord + float2( 0, -1)).r +
                        sample(src, coord + float2( 0,  1)).r
                    );

                } else {
                    // Green pixel on blue row
                    R = 0.5 * (
                        sample(src, coord + float2( 0, -1)).r +
                        sample(src, coord + float2( 0,  1)).r
                    );

                    B = 0.5 * (
                        sample(src, coord + float2(-1, 0)).r +
                        sample(src, coord + float2( 1, 0)).r
                    );
                }
            }

            // Optional: gamma correction (for display/debug only)
            R = pow(R, 1.0 / 2.2);
            G = pow(G, 1.0 / 2.2);
            B = pow(B, 1.0 / 2.2);

            return float4(R, G, B, 1.0);
        }
    
    
    
    
}
