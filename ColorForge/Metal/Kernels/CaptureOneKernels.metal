//
//  CaptureOneKernels.metal
//  ColorForge
//
//  Created by Ben Quinton on 02/07/2025.
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
    
    
    // MARK: - Capture One Color Kernels
    
    /*
     ColorForge to Capture One:
     
     0.567264  0.220259  0.212477
     0.053290  0.580767  0.365943
     -0.004724  0.197315  0.807409
     
     
     Capture One to ColorForge:
     
     1.819782   -0.6234629  -0.1963193
    -0.2053017   2.1055971  -0.9002955
     0.0608189  -0.5182146   1.4573957
     
     
     */
    
    // Converts Capture One No Effects to ColorForge linear input
    float4 c1ToColorForge(coreimage::sample_t s) {
        float3 c1 = float3(s.r, s.g, s.b);
        
		
        float3 linear = pow(c1, 1.8);
        
        // CaptureOne to ColorForge
        float3x3 inverseV3 = float3x3(
            float3(1.819782,  -0.2053017,  0.0608189),   // R column
            float3(-0.6234629, 2.1055971, -0.5182146),   // G column
            float3(-0.1963193, -0.9002955, 1.4573957)    // B column
        );

        float3 rgb = inverseV3 * linear; // matrix * vector (column-major convention)
        
		rgb *= 1.2;


        return float4(rgb, s.a);
    }
    
    // Converts ColorForge linear input to Capture One No Effects
    float4 convertToC1(coreimage::sample_t s) {
        float3 rgb = float3(s.r, s.g, s.b);

        // ColorForge to CaptureOne
        float3x3 v3 = float3x3(
            float3(0.567264, 0.053290, -0.004724),  // R column
            float3(0.220259, 0.580767, 0.197315),   // G column
            float3(0.212477, 0.365943, 0.807409)    // B column
        );

        float3 c1 = v3 * rgb; // correct matrix multiplication

        c1 = pow(c1, (1.0 / 1.8));

        return float4(c1, s.a);
    }
    
    
    // MARK: - Capture One Curve Kernels
    

    float4 filmStandardToLinear(coreimage::sample_t s) {
        float3 rgb = float3(s.r, s.g, s.b);
        
        rgb = 1.0 - rgb;
        rgb = pow(rgb, 1.0 / 2.0);
        rgb = 1.0 - rgb;
        rgb = pow(rgb, 1.0 / 1.2);

        return float4(rgb, s.a);
    }
	
	float4 scale0to1(coreimage::sample_t s,
					 float wr, float wg, float wb,
					 float br, float bg, float bb)
	{
		float3 rgb = float3(s.r, s.g, s.b);
		
		rgb.r *= wr;
		rgb.g *= wg;
		rgb.b *= wb;
		
		rgb = 1.0 - rgb;
		
		rgb.r *= br;
		rgb.g *= bg;
		rgb.b *= bb;
		
		rgb = 1.0 - rgb;

		return float4(rgb, s.a);
	}
	
	float4 scaleWP_BP_withScalar(coreimage::sample_t s, float wScalar, float bScalar) {
		float3 rgb = float3(s.r, s.g, s.b);
		
		// First scale white
		rgb *= wScalar;
		
		// Then invert and scale black
		rgb = 1.0 - rgb;
		rgb *= bScalar;
		rgb = 1.0 - rgb;
		
		// Clamp
		rgb = clamp(rgb, 0.0, 1.0);
		
		// Now apply FilmStandard to Linear
		rgb = 1.0 - rgb;
		rgb = pow(rgb, 1.0 / 2.0);
		rgb = 1.0 - rgb;
		rgb = pow(rgb, 1.0 / 1.2);

		// Return the result
		return float4(rgb, s.a);
	}

	// Constant 32-point linear input map (0.0 to 1.0)
	constant float LinearMap[32] = {
		0.0, 0.03225806, 0.06451613, 0.09677419, 0.12903225, 0.16129032, 0.19354839, 0.22580644,
		0.25806452, 0.29032257, 0.32258064, 0.3548387, 0.38709676, 0.41935483, 0.4516129, 0.48387095,
		0.516129, 0.5483871, 0.58064514, 0.61290324, 0.6451613, 0.67741936, 0.7096774, 0.7419355,
		0.7741935, 0.8064516, 0.83870965, 0.87096775, 0.9032258, 0.9354839, 0.9677419, 1.0
	};

	float linearInterpolate(float x, float x0, float y0, float x1, float y1) {
		float t = clamp((x - x0) / (x1 - x0), 0.0, 1.0);
		return mix(y0, y1, t);
	}

	inline float3 mapOutputToInput(float3 inputColor, constant float outputMap[32][3]) {
		float3 result;

		for (int channel = 0; channel < 3; channel++) {
			float val = inputColor[channel];

			// Clamp below range
			if (val <= outputMap[0][channel]) {
				result[channel] = LinearMap[0];
				continue;
			}

			// Clamp above range
			if (val >= outputMap[31][channel]) {
				result[channel] = LinearMap[31];
				continue;
			}

			// Find interval and interpolate
			for (int j = 0; j < 31; j++) {
				float y0 = outputMap[j][channel];
				float y1 = outputMap[j + 1][channel];
				if (val >= y0 && val <= y1) {
					result[channel] = linearInterpolate(val, y0, LinearMap[j], y1, LinearMap[j + 1]);
					break;
				}
			}
		}

		return result;
	}
	
	inline float3 mapSourceToTarget(float3 encodedColor,
								   constant float3 *source,
								   constant float3 *target) {
		float3 result;

		for (int channel = 0; channel < 3; channel++) {
			float val = encodedColor[channel];

			// Clamp below range
			if (val <= target[0][channel]) {
				result[channel] = source[0][channel];
				continue;
			}

			// Clamp above range
			if (val >= target[31][channel]) {
				result[channel] = source[31][channel];
				continue;
			}

			// Search target curve for interval and interpolate source value
			for (int j = 0; j < 31; j++) {
				float y0 = target[j][channel];
				float y1 = target[j + 1][channel];

				if (val >= y0 && val <= y1) {
					float x0 = source[j][channel];
					float x1 = source[j + 1][channel];
					result[channel] = linearInterpolate(val, y0, x0, y1, x1);
					break;
				}
			}
		}

		return result;
	}
	
	
	float4 applyInverseCurve(coreimage::sample_t s, constant float3 *curve) {
		float3 rgb = float3(s.r, s.g, s.b);

		// Remap the output RGB to the original linear input via inverse mapping
		float3 corrected = mapOutputToInput(rgb, (constant float(*)[3])curve);

		return float4(corrected, s.a); // Reattach alpha unchanged
	}
	
	// Uses source as inputmap and target as outputmap
	float4 swapCurves(coreimage::sample_t s, coreimage::sample_t t, coreimage::sample_t i) {
		float3 r1 = float3(s.r, s.g, s.b);
		float3 r2 = float3(t.r, t.g, t.b);
		float3 id = float3(i.r, i.g, i.b);
		
		float3 final = id + (r2 - r1);

		return float4(final, s.a);
	}

	
	float4 transformLut(coreimage::sample_t s, coreimage::sample_t t, coreimage::sample_t id) {
		float3 s_rgb = float3(s.r, s.g, s.b);
		float3 t_rgb = float3(t.r, t.g, t.b);
		float3 identity = float3(id.r, id.g, id.b);
		
		float3 delta = t_rgb - s_rgb;
		float3 transformed = identity + delta;
		
		return float4(transformed, 1.0);
	}
    
	
}
