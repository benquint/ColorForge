//
//  GrainV2Kernels.metal
//  ColorForge
//
//  Created by admin on 20/07/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

// Define PRNG struct, used for generating noise
struct noise_prng {
	uint state;

	// Initialize PRNG
	noise_prng(uint seed) {
		state = wang_hash(seed);
	}

	// wang_hash is used to generate pseudo-random numbers
	uint wang_hash(uint seed) {
		seed = (seed ^ 61u) ^ (seed >> 16u);
		seed *= 9u;
		seed = seed ^ (seed >> 4u);
		seed *= 668265261u;
		seed = seed ^ (seed >> 15u);
		return seed;
	}

	// Generate a random number
	uint myrand() {
		state ^= state << 13u;
		state ^= state >> 17u;
		state ^= state << 5u;
		return state;
	}

	// Generate a floating-point number in the range [0, 1]
	float myrand_uniform_0_1() {
		return static_cast<float>(myrand()) / 4294967295.0f;
	}
};

// Generate a seed for the PRNG
inline uint cellseed(const int x, const int y, const uint offset) {
	const uint period = 65536u; // 65536 = 2^16
	uint s = ((uint(y % int(period))) * period + (uint(x % int(period)))) + offset;
	s |= (s == 0u); // if (s == 0u) s = 1u;
	return s;
}

// Compute the squared distance between two points
inline float sq_distance(const float x1, const float y1, const float x2, const float y2) {
	return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
}

// Generate a random number from a Poisson distribution
int my_rand_poisson(thread noise_prng &p, const float lambda, float prod) {
	// Generate a random u value
	const float u = p.myrand_uniform_0_1();
	const float x_max = 10000.0f * lambda;

	float sum = prod;
	float x = 0.0f;

	while (u > sum && x < x_max) {
		x += 1.0f;
		prod *= lambda / x;
//        prod = clamp(prod, 1e-6f, 1e6f);

		sum += prod;
	}

	return int(x);
}



