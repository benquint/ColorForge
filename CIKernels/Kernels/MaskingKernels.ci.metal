//
//  MaskingKernels.metal
//  ColorForge
//
//  Created by admin on 23/05/2025.
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
	
	// MARK: - Constants
	constant float printCurve[32][3] = {
		{0.9137254902, 0.9137254902, 0.9137160433},
		{0.9137254902, 0.9137251008, 0.9132164287},
		{0.9137254902, 0.9136863092, 0.9065719407},
		{0.9137254902, 0.9127539646, 0.8690264908},
		{0.9137248995, 0.9037319907, 0.7612881037},
		{0.9136952338, 0.8633435192, 0.5822429465},
		{0.9131453779, 0.7671307204, 0.3835657605},
		{0.9085740807, 0.6215398499, 0.2221173575},
		{0.8890990171, 0.4559826974, 0.1267670173},
		{0.8402518349, 0.3020768924, 0.0835366824},
		{0.7569793280, 0.1854755668, 0.0684758157},
		{0.6440434789, 0.1139494993, 0.0640181297},
		{0.5138248164, 0.0799506500, 0.0629191631},
		{0.3953151219, 0.0676461981, 0.0627563642},
		{0.2981979460, 0.0638404663, 0.0627453858},
		{0.2110902388, 0.0628931690, 0.0627450980},
		{0.1411527197, 0.0627545404, 0.0627450980},
		{0.1002665023, 0.0627453351, 0.0627450980},
		{0.0810581272, 0.0627450980, 0.0627450980},
		{0.0718593436, 0.0627450980, 0.0627450980},
		{0.0671789120, 0.0627450980, 0.0627450980},
		{0.0646138308, 0.0627450980, 0.0627450980},
		{0.0632616679, 0.0627450980, 0.0627450980},
		{0.0628179136, 0.0627450980, 0.0627450980},
		{0.0627495474, 0.0627450980, 0.0627450980},
		{0.0627451996, 0.0627450980, 0.0627450980},
		{0.0627450980, 0.0627450980, 0.0627450980},
		{0.0627450980, 0.0627450980, 0.0627450980},
		{0.0627450980, 0.0627450980, 0.0627450980},
		{0.0627450980, 0.0627450980, 0.0627450980},
		{0.0627450980, 0.0627450980, 0.0627450980},
		{0.0627450980, 0.0627450980, 0.0627450980}
	};
	
	
	// Enlarger inverse curve
	constant float enlargerInverse[32][3] = {
		{0.000000, 0.000000, 0.000000},
		{0.000000, 0.000000, 0.000000},
		{0.000000, 0.000000, 0.000000},
		{0.096881, 0.096881, 0.096881},
		{0.129881, 0.129881, 0.129881},
		{0.152650, 0.152650, 0.152650},
		{0.171087, 0.171087, 0.171087},
		{0.186978, 0.186978, 0.186978},
		{0.201432, 0.201432, 0.201432},
		{0.214731, 0.214731, 0.214731},
		{0.227460, 0.227460, 0.227460},
		{0.239698, 0.239698, 0.239698},
		{0.251612, 0.251612, 0.251612},
		{0.263576, 0.263576, 0.263576},
		{0.275447, 0.275447, 0.275447},
		{0.287511, 0.287511, 0.287511},
		{0.299986, 0.299986, 0.299986},
		{0.312824, 0.312824, 0.312824},
		{0.326400, 0.326400, 0.326400},
		{0.340843, 0.340843, 0.340843},
		{0.356429, 0.356429, 0.356429},
		{0.373616, 0.373616, 0.373616},
		{0.392653, 0.392653, 0.392653},
		{0.414189, 0.414189, 0.414189},
		{0.438285, 0.438285, 0.438285},
		{0.464911, 0.464911, 0.464911},
		{0.493866, 0.493866, 0.493866},
		{0.525343, 0.525343, 0.525343},
		{0.561281, 0.561281, 0.561281},
		{0.609243, 0.609243, 0.609243},
		{1.000000, 1.000000, 1.000000},
		{1.000000, 1.000000, 1.000000}
	};
	
	
	inline float3 overlay(float3 background, float3 blend) {
		return mix(
				   2.0 * background * blend,
				   1.0 - 2.0 * (1.0 - background) * (1.0 - blend),
				   step(0.5, blend)
				   );
	}
	
	// Expects black and white mask image
	float4 ditherMask(coreimage::sample_t s, coreimage::destination dest) {
		float value = fract(sin(dot(dest.coord() / 1000,
									float2(12.9898, 78.233))) * 43758.5453);
		float3 noise = float3(value, value, value);
		float3 grey = float3(0.5, 0.5, 0.5);
		noise = mix(grey, noise, 0.1);
		
		float3 rgb = s.rgb;
		float3 noiseApplied = overlay(rgb, noise);
		
		float mask = s.r; // linear grayscale mask
		float weight = bellCurve(mask, 0.5, 0.5);
		rgb = mix(rgb, noiseApplied, weight);
		
		return float4(rgb, s.a);
	}
	
	float4 softenMask(coreimage::sample_t s) {
		float3 rgb = float3(s.r, s.g, s.b);
		float softness = 4.0;
		
		rgb = log(1.0 + softness * rgb) / log(1.0 + softness);
		
		return float4(rgb, s.a);
	}
	
	float4 blendWithMaskMetal(coreimage::sample_t b, coreimage::sample_t f, coreimage::sample_t m, float width, float height, coreimage::destination dest){
		float3 base = b.rgb;
		float3 foreground = f.rgb;
		float3 mask = m.rgb;
		
		float3 masked = mix(base, foreground, mask);
		
		// Clamp Coords
		float2 coord = dest.coord();
		if (coord.x < 0.0 || coord.x >= width || coord.y < 0.0 || coord.y >= height) {
			return float4(0.0);              // Transparent outside the extent
		}
		
		return float4(masked, 1.0);
	}
	
	
	// MARK: - Mask Gamma Corrections
	
	float4 linearGamma(coreimage::sample_t s) {
		float3 rgb = float3(s.r, s.g, s.b);
		
		rgb = mapRGB32(rgb, enlargerInverse);
		
		return float4(rgb, s.a);
	}
	
	float4 enlargerGamma(coreimage::sample_t s) {
		float3 rgb = float3(s.r, s.g, s.b);
		
		rgb = mapRGB32(rgb, enlargerInverse);
		
		return float4(rgb, s.a);
	}
	
	
	// MARK: - Gradient kernels
	
	inline float sigmoidT(float t) {
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
	
	float4 linearGradientMetalRawExposure(
		coreimage::sampler src,
		coreimage::sampler top,
		float startX, float startY,
		float endX, float endY)
	{
		float width = src.size().x;
		float height = src.size().y;

		float2 start = float2(startX, startY);
		float2 end = float2(endX, endY);
		float2 uv = src.coord();

		// Check if the pixel is outside before computing anything
		bool outside = (uv.x < 0.0f || uv.x >= width || uv.y < 0.0f || uv.y >= height);
		
		uv.x = clamp(0.0, width, uv.x);
		uv.y = clamp(0.0, height, uv.y);

		// Sample images (Core Image will clamp if needed)
		float3 baseRgb = sample(src, uv).rgb;
		float3 blendRgb = sample(top, uv).rgb;

		// Compute gradient factor only if inside
		float t = 0.0f;
		if (!outside) {
			float2 dir = end - start;
			float len = length(dir);
			float2 dirNorm = (len > 0.0f) ? (dir / len) : float2(0.0);
			float proj = dot(uv - start, dirNorm);
			t = clamp(proj / len, 0.0f, 1.0f);
			t = sigmoidT(t);
		}

		// Blend
		float3 result = mix(blendRgb, baseRgb, t);

		// If outside, make fully transparent
		float alpha = outside ? 0.0f : 1.0f;

		return float4(result, alpha);
	}
	
	
	float4 applySigmoidSmoothing(coreimage::sample_t s) {
		float mask = s.g;
		
		mask = sigmoidT(mask);
		
		return float4(mask, mask, mask, 1.0);
	}
	
	
	float4 createBorder(coreimage::sample_t s, float maskedOriginX, float maskOriginY, float maskedWidth, float maskedHeight, coreimage::destination dest) {

		float2 maskedOrigin = float2(maskedOriginX, maskOriginY);
		float2 maskedSize = float2(maskedWidth, maskedHeight);
		
		float2 uv = dest.coord();
		
		// Rectangle bounds
		float2 minBound = maskedOrigin;
		float2 maxBound = maskedOrigin + maskedSize;

		// Check if this pixel is inside the masked rectangle
		bool inside = (uv.x >= minBound.x && uv.x <= maxBound.x &&
					   uv.y >= minBound.y && uv.y <= maxBound.y);

		if (inside) {
			// Return fully transparent black
			return float4(0.0, 0.0, 0.0, 0.0);
		} else {
			// Return the original pixel
			return float4(s.rgb, 1.0);
		}
	}
    
    
    // MARK: - Sam
    
    float4 addMask(coreimage::sample_t s, coreimage::sample_t b) {
        float3 sum = clamp(0.0, 1.0, s.rgb + b.rgb);
        return float4(sum, 1.0);
    }
    
    
    float4 subtractMask(coreimage::sample_t s, coreimage::sample_t b) {
        float3 sum = clamp(0.0, 1.0, s.rgb - b.rgb);
        return float4(sum, 1.0);
    }
	
}

