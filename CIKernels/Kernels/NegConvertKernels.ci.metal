//
//  NegConvertKernels.metal
//  ColorForge
//
//  Created by admin on 23/05/2025.
//


/*
 
 Functions relating to the conversion to / from negative to positve, and also
 Cineon encoding and decoding.
 
 
 */

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
	
	// Kodak Portra Constants
	constant float dMinRed_KodakPortra = 0.466;
	constant float redDensity_KodakPortra = 2.1466;
	
	constant float dMinGreen_KodakPortra = 0.206;
	constant float greenDensity_KodakPortra = 2.7104;
	
	constant float dMinBlue_KodakPortra = 0.109;
	constant float blueDensity_KodakPortra = 3.1870;
	
	
	// Kodak Gold Constants
	constant float dMinRed_KodakGold = 0.41374;
	constant float redDensity_KodakGold = 1.796436608;

	constant float dMinGreen_KodakGold = 0.18859;
	constant float greenDensity_KodakGold = 2.268889757;

	constant float dMinBlue_KodakGold = 0.08944;
	constant float blueDensity_KodakGold = 2.656110418;
	
	
	// TMAX Constants (shared across channels)
	constant float dMin_Tmax = 0.7512;
	constant float density_Tmax = 2.886334291;
	
	
	// Noritsu Scan Constants
	constant float dMinRed_Noritsu = 0.46472;
	constant float redDensity_Noritsu = 2.135020;

	constant float dMinGreen_Noritsu = 0.20837;
	constant float greenDensity_Noritsu = 2.669063;

	constant float dMinBlue_Noritsu = 0.10872;
	constant float blueDensity_Noritsu = 3.031886;
	
	
	// MTF Constants
	
	// Red gains
	constant float rGain_10LPM = 0.95;
	constant float rGain_20LPM = 0.80;
	constant float rGain_50LPM = 0.45;
	constant float rGain_100LPM = 0.15;

	// Green gains
	constant float gGain_10LPM = 0.95;
	constant float gGain_20LPM = 0.85;
	constant float gGain_50LPM = 0.55;
	constant float gGain_100LPM = 0.25;

	// Blue gains
	constant float bGain_10LPM = 0.90;
	constant float bGain_20LPM = 0.70;
	constant float bGain_50LPM = 0.55;
	constant float bGain_100LPM = 0.30;
	
	
	
	//Mask OutputMaps
	
	constant float lowsMask[32] = {
		1.000000, 1.000000, 1.000000, 1.000000, 1.000000,
		1.000000, 1.000000, 1.000000, 1.000000, 1.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000
	};
	
	constant float midsMask[32] = {
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		1.000000, 1.000000, 1.000000, 1.000000, 1.000000,
		1.000000, 1.000000, 1.000000, 1.000000, 1.000000,
		1.000000, 1.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000
	};
	
	constant float highsMask[32] = {
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 1.000000, 1.000000, 1.000000,
		1.000000, 1.000000, 1.000000, 1.000000, 1.000000,
		1.000000, 1.000000
	};
	
	
	// Grain output map:
	// Blends highlight grain over the top of shadow grain
	constant float grainMask[32] = {
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000,
		0.000000, 0.000000, 1.000000, 1.000000, 1.000000,
		1.000000, 1.000000, 1.000000, 1.000000, 1.000000,
		1.000000, 1.000000
	};
	
	
	
	// MARK: - Cineon (to / from positive)
	
	// Currently with half stop exposure compensation
	float4 encodeCineon(coreimage::sample_t s) {
		float3 linearRGB = float3(s.r, s.g, s.b) * 1.5; // Exposure compensation of half a stop
		float3 cineonRGB;
		
		cineonRGB.r = (685 + log10(((linearRGB.r * 255 + 2.78) / 255.73)) * 300) * (1.0 / 1023.0);
		cineonRGB.g = (685 + log10(((linearRGB.g * 255 + 2.78) / 255.73)) * 300) * (1.0 / 1023.0);
		cineonRGB.b = (685 + log10(((linearRGB.b * 255 + 2.78) / 255.73)) * 300) * (1.0 / 1023.0);
		
		return float4(cineonRGB, s.a);
	}
	
	
	// Currently with half stop exposure compensation
	float4 decodeCineon(coreimage::sample_t s) {
		float3 cineonRGB = float3(s.r, s.g, s.b);
		float3 linearRGB;

		linearRGB.r = ((pow(10, ((cineonRGB.r * 1023.0 - 685) / 300.0)) * 255.73) - 2.78) / 255.0;
		linearRGB.g = ((pow(10, ((cineonRGB.g * 1023.0 - 685) / 300.0)) * 255.73) - 2.78) / 255.0;
		linearRGB.b = ((pow(10, ((cineonRGB.b * 1023.0 - 685) / 300.0)) * 255.73) - 2.78) / 255.0;

		// Apply the inverse of the exposure compensation (divide by 1.5)
		linearRGB /= 1.5;

		return float4(linearRGB, s.a);
	}
	
	
	// MARK: - Cineon (inversion)
	
	// Requires user set values for dMin, dMax and Density for each channel.
	float4 encodeNegative(coreimage::sample_t s, float dMinRed, float dMinGreen, float dMinBlue, float redDensity, float greenDensity, float blueDensity, int choice) {
		// Define RGB as a float3 using the sample's RGB values
		float3 rgb = float3(s.r, s.g, s.b);
		
		// Choice:
		// 0 = user, 1 = Portra constants (previously HOG), 2 = Kodak Gold constants,
		// 3 = TMax Constants, 4 = Noritsu Constants.
		if (choice != 0) {
			if (choice == 1) {
				// Kodak Portra
				dMinRed = dMinRed_KodakPortra;
				redDensity = redDensity_KodakPortra;
				dMinGreen = dMinGreen_KodakPortra;
				greenDensity = greenDensity_KodakPortra;
				dMinBlue = dMinBlue_KodakPortra;
				blueDensity = blueDensity_KodakPortra;
			} else if (choice == 2) {
				// Kodak Gold
				dMinRed = dMinRed_KodakGold;
				redDensity = redDensity_KodakGold;
				dMinGreen = dMinGreen_KodakGold;
				greenDensity = greenDensity_KodakGold;
				dMinBlue = dMinBlue_KodakGold;
				blueDensity = blueDensity_KodakGold;
			} else if (choice == 3) {
				// TMAX (grayscale, same values for all channels)
				dMinRed = dMin_Tmax;
				redDensity = density_Tmax;
				dMinGreen = dMin_Tmax;
				greenDensity = density_Tmax;
				dMinBlue = dMin_Tmax;
				blueDensity = density_Tmax;
			} else if (choice == 4) {
				// Noritsu
				dMinRed = dMinRed_Noritsu;
				redDensity = redDensity_Noritsu;
				dMinGreen = dMinGreen_Noritsu;
				greenDensity = greenDensity_Noritsu;
				dMinBlue = dMinBlue_Noritsu;
				blueDensity = blueDensity_Noritsu;
			}
		}
		

		// Encode each channel
		rgb.r = (log10(dMinRed / rgb.r) * (1023.0 / redDensity) + 95.0) * (1.0 / 1023.0);
		rgb.g = (log10(dMinGreen / rgb.g) * (1023.0 / greenDensity) + 95.0) * (1.0 / 1023.0);
		rgb.b = (log10(dMinBlue / rgb.b) * (1023.0 / blueDensity) + 95.0) * (1.0 / 1023.0);

		return float4(rgb, s.a);
	}
	
	
	// Requires user set values for dMin, dMax and Density for each channel.
	float4 decodeNegative(coreimage::sample_t s, float dMinRed, float dMinGreen, float dMinBlue, float redDensity, float greenDensity, float blueDensity, int choice) {
		// Define RGB as a float3 using the sample's RGB values
		float3 rgb = float3(s.r, s.g, s.b);
		
		// Choice:
		// 0 = user, 1 = Portra constants (previously HOG), 2 = Kodak Gold constants,
		// 3 = TMax Constants, 4 = Noritsu Constants.
		if (choice != 0) {
			if (choice == 1) {
				// Kodak Portra
				dMinRed = dMinRed_KodakPortra;
				redDensity = redDensity_KodakPortra;
				dMinGreen = dMinGreen_KodakPortra;
				greenDensity = greenDensity_KodakPortra;
				dMinBlue = dMinBlue_KodakPortra;
				blueDensity = blueDensity_KodakPortra;
			} else if (choice == 2) {
				// Portra + 1
				dMinRed = dMinRed_KodakPortra;
				redDensity = redDensity_KodakPortra;
				dMinGreen = dMinGreen_KodakPortra;
				greenDensity = greenDensity_KodakPortra;
				dMinBlue = dMinBlue_KodakPortra;
				blueDensity = blueDensity_KodakPortra;
				
			} else if (choice == 3) {
				// Portra + 2
				dMinRed = dMinRed_KodakPortra;
				redDensity = redDensity_KodakPortra;
				dMinGreen = dMinGreen_KodakPortra;
				greenDensity = greenDensity_KodakPortra;
				dMinBlue = dMinBlue_KodakPortra;
				blueDensity = blueDensity_KodakPortra;
				

			} else if (choice == 4) {
				// Kodak Gold
				dMinRed = dMinRed_KodakGold;
				redDensity = redDensity_KodakGold;
				dMinGreen = dMinGreen_KodakGold;
				greenDensity = greenDensity_KodakGold;
				dMinBlue = dMinBlue_KodakGold;
				blueDensity = blueDensity_KodakGold;
				
				
//				// Noritsu
//				dMinRed = dMinRed_Noritsu;
//				redDensity = redDensity_Noritsu;
//				dMinGreen = dMinGreen_Noritsu;
//				greenDensity = greenDensity_Noritsu;
//				dMinBlue = dMinBlue_Noritsu;
//				blueDensity = blueDensity_Noritsu;
			} else if (choice == 5) {
				// TMAX (grayscale, same values for all channels)
				dMinRed = dMin_Tmax;
				redDensity = density_Tmax;
				dMinGreen = dMin_Tmax;
				greenDensity = density_Tmax;
				dMinBlue = dMin_Tmax;
				blueDensity = density_Tmax;
			}
		}

		// Decode each channel
		rgb.r = dMinRed / pow(10, ((rgb.r * 1023.0 - 95.0) / (1023.0 / redDensity)));
		rgb.g = dMinGreen / pow(10, ((rgb.g * 1023.0 - 95.0) / (1023.0 / greenDensity)));
		rgb.b = dMinBlue / pow(10, ((rgb.b * 1023.0 - 95.0) / (1023.0 / blueDensity)));

		return float4(rgb, s.a);
	}
	
	// Used for halation
	inline float3 encodeNegativeF3 (float3 rgb) {
		float dMinRed = dMinRed_KodakPortra;
		float redDensity = redDensity_KodakPortra;
		float dMinGreen = dMinGreen_KodakPortra;
		float greenDensity = greenDensity_KodakPortra;
		float dMinBlue = dMinBlue_KodakPortra;
		float blueDensity = blueDensity_KodakPortra;
		
		rgb.r = (log10(dMinRed / rgb.r) * (1023.0 / redDensity) + 95.0) * (1.0 / 1023.0);
		rgb.g = (log10(dMinGreen / rgb.g) * (1023.0 / greenDensity) + 95.0) * (1.0 / 1023.0);
		rgb.b = (log10(dMinBlue / rgb.b) * (1023.0 / blueDensity) + 95.0) * (1.0 / 1023.0);
		
		return rgb;
	}
	
	inline float3 decodeNegativeF3 (float3 rgb) {
		float dMinRed = dMinRed_KodakPortra;
		float redDensity = redDensity_KodakPortra;
		float dMinGreen = dMinGreen_KodakPortra;
		float greenDensity = greenDensity_KodakPortra;
		float dMinBlue = dMinBlue_KodakPortra;
		float blueDensity = blueDensity_KodakPortra;
		
		
		rgb.r = dMinRed / pow(10, ((rgb.r * 1023.0 - 95.0) / (1023.0 / redDensity)));
		rgb.g = dMinGreen / pow(10, ((rgb.g * 1023.0 - 95.0) / (1023.0 / greenDensity)));
		rgb.b = dMinBlue / pow(10, ((rgb.b * 1023.0 - 95.0) / (1023.0 / blueDensity)));
		
		return rgb;
	}
	
	
	// MARK: - MTF Curve helper
	
	float4 mtfBandKernel(coreimage::sample_t base, coreimage::sample_t low,
						 float rGain, float gGain, float bGain) {
		float3 base3 = float3(base.r, base.g, base.b);
		base3 = encodeLogCFloat3(base3);
		float3 low3 = float3(low.r, low.g, low.b);
		low3 = encodeLogCFloat3(low3);
		float3 high = base3 - low3;
		
		float3 result = low3;
		result.r += high.r * rGain;
		result.g += high.g * gGain;
		result.b += high.b * bGain;
		result = decodeLogCFloat3(result);
		return float4(result, base.a);
	}
	
	
	// MARK: - Grain Blend function
	
	
	// Blends grain plates based on luminance and weights, and returns masked grain plate
	float4 grainPlateBlendKernel(coreimage::sample_t s, coreimage::sample_t HG, coreimage::sample_t LG, float amount) {
		float3 rgb = float3(s.r, s.g, s.b);
		float3 maskedRgb = rgb;
		
	
		maskedRgb = inputOutputMapSingleDimension(rgb, grainMask);


		
		float3 lowMask = 1.0 - maskedRgb;
		float3 highGrain = float3(HG.r, HG.g, HG.b);
		float3 lowGrain = float3(LG.r, LG.g, LG.b);
		float3 grey = float3(0.5, 0.5, 0.5);
		
		float3 finalGrain = mix(grey, lowGrain, lowMask * 0.75);
		finalGrain = mix(finalGrain, highGrain, maskedRgb);
		
		finalGrain = mix(grey, finalGrain, amount);
		
		rgb = softlightF3(rgb, finalGrain);
		
		return float4(rgb, s.a);
	}
	
	
	
	// MARK: - Grain helper functions
	
	
	float4 returnChannelAndInvert(coreimage::sample_t s, int channel) {
		if (channel == 0){
			return float4(s.r, 0.0, 0.0, s.a);
		} else if (channel == 1) {
			return float4(0.0, s.g, 0.0, s.a);
		} else if (channel == 2) {
			return float4(0.0, 0.0, s.b, s.a);
		} else {
			return s;
		}
	}
	
	float4 combineRGBAndInvert(coreimage::sample_t r, coreimage::sample_t g, coreimage::sample_t b) {
		float red = 1.0 - r.r;
		float green = 1.0 - g.g;
		float blue = 1.0 - b.b;
		
		return float4(red, green, blue, 1.0);
	}
	
	/*
	 constant float dMinRed_KodakPortra = 0.466;
	 constant float redDensity_KodakPortra = 2.1466;
	 
	 constant float dMinGreen_KodakPortra = 0.206;
	 constant float greenDensity_KodakPortra = 2.7104;
	 
	 constant float dMinBlue_KodakPortra = 0.109;
	 constant float blueDensity_KodakPortra = 3.1870;
	 */


	// Converts the arri image to a negative, the uses frequency separation to add back in the blurs
	float4 halation(coreimage::sample_t s, coreimage::sample_t blurred, float blend) {
		float3 arri = float3(s.r, s.g, s.b);
		float3 linear = decodeLogCFloat3(arri);
		
//		float halationEV = 8.0;

		float3 blurredF3 = float3(blurred.r, blurred.g, blurred.b);
		float3 blurredLinear = decodeLogCFloat3(blurredF3);
		float3 negativeBlurred = decodeNegativeF3(blurredF3);
		float3 black = float3(0.0, 0.0, 0.0);
		negativeBlurred = mix(black, negativeBlurred, blurredLinear);
		
		
		float3 halation = linear + negativeBlurred;
		
		
		linear = mix(linear, halation, blend);
		arri = encodeLogCFloat3(linear);

		return float4(arri, s.a);
	}
	
}