extern "C" {
	
	inline float render_pixel_coreimage(
		coreimage::sampler src,
		int width,
		int height,
		int x,
		int y,
		int num_iterations,
		float grain_radius_mean,
		float sigma,
		int seed,
		constant float* lambda,        // 256-entry lookup table
		constant float* exp_lambda,    // 256-entry lookup table
		constant float* x_gaussian,    // length = num_iterations
		constant float* y_gaussian     // length = num_iterations
	) {
		const float inv_grain_radius_mean = ceil(1.0f / grain_radius_mean);
		const float ag = grain_radius_mean;
		const float grain_radius_sq = grain_radius_mean * grain_radius_mean;

		int pixel_val = 0;

		// Monte Carlo sampling loop
		for (int i = 0; i < num_iterations; i++) {
			float x_gauss = float(x) + sigma * x_gaussian[i];
			float y_gauss = float(y) + sigma * y_gaussian[i];

			int x_start = int(floor((x_gauss - grain_radius_mean) * inv_grain_radius_mean));
			int x_end   = int(ceil((x_gauss + grain_radius_mean) * inv_grain_radius_mean));
			int y_start = int(floor((y_gauss - grain_radius_mean) * inv_grain_radius_mean));
			int y_end   = int(ceil((y_gauss + grain_radius_mean) * inv_grain_radius_mean));

			noise_prng p = noise_prng(cellseed(x_start + x, y_start + y, uint(seed)));
			float found_grain = 0.0;

			for (int ix = x_start; ix <= x_end; ix++) {
				for (int iy = y_start; iy <= y_end; iy++) {
					float cell_x = ag * float(ix);
					float cell_y = ag * float(iy);

					int px = clamp(int(round(cell_x)), 0, width - 1);
					int py = clamp(int(round(cell_y)), 0, height - 1);

					// Sample source using CoreImage's sampler (convert pixel coords back to normalized)
					float cellVal = sample(src, float2(px, py) / src.size()).r;
					int pixelIndex = int(clamp(cellVal * 255.1f, 0.0f, 255.0f));

					int n_cell = my_rand_poisson(p, lambda[pixelIndex], exp_lambda[pixelIndex]);

					for (int k = 0; k < n_cell; k++) {
						float xCentreGrain = cell_x + ag * p.myrand_uniform_0_1();
						float yCentreGrain = cell_y + ag * p.myrand_uniform_0_1();

						float dist_check = sq_distance(xCentreGrain, yCentreGrain, x_gauss, y_gauss) < grain_radius_sq ? 1.0f : 0.0f;

						pixel_val += int(dist_check * (1.0f - found_grain));
						found_grain = mix(found_grain, 1.0f, dist_check);
					}
				}
			}
		}

		return float(pixel_val) / float(num_iterations);
	}
	
//	float4 realisticFilmGrain(coreimage::sampler src,
//							  int width, int height,
//							  int num_iterations,
//							  float grain_radius_mean,
//							  float grain_radius_std,
//							  float sigma,
//							  int seed,
//							  constant float* lambda      [[ buffer(0) ]],
//							  constant float* exp_lambda  [[ buffer(1) ]],
//							  constant float* x_gaussian  [[ buffer(2) ]],
//							  constant float* y_gaussian  [[ buffer(3) ]])
//	{
//		// Simple test: always return blue so we know the kernel runs
//		return float4(0.0, 0.0, 1.0, 1.0);
//	}

	// Convert a pixel's grayscale intensity to the normalized probability field (ũ)
	inline float normalized_intensity(coreimage::sampler src, float umax, float epsilon) {
		// Sample the pixel intensity at its exact coordinate
		float pixelVal = sample(src, src.coord()).r;  // u(x)

		// Normalize to [0,1):  ũ(x) = u(x) / (umax + ε)
		return pixelVal / (umax + epsilon);
	}
	
	struct PoissonParams {
		float lambdaVal;
		float expLambdaVal;
	};
	
	// Fetch λ(x) and exp(-λ(x)) using precomputed lookup tables
	inline PoissonParams get_poisson_params(coreimage::sampler src,
											constant float* lambda,
											constant float* exp_lambda) {
		PoissonParams params;

		// Sample normalized intensity ũ(x)
		float pixelVal = sample(src, src.coord()).r;
		float u_norm = pixelVal / (1.0 + 1e-6);

		int pixelIndex = int(clamp(u_norm * 255.0f, 0.0f, 255.0f));

		params.lambdaVal = lambda[pixelIndex];
		params.expLambdaVal = exp_lambda[pixelIndex];

		return params;
	}
	
	// Simple 1D Gaussian weight function
	inline float gaussian_weight(float x, float sigma) {
		return exp(-(x * x) / (2.0f * sigma * sigma));
	}
	
//	// Main kernel
//	float4 realisticFilmGrain(coreimage::sampler src,
//							  int width, int height,
//							  int num_iterations,
//							  float grain_radius_mean,
//							  float grain_radius_std,
//							  float sigma,
//							  int seed,
//							  constant float* lambda      [[ buffer(0) ]],
//							  constant float* exp_lambda  [[ buffer(1) ]],
//							  constant float* x_gaussian  [[ buffer(2) ]],
//							  constant float* y_gaussian  [[ buffer(3) ]]
//							  ) {
//		float2 pixelCoord = src.coord();
//		int x = int(pixelCoord.x);
//		int y = int(pixelCoord.y);
//	
//		// Step 1: Calculate normalised intensity
//		// Get ũ(x) for this pixel
//		float u_norm = normalized_intensity(src, 1.0, 1e-6);  // assuming umax=1.0 for normalized input
//		int pixelIndex = int(clamp(u_norm * 255.0f, 0.0f, 255.0f));
//		
//		
//		// Step 2: Get poisson params
//		PoissonParams poissonParams = get_poisson_params(src, lambda, exp_lambda);
//		float lambdaVal = poissonParams.lambdaVal;
//		float expLambdaVal = poissonParams.expLambdaVal;
//		
//		
//		// Step 3: Monte Carlo Sampling
//		const float inv_grain_radius_mean = ceil(1.0f / grain_radius_mean);
//		const float ag = grain_radius_mean;  // cell spacing
//		const float grain_radius_sq = grain_radius_mean * grain_radius_mean;
//		
//		int coveredCount = 0; // How many iterations this pixel is "covered" by a grain
//		
//		
//		// Step 3: Monte Carlo sampling (with PRNG & Poisson)
//		for (int i = 0; i < num_iterations; i++) {
//			// Jittered sampling point near pixel (Gaussian offset)
//			float x_k = float(x) + sigma * x_gaussian[i];
//			float y_k = float(y) + sigma * y_gaussian[i];
//			
//			// Find overlapping grid cells
//			int x_start = int(floor((x_k - grain_radius_mean) * inv_grain_radius_mean));
//			int x_end   = int(ceil((x_k + grain_radius_mean) * inv_grain_radius_mean));
//			int y_start = int(floor((y_k - grain_radius_mean) * inv_grain_radius_mean));
//			int y_end   = int(ceil((y_k + grain_radius_mean) * inv_grain_radius_mean));
//			
//			bool iterationCovered = false;
//			
//			for (int ix = x_start; ix <= x_end; ix++) {
//				for (int iy = y_start; iy <= y_end; iy++) {
//					float cell_x = ag * float(ix);
//					float cell_y = ag * float(iy);
//					
//					// Step 3.3: PRNG per cell (reproducible)
//					noise_prng rng = noise_prng(cellseed(ix, iy, uint(seed)));
//					
//					// Draw how many grains for this cell (Poisson distributed)
//					int n_cell = my_rand_poisson(rng,
//												 poissonParams.lambdaVal,
//												 poissonParams.expLambdaVal);
//					
//					// For each grain center
//					for (int k = 0; k < n_cell; k++) {
//						// Random position inside the cell
//						float xCentre = cell_x + ag * rng.myrand_uniform_0_1();
//						float yCentre = cell_y + ag * rng.myrand_uniform_0_1();
//						
//						// Check coverage
//						float dx = xCentre - x_k;
//						float dy = yCentre - y_k;
//						if (dx * dx + dy * dy < grain_radius_sq) {
//							iterationCovered = true;
//						}
//					}
//				}
//			}
//			
//			if (iterationCovered) {
//				coveredCount++;
//			}
//		}
//		
//		// Grain probability field
//		float f_x = float(coveredCount) / float(num_iterations);
//
//		// Step 4: Gaussian smoothing (convolve with neighbors in a 3x3 grid)
//		float blurSigma = sigma * 0.5;  // can tune
//		float totalWeight = 0.0;
//		float blurred = 0.0;
//
//		// Small convolution kernel around the pixel
//		for (int dx = -1; dx <= 1; dx++) {
//			for (int dy = -1; dy <= 1; dy++) {
//				float2 offsetCoord = (pixelCoord + float2(dx, dy)) / src.size();
//				float sampleVal = sample(src, offsetCoord).r; // For simplicity, just reuse input brightness
//				float weight = gaussian_weight(length(float2(dx, dy)), blurSigma);
//				blurred += sampleVal * weight;
//				totalWeight += weight;
//			}
//		}
//		blurred = mix(f_x, blurred / totalWeight, 0.5);  // mix raw grain with blurred neighbor contribution
//
//		// Step 5: Blend with original image
//		float4 inputColor = sample(src, src.coord());
//		float alpha = 0.5;  // strength
//		float3 blended = mix(inputColor.rgb, float3(blurred), alpha);
//
//		return float4(blended, inputColor.a);
//	}
	
	
	float4 copyChannel(coreimage::sample_t s, int channel) {
		
		if (channel == 0) {
			return float4(s.r, s.r, s.r, s.a);
		} else if (channel == 1) {
			return float4(s.g, s.g, s.g, s.a);
		} else if (channel == 2) {
			return float4(s.b, s.b, s.b, s.a);
		} else {
			return s;
		}
	}
	
	// This works
	float4 testSampler(coreimage::sampler src) {
		float4 color = sample(src, src.coord());
		float2 redCoord = src.coord() - float2(20, 20);
		color.r = sample(src, redCoord).r;
		float2 blueCoord = src.coord() + float2(40, 40);
		color.b = sample(src, blueCoord).b;
		
		return color * color.a;
	}
	
}
