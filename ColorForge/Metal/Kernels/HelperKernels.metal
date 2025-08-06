//
//  HelperKernels.metal
//  ColorForge
//
//  Created by admin on 01/06/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "GlobalHelperFunctions.metal"

using namespace metal;



extern "C" {

    constant float arriMidGrey = 0.391;

    inline float arriOverlay(float base, float blend, float pivot) {
        if (base < pivot) {
            return (2.0 * base * blend) / pivot;
        } else {
            return 1.0 - (2.0 * (1.0 - base) * (1.0 - blend)) / (1.0 - pivot);
        }
    }
    
    inline float overlayBlend(float base, float blend, float pivot) {
        if (base < pivot) {
            return (2.0 * base * blend) / pivot;
        } else {
            return 1.0 - (2.0 * (1.0 - base) * (1.0 - blend)) / (1.0 - pivot);
        }
    }

    float4 arriOverlayBlend(coreimage::sample_t s, coreimage::sample_t overlay) {
        float3 base = s.rgb;
        float3 blend = overlay.rgb;
        
        base += 0.5 - arriMidGrey;
        
        float3 result;
        result.r = arriOverlay(base.r, blend.r, 0.5);
        result.g = arriOverlay(base.g, blend.g, 0.5);
        result.b = arriOverlay(base.b, blend.b, 0.5);
        
        result -= 0.5 - arriMidGrey;

        return float4(result, s.a);
    }
    
    inline float arriSoftLight(float base, float blend, float pivot) {
        if (blend < pivot) {
            float scale = (1.0 - (blend / pivot));
            return base - scale * base * (1.0 - base);
        } else {
            float scale = ((blend - pivot) / (1.0 - pivot));
            return base + scale * (sqrt(base) - base);
        }
    }


    
    float4 arriSoftLightBlend(coreimage::sample_t s, coreimage::sample_t overlay) {
        float3 base = s.rgb;
        float3 blend = overlay.rgb;

        base += 0.5 - arriMidGrey;
        
        float3 result;
        result.r = arriSoftLight(base.r, blend.r, 0.5);
        result.g = arriSoftLight(base.g, blend.g, 0.5);
        result.b = arriSoftLight(base.b, blend.b, 0.5);
        
        result -= 0.5 - arriMidGrey;

        return float4(result, s.a);
    }
    
    inline float3 arriSoftLightBlendF3(float3 base, float3 blend) {
        float arriMidtone = 0.396;
        
        base += 0.5 - arriMidtone;
        
        float3 result;
        result.r = arriSoftLight(base.r, blend.r, 0.5);
        result.g = arriSoftLight(base.g, blend.g, 0.5);
        result.b = arriSoftLight(base.b, blend.b, 0.5);
        
        result -= 0.5 - arriMidtone;

        return result;
    }
    
    inline float3 arriOverlayBlendF3(float3 base, float3 blend) {
        float3 result;
        result.r = arriOverlay(base.r, blend.r, 0.5);
        result.g = arriOverlay(base.g, blend.g, 0.5);
        result.b = arriOverlay(base.b, blend.b, 0.5);
        return result;
    }
    
	// MARK: - Blend Kernels
	float4 blendWithOpacity(coreimage::sample_t background, coreimage::sample_t foreground, float opacity) {
		float3 backgroundRGB = float3(background.r, background.g, background.b);
		float3 foregroundRGB = float3(foreground.r, foreground.g, foreground.b);
		float3 mixRGB = float3(0.0, 0.0, 0.0);
		mixRGB = mix(backgroundRGB, foregroundRGB, opacity);
		return float4(mixRGB, background.a);
	}
    
    float4 addTwoImages(coreimage::sample_t x, coreimage::sample_t y) {
        return float4(x.rgb + y.rgb, 1.0);
    }
    
    float4 multiplyTwoImages(coreimage::sample_t x, coreimage::sample_t y) {
        return float4(x.rgb * y.rgb, 1.0);
    }
	
	float4 multiplyByValue(coreimage::sample_t s, float val, int channel) {
		float3 rgb = float3(s.r, s.g, s.b);
		
		if (channel == 0) {
			// Multiply all channels
			return float4(rgb * val, s.a);
		} else if (channel == 1) {
			// Multiply red only
			return float4(rgb.x * val, rgb.y, rgb.z, s.a);
		} else if (channel == 2) {
			// Multiply green only
			return float4(rgb.x, rgb.y * val, rgb.z, s.a);
		} else if (channel == 3) {
			// Multiply blue only
			return float4(rgb.x, rgb.y, rgb.z * val, s.a);
		}
		
		// No change (invalid channel)
		return float4(rgb, s.a);
	}

	float4 scaleWP_BP(coreimage::sample_t s) {
		float3 rgb = float3(s.r, s.g, s.b);
		rgb = rgb * 0.8 + 0.1;
		return float4(rgb, s.a);
	}
	
    
    float4 evenTile(coreimage::sample_t b, coreimage::sample_t t) {
        float3 tile = b.rgb;
        float3 inverted = t.rgb;
        
        tile.x = overlayBlend(tile.x, inverted.x, 0.5);
        tile.y = overlayBlend(tile.y, inverted.y, 0.5);
        tile.z = overlayBlend(tile.z, inverted.z, 0.5);
        
        return float4(tile, b.a);
    }
    
    ///  Params:
    /// s = input image (in log C), gl = Grain Low, gh = Grain High
    
    float4 mixGrainAndApply(coreimage::sample_t s, coreimage::sample_t gL, coreimage::sample_t gH, float amount) {
        float3 grainLow = gL.rgb;
        float3 grainHigh = gH.rgb;
        float3 rgb = s.rgb;
        
        float lum = (s.r + s.g + s.b) / 3.0;
        float3 mask = float3(lum);
        mask = decodeLogCFloat3(mask);
        mask = pow(mask, (1.0 / 2.2));
        mask = clamp(mask, 0.0, 1.0);

        float3 grain = mix(grainLow, grainHigh, mask);
        
        float t = amount / 100.0;
        
        float strength;
        if (t <= 0.5) {
            // Fade out to zero grain below midpoint
            strength = t * 2.0;  // maps 0–0.5 to 0–1
        } else {
            // Exaggerate growth above 50
            float u = (t - 0.5) * 2.0; // maps 0.5–1.0 to 0–1
            strength = 1.0 + pow(u, 2.0) * 3.0; // grows non-linearly up to 4.0
        }

        grain = (grain - 0.5) * strength + 0.5;
        
        float3 result = arriSoftLightBlendF3(rgb, grain);
        
        return float4(result, s.a);
    }

	
}
