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
	
	
    
    // MARK: - Adobe RGB to LAB
    
    // ---- White point (D65)
    constant float3 kWhiteD65 = float3(0.95047f, 1.00000f, 1.08883f);

    // ---- Adobe RGB (1998) matrices (linear, D65)
    constant float3x3 kAdobe2XYZ = float3x3(
        float3(0.57667f, 0.18556f, 0.18823f),
        float3(0.29734f, 0.62736f, 0.07529f),
        float3(0.02703f, 0.07069f, 0.99134f)
    );

    constant float3x3 kXYZ2Adobe = float3x3(
        float3( 2.04159f, -0.56501f, -0.34473f),
        float3(-0.96924f,  1.87597f,  0.04156f),
        float3( 0.01344f, -0.11836f,  1.01517f)
    );

    // ---- Adobe RGB gamma helpers (use only if your data is gamma-encoded)
    inline float3 adobeEncode(float3 linear) {
        const float g = 1.0f / 2.19921875f;
        return pow(max(linear, 0.0f), float3(g, g, g));
    }
    inline float3 adobeDecode(float3 encoded) {
        const float g = 2.19921875f;
        return pow(max(encoded, 0.0f), float3(g, g, g));
    }

    // ---- Lab helper pieces
    inline float fLab(float t) {
        const float d  = 6.0f / 29.0f;
        const float d3 = d*d*d;
        const float k  = 1.0f / (3.0f*d*d);
        return (t > d3) ? pow(t, 1.0f/3.0f) : (k*t + 4.0f/29.0f);
    }
    inline float fInvLab(float t) {
        const float d = 6.0f / 29.0f;
        return (t > d) ? (t*t*t) : (3.0f*d*d*(t - 4.0f/29.0f));
    }

    // ---- Core conversions (linear Adobe RGB <-> Lab, D65)
    inline float3 adobeLinearToLab(float3 rgbLinear) {
        float3 xyz = kAdobe2XYZ * rgbLinear;
        float3 r = xyz / kWhiteD65;

        float fx = fLab(r.x);
        float fy = fLab(r.y);
        float fz = fLab(r.z);

        float L = 116.0f*fy - 16.0f;
        float a = 500.0f*(fx - fy);
        float b = 200.0f*(fy - fz);
        return float3(L, a, b);
    }

    inline float3 labToAdobeLinear(float3 lab) {
        float fy = (lab.x + 16.0f) / 116.0f;
        float fx = fy + lab.y / 500.0f;
        float fz = fy - lab.z / 200.0f;

        float3 xyz;
        xyz.x = fInvLab(fx) * kWhiteD65.x;
        xyz.y = fInvLab(fy) * kWhiteD65.y;
        xyz.z = fInvLab(fz) * kWhiteD65.z;

        return kXYZ2Adobe * xyz;
    }

    // ---- Convenience wrappers if your buffers are gamma-encoded Adobe RGB
    inline float3 adobeEncodedToLab(float3 rgbEncoded) {
        // Decode gamma to linear, then to Lab
        float3 lab = adobeLinearToLab(adobeDecode(rgbEncoded));

        // Normalize Lab ranges to 0–1
        lab.x = lab.x / 100.0f;              // L: 0–100 → 0–1
        lab.y = (lab.y + 128.0f) / 255.0f;   // a: -128–128 → 0–1
        lab.z = (lab.z + 128.0f) / 255.0f;   // b: -128–128 → 0–1

        return lab;
    }

    inline float3 labToAdobeEncoded(float3 lab) {
        // Denormalize Lab back to standard ranges
        lab.x = lab.x * 100.0f;              // 0–1 → 0–100
        lab.y = lab.y * 255.0f - 128.0f;     // 0–1 → -128–128
        lab.z = lab.z * 255.0f - 128.0f;     // 0–1 → -128–128

        // Lab → linear RGB → gamma encode
        return adobeEncode(labToAdobeLinear(lab));
    }
	
	
	// MARK: - Gaussian Blur
	
	
	inline float gaussianWeight2D(int dx, int dy, float stdDev) {
		float r2 = float(dx*dx + dy*dy);
		float denom = 2.0f * stdDev * stdDev;
		return exp(-r2 / denom);
	}
	
	
	inline float3 gaussianBlur2D(coreimage::sampler src, float radiusPx, float2 center) {
		float stdDev = radiusPx * 0.5f;
		int window   = (int)ceil(stdDev * 5.0f);
		if (window <= 0) {
			return sample(src, center).rgb;
		}
		
		float2 imgSize = src.size();
		int halfW = window / 2;
		
		float3 sum  = float3(0.0f);
		float  wsum = 0.0f;
		
		for (int dy = -halfW; dy <= halfW; ++dy) {
			for (int dx = -halfW; dx <= halfW; ++dx) {
				float2 uv = center + float2(dx, dy);
				
				// Skip outside image
				if (uv.x < 0.0f || uv.y < 0.0f || uv.x >= imgSize.x || uv.y >= imgSize.y) {
					continue;
				}
				
				float w = gaussianWeight2D(dx, dy, stdDev);
				sum  += w * sample(src, uv).rgb;
				wsum += w;
			}
		}
		
		return (wsum > 0.0f) ? (sum / wsum) : sample(src, center).rgb;
	}
	
	
//	// Kernel entry — single pass 2D blur
//	float4 gaussianBlur2D_kernel(coreimage::sampler src, float blur_amount) {
//		float2 coord = src.coord();
//		float2 imgSize = src.size();
//
//		
//		float3 outRGB = gaussianBlur2D(src, blur_amount, coord);
//		return float4(outRGB, 1.0);
//	}

	
	
}


