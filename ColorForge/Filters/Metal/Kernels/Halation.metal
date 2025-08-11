//
//  Halation.metal
//  ColorForge
//
//  Created by Ben Quinton on 24/07/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "GlobalHelperFunctions.metal"

using namespace metal;


extern "C" {
	
	
	// MARK: - Blur
	
	inline float exp_k(float x, float y, float r0) {
		return exp(-sqrt(x*x + y*y) / r0);
	}
	
	inline float4 exp_blur(coreimage::sampler src, float size) {
		int radius = ceil(4.5f * size);
		float3 sum = float3(0.0f);
		float weight_sum = 0.0f;

		float2 coord = src.coord();                // Current pixel coordinate
		float2 imageSize = src.size();         // Size in pixels

		for (int i = -radius; i <= radius; i++) {
			for (int j = -radius; j <= radius; j++) {
				float2 uv = coord + float2(i, j);

				// Skip sampling outside the image entirely
				if (uv.x < 0.0f || uv.y < 0.0f || uv.x >= imageSize.x || uv.y >= imageSize.y) {
					continue;
				}

				float weight = exp_k(i, j, size);
				float3 rgb = sample(src, uv).rgb;
				sum += weight * rgb;
				weight_sum += weight;
			}
		}

		// Normalize if we accumulated any weights
		float3 blurred_rgb = (weight_sum > 0.0f) ? (sum / weight_sum) : float3(0.0f);

		return float4(blurred_rgb, 1.0);
	}
	
	
	inline float4 exp_blur_linear(coreimage::sampler src, float size) {
		int radius = ceil(4.5f * size);
		float3 sum = float3(0.0f);
		float weight_sum = 0.0f;

		float2 coord = src.coord();                // Current pixel coordinate
		float2 imageSize = src.size();         // Size in pixels

		for (int i = -radius; i <= radius; i++) {
			for (int j = -radius; j <= radius; j++) {
				float2 uv = coord + float2(i, j);

				// Skip sampling outside the image entirely
				if (uv.x < 0.0f || uv.y < 0.0f || uv.x >= imageSize.x || uv.y >= imageSize.y) {
					continue;
				}

				float weight = exp_k(i, j, size);
				float3 rgb = sample(src, uv).rgb;
				rgb = pow(rgb, 2.2f);
				
				sum += weight * rgb;
				weight_sum += weight;
			}
		}

		// Normalize if we accumulated any weights
		float3 blurred_rgb = (weight_sum > 0.0f) ? (sum / weight_sum) : float3(0.0f);
		blurred_rgb = pow(blurred_rgb, 1.0f / 2.2f);

		return float4(blurred_rgb, 1.0);
	}
	
	
	// MARK: - Halation
    

    float4 halationV2(coreimage::sampler src, float size, int method) {
        float2 coord = src.coord();
        float2 imageSize = src.size();



        float3 rgb = sample(src, coord).rgb;

        if (size < 1e-10) return float4(rgb, 1.0);

        float3 blurred = exp_blur(src, size).rgb;
        float3 result, color, halated;

        switch (method) {
            case 0:
                color = float3(1.0, 0.2, 0.0);
                halated = rgb + (blurred * color);
                result = halated / (color + 1.0f);
                break;

            case 1:
                color = float3(0.7f, 1.0f - 0.2 / 3.0f, 1.0f);
                halated = (rgb - blurred) * color;
                result = halated + blurred;
                break;
        }

        // If the pixel itself is outside the image, output transparent
        if (coord.x < 0.0f || coord.y < 0.0f || coord.x >= imageSize.x || coord.y >= imageSize.y) {
            return float4(0.0, 0.0, 0.0, 0.0); // Transparent
        }
        
        return float4(result, 1.0);
    }
    
    /*
     float3 rgb = _sample(p_TexR, p_TexG, p_TexB, p_X, p_Y);

     float lum = (rgb.x + rgb.y + rgb.z) / 3.0f;

     if (SIZE < 1e-10) return rgb;

     float3 blurred = exp_blur(p_TexR, p_TexG, p_TexB, p_X, p_Y, SIZE);
     float3 result, color, halatedDark, halatedNorm, mixed;

     switch (METHOD) {
     case PROOSA:
         color = make_float3(1.0f, COLOR, 0.0f);
         halatedDark = rgb + (blurred * COLOR);
         halatedNorm = halatedDark / (COLOR + 1.0f);
         result = _mix(halatedNorm, halatedDark, lum);
     */
	
	
    float4 printHalation(coreimage::sampler src, float size, float amount, int applyDarkening) {
		float2 coord = src.coord();
		float2 imageSize = src.size();
		
		float3 rgb = sample(src, coord).rgb;

		if (size < 1e-10) return float4(rgb, 1.0);

		float3 blurred = exp_blur_linear(src, size).rgb;
        float3 result, halatedDark, halatedNorm;
        float avg = (rgb.x + rgb.y + rgb.z) / 3.0f;
        avg = pow(avg, 2.2f);

        halatedDark = rgb + (blurred * amount);
        halatedNorm = halatedDark / (amount + 1.0f);
        
        switch (applyDarkening) {
            case 0:
                result = mix(halatedNorm, halatedDark, pow(rgb, 1.0f / 2.2f));
                break;

            case 1:
                result = halatedNorm;
                break;
        }
        


		// If the pixel itself is outside the image, output transparent
		if (coord.x < 0.0f || coord.y < 0.0f || coord.x >= imageSize.x || coord.y >= imageSize.y) {
			return float4(0.0, 0.0, 0.0, 0.0); // Transparent
		}
		
		return float4(blurred, 1.0);
	}
    
    
    float4 printHalationV2(coreimage::sample_t s, coreimage::sample_t b, float amount, int applyDarkening) {
        float3 rgb = s.rgb;
        float3 blurred = b.rgb;
        
        float3 result, halatedDark, halatedNorm;
        float avg = (rgb.x + rgb.y + rgb.z) / 3.0f;
        avg = pow(avg, 2.2f);
        
        halatedDark = rgb + (blurred * amount);
        halatedNorm = halatedDark / (amount + 1.0f);
        
        
        switch (applyDarkening) {
            case 0:
                result = mix(halatedNorm, halatedDark, pow(rgb, 1.0f / 2.2f));
                break;

            case 1:
                result = halatedNorm;
                break;
        }
        
        
        return float4(result, 1.0);
    }
    
}
