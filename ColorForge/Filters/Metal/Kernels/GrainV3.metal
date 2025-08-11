//
//  GrainV3.metal
//  ColorForge
//
//  Created by admin on 21/07/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;


/*
 
 Possibly vectorise for GPU efficiency.
 
 
 Step 1: We divide the image into cells based on size (width x height)
 
 Step 2: Le
 
 
 */

extern "C" {
	
	// Gaussian PDF for weighting offsets
	inline float gaussianPDF(float2 offset, float sigma) {
		float norm2 = dot(offset, offset);
		return (1.0 / (2.0 * M_PI_F * sigma * sigma)) * exp(-norm2 / (2.0 * sigma * sigma));
	}

	
	// Simple hash-based RNG (repeatable per cell + iteration)
	inline float randHash(uint seed) {
		seed = (seed ^ 61u) ^ (seed >> 16);
		seed *= 9u;
		seed = seed ^ (seed >> 4);
		seed *= 0x27d4eb2du;
		seed = seed ^ (seed >> 15);
		return float(seed & 0xFFFFFF) / float(0x1000000);
	}
	
	// Deterministic random float [0,1] based on cell coordinate and sequence index
	inline float cellRandom(uint2 cell, uint seq, uint globalSeed) {
		uint seed = globalSeed ^ (cell.x * 374761393u + cell.y * 668265263u) ^ seq * 2654435761u;
		return randHash(seed);
	}
	
	// Poisson sampler using Knuth's method
	inline int poissonSample(float lambda, uint2 cell, uint globalSeed) {
		if (lambda <= 0.0) return 0;
		
		float L = exp(-lambda);
		int k = 0;
		float p = 1.0;
		do {
			k++;
			p *= cellRandom(cell, k, globalSeed);
		} while (p > L);
		return k - 1;
	}
	
	
	// Generate log-normal distributed grain radius
	inline float logNormalRadius(uint2 cell, uint q, uint globalSeed,
								 float mu_r, float sigma_r, float rm) {
		// Generate two uniform randoms
		float u1 = cellRandom(cell, q * 2u, globalSeed);
		float u2 = cellRandom(cell, q * 2u + 1u, globalSeed);
		
		// Convert to standard normal via Box-Muller
		float z = sqrt(-2.0 * log(max(u1, 1e-6))) * cos(2.0 * 3.14159 * u2);
		
		// Log-normal transform: r = exp(log(mu_r) + z * log(1 + sigma_r / mu_r))
		float logMean = log(max(mu_r, 1e-6));
		float logStd = log(1.0 + (sigma_r / max(mu_r, 1e-6)));
		
		float r = exp(logMean + z * logStd);
		return clamp(r, 0.0, rm);
	}
	
	// Evaluate if pixel `pos` is covered by any grain (Algorithm 3)
	inline bool evaluateLocalBooleanIndicator(
		coreimage::sampler src,
		float2 pos,
		constant float* lambdaLUT,
		int width, int height,
		float mu_r, float sigma_r, float rm,
		float delta,
		uint globalSeed
	) {
		int minX = int(floor((pos.x - rm) / delta));
		int maxX = int(floor((pos.x + rm) / delta));
		int minY = int(floor((pos.y - rm) / delta));
		int maxY = int(floor((pos.y + rm) / delta));

		for (int cy = minY; cy <= maxY; ++cy) {
			for (int cx = minX; cx <= maxX; ++cx) {
				uint2 cell = uint2(cx, cy);

				float2 sampleCoord = float2(
					clamp(float(cx) * delta, 0.0, float(width  - 1)),
					clamp(float(cy) * delta, 0.0, float(height - 1))
				);
				float u = clamp(sample(src, sampleCoord).r, 0.0, 1.0 - 1e-6);

				int lutIndex = int(u * 255.0);
				float lambda = lambdaLUT[lutIndex];
				
//				float lambdaScaled = lambda / 5.0;

				int Q = poissonSample(lambda, cell, globalSeed);

				for (int q = 0; q < Q; ++q) {
					float rx = cellRandom(cell, q * 3u, globalSeed);
					float ry = cellRandom(cell, q * 3u + 1u, globalSeed);
					float2 center = float2((float(cx) + rx) * delta,
										   (float(cy) + ry) * delta);
					float r = logNormalRadius(cell, q, globalSeed, mu_r, sigma_r, rm);
					if (distance(pos, center) <= r) return true;
				}
			}
		}
		return false;
	}
	
	float4 grainMaskDebug(
		coreimage::sampler src,               // Input grayscale image (normalized 0–1)
		int width, int height,                // Image dimensions
		float mu_r, float sigma_r,            // Grain radius distribution
		float rm, float delta,                // Max radius & cell size (usually δ = μ_r)
		uint seed,                            // Global RNG seed
		constant float* lambdaLUT             // Precomputed λ LUT (256 entries)
	) {
		// Current pixel coordinate (CoreImage returns pixel-space coords)
		float2 pos = samplerCoord(src);

		// Check if this pixel is covered by any grain (Algorithm 3)
		bool covered = evaluateLocalBooleanIndicator(src, pos, lambdaLUT,
													 width, height,
													 mu_r, sigma_r, rm, delta, seed);

		// Output binary mask
		float v = covered ? 1.0 : 0.0;
		return float4(v, v, v, 1.0);
	}
	
	
	float4 realisticFilmGrain(
		coreimage::sampler src,
		int width, int height,
		int N,
		float mu_r, float sigma_r,
		float rm, float delta,
		float s,
		float sigma,       // blur sigma for Gaussian offsets
		float beta,        // NEW: final scaling factor (Eq. 5)
		uint seed,
		constant float* lambdaLUT,
		constant float* xOffsets,
		constant float* yOffsets
							  )
	{
		float2 pos = samplerCoord(src);
		float weightedSum = 0.0;
		float weightNorm = 0.0;
		
		// Sample the original pixel brightness
		float base = sample(src, pos).r;

		for (int k = 0; k < N; ++k) {
			float2 offset = float2(xOffsets[k], yOffsets[k]);
			float w = gaussianPDF(offset, sigma);

//			float2 samplePos = (pos + offset) / max(s, 1e-6);
			float2 samplePos = (pos + offset) / max(s, 1e-6);
			samplePos.x = clamp(samplePos.x, 0.0, float(width  - 1));
			samplePos.y = clamp(samplePos.y, 0.0, float(height - 1));
			bool covered = evaluateLocalBooleanIndicator(src, samplePos, lambdaLUT,
														 width, height,
														 mu_r, sigma_r, rm, delta, seed);
			if (covered) weightedSum += w;
			weightNorm += w;
		}

		// Apply β scaling to normalize fill fraction (Eq. 5)
//		float v = (weightNorm > 0.0) ? (beta * (weightedSum / weightNorm)) : 0.0;
		float v = weightedSum / weightNorm;
//		return float4(v, v, v, 1.0);
		
		// Target average level (adjust as needed)
//		float targetLevel = 0.4;

		// Grain strength (normalized)
		float grain = (weightNorm > 0.0) ? (weightedSum / weightNorm) : 0.0;
		

		// Normalize so we preserve the original pixel brightness
		float final = base * grain;
		
//		final = (final + 0.0928) * (1.0 - 0.0928);

		return float4(final, final, final, 1.0);
	}
	
	
	float4 normaliseGrain(coreimage::sample_t s, float lowVal, float highVal) {
		
		float3 rgb = s.rgb;
		
		// Normalise
		rgb = (rgb + lowVal) * highVal;
		
		return float4(rgb, 1.0);
	}
	
}
