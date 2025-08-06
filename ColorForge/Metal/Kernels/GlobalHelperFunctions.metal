//
//  GlobalHelperFunctions.metal
//  ColorForge
//
//  Created by admin on 23/05/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" {
	
	
	// MARK: - Boiler plate kernels
	
	/*
	 
	 float4 name(coreimage::sample_t s) {
		 float3 rgb = float3(s.r, s.g, s.b);
		 
		 
		 return float4(rgb, s.a);
	 }
	 
	 */
	
	// MARK: - Global Constants
	
	constant float inputMapLinear32[32] = {
		0.0000000000, 0.0322580645, 0.0645161290, 0.0967741935, 0.1290322581,
		0.1612903226, 0.1935483871, 0.2258064516, 0.2580645161, 0.2903225806,
		0.3225806452, 0.3548387097, 0.3870967742, 0.4193548387, 0.4516129032,
		0.4838709677, 0.5161290323, 0.5483870968, 0.5806451613, 0.6129032258,
		0.6451612903, 0.6774193548, 0.7096774194, 0.7419354839, 0.7741935484,
		0.8064516129, 0.8387096774, 0.8709677419, 0.9032258065, 0.9354838710,
		0.9677419355, 1.0000000000
	};
	
	// Constants for Log C encoding
	constant float cut = 0.010591;
	constant float a = 5.555556;
	constant float b = 0.052272;
	constant float c = 0.247190;
	constant float d = 0.385537;
	constant float e = 5.367655;
	constant float f = 0.092809;
	
	
	// MARK: - Bell Curve
	
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
	
	
	
	// MARK: - Float3 ColorSpace Kernels
	
	inline float3 rgbToSphericalFloat3(float3 rgb) {
		
		// Compute intermediate values
		const float rtr = rgb.x * 0.81649658f + rgb.y * -0.40824829f + rgb.z * -0.40824829f;
		const float rtg = rgb.x * 0.0f + rgb.y * 0.70710678f + rgb.z * -0.70710678f;
		const float rtb = rgb.x * 0.57735027f + rgb.y * 0.57735027f + rgb.z * 0.57735027f;
		
		const float art = atan2(rtg, rtr);
		
		// Calculate spherical coordinates (branchless version)
		const float sph_x = sqrt(rtr * rtr + rtg * rtg + rtb * rtb);
		const float sph_y = art + (step(art, 0.0f) * (2.0f * 3.141592653589f));
		const float sph_z = atan2(sqrt(rtr * rtr + rtg * rtg), rtb);
		
		return float3(
			sph_x * 0.5773502691896258f,
			sph_y * 0.15915494309189535f,
			sph_z * 1.0467733744265997f
		);
	}
	
	
	inline float3 sphericalToRgbFloat3(float3 sph) {
		
		// Scale spherical values
		sph.x *= 1.7320508075688772f;
		sph.y *= 6.283185307179586f;
		sph.z *= 0.9553166181245093f;
		
		// Convert to cartesian coordinates
		float ctr = sph.x * sin(sph.z) * cos(sph.y);
		float ctg = sph.x * sin(sph.z) * sin(sph.y);
		float ctb = sph.x * cos(sph.z);
		
		// Convert to RGB
		return float3(
					  ctr * 0.81649658f + ctg * 0.0f + ctb * 0.57735027f,
					  ctr * -0.40824829f + ctg * 0.70710678f + ctb * 0.57735027f,
					  ctr * -0.40824829f + ctg * -0.70710678f + ctb * 0.57735027f
					  );
	}
	
	inline float3 softlightF3(float3 base, float3 blend) {
		float3 result;

		for (int i = 0; i < 3; i++) {
			if (blend[i] <= 0.5) {
				result[i] = base[i] - (1.0 - 2.0 * blend[i]) * base[i] * (1.0 - base[i]);
			} else {
				result[i] = base[i] + (2.0 * blend[i] - 1.0) * (sqrt(base[i]) - base[i]);
			}
		}

		return result;
	}
	
	
	inline float3 encodeLogCFloat3(float3 linearRGB) {
		
		// Evaluate both expressions (always computed)
		float3 logPart = c * log10(a * linearRGB + b) + d;
		float3 linPart = e * linearRGB + f;
		
		// Create a mask where linearRGB > cut (1.0 if true, 0.0 if false)
		float3 mask = step(cut, linearRGB);
		
		// Use mix (or equivalent): result = linPart * (1 - mask) + logPart * mask
		float3 logC = mix(linPart, logPart, mask);
		
		return logC;
	}
	
	inline float3 decodeLogCFloat3(float3 logC) {

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

	// Currently with half stop exposure compensation
	inline float3 encodeCineonF3(float3 linearRGB) {
		float3 cineonRGB;
		
		cineonRGB.r = (685 + log10(((linearRGB.r * 255 + 2.78) / 255.73)) * 300) * (1.0 / 1023.0);
		cineonRGB.g = (685 + log10(((linearRGB.g * 255 + 2.78) / 255.73)) * 300) * (1.0 / 1023.0);
		cineonRGB.b = (685 + log10(((linearRGB.b * 255 + 2.78) / 255.73)) * 300) * (1.0 / 1023.0);
		
		return cineonRGB;
	}
	
	
	// Currently with half stop exposure compensation
	inline float3 decodeCineonF3(float3 cineonRGB) {
		float3 linearRGB;

		linearRGB.r = ((pow(10, ((cineonRGB.r * 1023.0 - 685) / 300.0)) * 255.73) - 2.78) / 255.0;
		linearRGB.g = ((pow(10, ((cineonRGB.g * 1023.0 - 685) / 300.0)) * 255.73) - 2.78) / 255.0;
		linearRGB.b = ((pow(10, ((cineonRGB.b * 1023.0 - 685) / 300.0)) * 255.73) - 2.78) / 255.0;


		return linearRGB;
	}
    
    inline float3 cineonToNeg(float3 rgb) {
        float3 neg = c;
        
        float minR = 0.466;
        float maxR = 2.1466;
        
        float minG = 0.206;
        float maxG = 2.7104;
        
        float minB = 0.109;
        float maxB = 3.1870;
        
        
        rgb.r = minR / pow(10, ((rgb.r * 1023.0 - 95.0) / (1023.0 / maxR)));
        rgb.g = minG / pow(10, ((rgb.g * 1023.0 - 95.0) / (1023.0 / maxG)));
        rgb.b = minB / pow(10, ((rgb.b * 1023.0 - 95.0) / (1023.0 / maxB)));
        
        neg = rgb;
        
        return neg;
    }
    
    inline float3 negToCineon(float3 rgb) {
        float minR = 0.466;
        float maxR = 2.1466;
        
        float minG = 0.206;
        float maxG = 2.7104;
        
        float minB = 0.109;
        float maxB = 3.1870;
        
        rgb.r = (log10(minR / rgb.r) * (1023.0 / maxR) + 95.0) * (1.0 / 1023.0);
        rgb.g = (log10(minG / rgb.g) * (1023.0 / maxG) + 95.0) * (1.0 / 1023.0);
        rgb.b = (log10(minB / rgb.b) * (1023.0 / maxB) + 95.0) * (1.0 / 1023.0);
        
        return rgb;
    }
	
	
	
	// MARK: - Matrix Math
	
	inline float3 applyMatrix(float3 rgb, float3x3 matrix) {
		return matrix * rgb;
	}
	
	
	// MARK: - Interpolation
	
	// New linear interpolation function for 32 points
	inline float linearInterpolate32(float input, float x0, float y0, float x1, float y1) {
		return y0 + (input - x0) * (y1 - y0) / (x1 - x0);
	}

	// Updated mapRGB function for 32 points - Now uses the last or first value for out of bounds values
	inline float3 mapRGB32(float3 inputColor, constant float outputMap[32][3]) {
		float3 outputColor;

		// For each channel: R, G, B
		for (int i = 0; i < 3; i++) {
			float inputChannel = inputColor[i];

			// Below range — clamp to first value
			if (inputChannel <= inputMapLinear32[0]) {
				outputColor[i] = outputMap[0][i];
				continue;
			}

			// Above range — clamp to last value
			if (inputChannel >= inputMapLinear32[31]) {
				outputColor[i] = outputMap[31][i];
				continue;
			}

			// In-range — perform interpolation
			for (int j = 0; j < 31; j++) {
				if (inputChannel >= inputMapLinear32[j] && inputChannel <= inputMapLinear32[j + 1]) {
					outputColor[i] = linearInterpolate32(
						inputChannel,
						inputMapLinear32[j],     outputMap[j][i],
						inputMapLinear32[j + 1], outputMap[j + 1][i]
					);
					break;
				}
			}
		}

		return outputColor;
	}
	

	// Accepts single output map, not [3]
	inline float3 inputOutputMapSingleDimension(float3 inputColor, constant float* outputMap) {
		float3 outputColor;

		for (int i = 0; i < 3; i++) {
			float inputChannel = inputColor[i];

			if (inputChannel <= inputMapLinear32[0]) {
				outputColor[i] = outputMap[0];
				continue;
			}

			if (inputChannel >= inputMapLinear32[31]) {
				outputColor[i] = outputMap[31];
				continue;
			}

			for (int j = 0; j < 31; j++) {
				if (inputChannel >= inputMapLinear32[j] && inputChannel <= inputMapLinear32[j + 1]) {
					outputColor[i] = linearInterpolate32(
						inputChannel,
						inputMapLinear32[j],     outputMap[j],
						inputMapLinear32[j + 1], outputMap[j + 1]
					);
					break;
				}
			}
		}

		return outputColor;
	}
	
	// Curve interpolation for input/output maps with 10 values
	inline float linearInterpolation10x(float inputValue, constant float inputMap[10], constant float outputMap[10]) {
		
		// Find the two points on the input map where inputValue falls between
		for (int i = 0; i < 9; i++) {  // 9 because we are looking for a pair
			if (inputValue >= inputMap[i] && inputValue <= inputMap[i + 1]) {
				// Perform linear interpolation between the points
				float t = (inputValue - inputMap[i]) / (inputMap[i + 1] - inputMap[i]);
				return mix(outputMap[i], outputMap[i + 1], t);
			}
		}

		// If inputValue is exactly 1.0, return the last output map value
		return outputMap[9];
	}
	
	

	
}

