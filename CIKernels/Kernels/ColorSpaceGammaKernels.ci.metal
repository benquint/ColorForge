//
//  ColorSpaceGammaKernels.metal
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
	
	// Constants for converting sensor signal to Log C 3
	constant float ei160_Cut    = 0.004680;
	constant float ei160_A      = 40.0;
	constant float ei160_B      = -0.076072;
	constant float ei160_C      = 0.269036;
	constant float ei160_D      = 0.381991;
	constant float ei160_E      = 42.062665;
	constant float ei160_F      = -0.071569;
	constant float ei160_ECutF  = 0.125266;

	constant float ei200_Cut    = 0.004597;
	constant float ei200_A      = 50.0;
	constant float ei200_B      = -0.118740;
	constant float ei200_C      = 0.266007;
	constant float ei200_D      = 0.382478;
	constant float ei200_E      = 51.986387;
	constant float ei200_F      = -0.110339;
	constant float ei200_ECutF  = 0.128643;

	constant float ei250_Cut    = 0.004518;
	constant float ei250_A      = 62.5;
	constant float ei250_B      = -0.171260;
	constant float ei250_C      = 0.262978;
	constant float ei250_D      = 0.382966;
	constant float ei250_E      = 64.243053;
	constant float ei250_F      = -0.158224;
	constant float ei250_ECutF  = 0.132021;

	constant float ei320_Cut    = 0.004436;
	constant float ei320_A      = 80.0;
	constant float ei320_B      = -0.243808;
	constant float ei320_C      = 0.259627;
	constant float ei320_D      = 0.383508;
	constant float ei320_E      = 81.183335;
	constant float ei320_F      = -0.224409;
	constant float ei320_ECutF  = 0.135761;

	constant float ei400_Cut    = 0.004369;
	constant float ei400_A      = 100.0;
	constant float ei400_B      = -0.325820;
	constant float ei400_C      = 0.256598;
	constant float ei400_D      = 0.383999;
	constant float ei400_E      = 100.295280;
	constant float ei400_F      = -0.299079;
	constant float ei400_ECutF  = 0.139142;

	constant float ei500_Cut    = 0.004309;
	constant float ei500_A      = 125.0;
	constant float ei500_B      = -0.427461;
	constant float ei500_C      = 0.253569;
	constant float ei500_D      = 0.384493;
	constant float ei500_E      = 123.889239;
	constant float ei500_F      = -0.391261;
	constant float ei500_ECutF  = 0.142526;

	constant float ei640_Cut    = 0.004249;
	constant float ei640_A      = 160.0;
	constant float ei640_B      = -0.568709;
	constant float ei640_C      = 0.250219;
	constant float ei640_D      = 0.385040;
	constant float ei640_E      = 156.482680;
	constant float ei640_F      = -0.518605;
	constant float ei640_ECutF  = 0.146271;

	constant float ei800_Cut    = 0.004201;
	constant float ei800_A      = 200.0;
	constant float ei800_B      = -0.729169;
	constant float ei800_C      = 0.247190;
	constant float ei800_D      = 0.385537;
	constant float ei800_E      = 193.235573;
	constant float ei800_F      = -0.662201;
	constant float ei800_ECutF  = 0.149658;

	constant float ei1000_Cut   = 0.004160;
	constant float ei1000_A     = 250.0;
	constant float ei1000_B     = -0.928805;
	constant float ei1000_C     = 0.244161;
	constant float ei1000_D     = 0.386036;
	constant float ei1000_E     = 238.584745;
	constant float ei1000_F     = -0.839385;
	constant float ei1000_ECutF = 0.153047;

	constant float ei1280_Cut   = 0.004120;
	constant float ei1280_A     = 320.0;
	constant float ei1280_B     = -1.207168;
	constant float ei1280_C     = 0.240810;
	constant float ei1280_D     = 0.386590;
	constant float ei1280_E     = 301.197380;
	constant float ei1280_F     = -1.084020;
	constant float ei1280_ECutF = 0.156799;

	constant float ei1600_Cut   = 0.004088;
	constant float ei1600_A     = 400.0;
	constant float ei1600_B     = -1.524256;
	constant float ei1600_C     = 0.237781;
	constant float ei1600_D     = 0.387093;
	constant float ei1600_E     = 371.761171;
	constant float ei1600_F     = -1.359723;
	constant float ei1600_ECutF = 0.160192;
	
	
	// Constants for tonemapping
	constant float blackPoint = 0.0;
	constant float whitePoint = 1.0;
	constant float toneMapVal = 0.82;
	
	// Adobe Camera Raw Curve Constants
	constant float inputMap1[10] = {0.0, 0.111111, 0.222222, 0.333333, 0.444444, 0.555556, 0.666667, 0.777778, 0.888889, 1.0};
	constant float outputMap1[10] = {0.0, 0.097570, 0.256261, 0.465905, 0.634990, 0.775373, 0.869451, 0.930429, 0.968478, 1.0};
	
	// MARK: - TO AWG
	
	/*
	 
	 Rec709 IDT
	 0.631321  0.270801  0.097878
	 0.036820  0.793037  0.170143
	 0.017370  0.148789  0.833841
	 
	 Rec2020 IDT - Also Fujifilm uses this
	 1.012798 -0.074045  0.061247
	-0.040722  0.859682  0.181040
	-0.004824  0.074489  0.930335
	 
	 P3 D65
	 0.760019  0.132484  0.107497
	 0.008408  0.804728  0.186864
	-0.001355  0.085570  0.915786
	 
	 P3 D60
	 0.776156  0.119729  0.104116
	 0.009109  0.805648  0.185243
	-0.001058  0.086352  0.914706
	 
	 P3 DCI
	 0.717759  0.177618  0.104622
	 0.006637  0.810099  0.183264
	-0.001120  0.087356  0.913764
	 
	 
	 ACES AP0
	 1.515617 -0.359240 -0.156377
	-0.129027  1.020831  0.108196
	-0.010159  0.056989  0.953170
	 
	 ACES AP1
	 1.038812 -0.096243  0.057431
	-0.044602  0.859863  0.184739
	-0.009779  0.051399  0.958380
	 
	 AWG4
	 1.138221 -0.144940  0.006719
	-0.095585  1.008229  0.087357
	-0.008318  0.058954  0.949363
	 
	 AdobeRGB
	 0.882811  0.015109  0.102080
	 0.051487  0.771065  0.177447
	 0.024289  0.106074  0.869637
	 
	 
	 SGamut3.Cine
	 0.974435  0.023802  0.001763
	-0.089226  1.071257  0.017969
	-0.035354  0.038226  0.997128
	 
	 SGamut3 / S-Gamut:
	 
	 1.135123 -0.150051  0.014928
	-0.075528  1.016898  0.058629
	-0.015536  0.063459  0.952077
	 
	 
	 Canon Cinema Gamut
	 1.156928 -0.140305 -0.016623
	-0.095219  1.085411  0.009809
	-0.016732 -0.141620  1.158352
	 
	 REDWideGamutRGB:
	 1.193057 -0.214522  0.021466
	-0.085618  1.065702  0.019916
	-0.076961 -0.238684  1.315644
	 
	 Davinci Wide Gamut:
	 
	 
	 
	 */
	
	// MARK: - Gamma
	
	/*
	 
	 SLOG3:
	 
	 Scene Linear Reflection to S-Log3
	 If in >= 0.01125000
	  out = (420.0 + log10((in + 0.01) / (0.18 + 0.01)) * 261.5) / 1023.0
	 else
	  out = (in * (171.2102946929 – 95.0)/0.01125000 + 95.0) / 1023.0
	 in = reflection
	 reflection = IRE * 0.9
	 out 0.0 - 1.0
	 if you need 10bit code for “out”.
	  10bit code = Round(out * 1023.0)
	 
	 
	 If in >= 171.2102946929 / 1023.0
	  out = (10.0 ^ ((in * 1023.0 - 420.0) / 261.5)) * (0.18 + 0.01) - 0.01
	 else
	  out + (in * 1023.0 – 95.0) * 0.01125000 / (171.2102946929 – 95.0)
	 in 0.0 - 1.0
	 out = reflection
	 reflection = IRE * 0.9
	 if you use 10bit code for “in”
	  in = S-Log3 10bit Code / 1023.0
	 
	 
	 
	 RED Log3G10
	 
	 float3 log3G10Inverse(float3 x)
	 {
		 const float a = 0.224282f;
		 const float b = 155.975327f;
		 const float c = 0.01f;
		 const float g = 15.1927f;

		 float3 result;
		 result = select(
			 (pow(10.0f, x / a) - 1.0f) / b,
			 x / g,
			 x < 0.0f
		 );
		 return result - c;
	 }

	 float3 log3G10(float3 x)
	 {
		 const float a = 0.224282f;
		 const float b = 155.975327f;
		 const float c = 0.01f;
		 const float g = 15.1927f;

		 x = x + c;

		 float3 result;
		 result = select(
			 a * log10((x * b) + 1.0f),
			 x * g,
			 x < 0.0f
		 );
		 return result;
	 }
	 
	 */
	
	
	// MARK: - AWG4 / LogC4


	float3 relativeSceneLinearToNormalizedLogC4(float3 x) {
		float awg4_a = (pow(2.0f, 18.0f) - 16.0f) / 117.45f;
		float awg4_b = (1023.0f - 95.0f) / 1023.0f;
		float awg4_c = 95.0f / 1023.0f;
		float awg4_s = (7.0f * log(2.0f) * pow(2.0f, 7.0f - 14.0f * awg4_c / awg4_b)) / (awg4_a * awg4_b);
		float awg4_t = (pow(2.0f, 14.0f * (-awg4_c / awg4_b) + 6.0f) - 64.0f) / awg4_a;
		
		
		bool3 belowT = x < float3(awg4_t);

		float3 linPart = (x - awg4_t) / awg4_s;
		float3 logPart = ((log2(awg4_a * x + 64.0f) - 6.0f) / 14.0f) * awg4_b + awg4_c;

		return select(logPart, linPart, belowT);
	}
	
	float3 normalizedLogC4ToRelativeSceneLinear(float3 x) {
		float awg4_a = (pow(2.0f, 18.0f) - 16.0f) / 117.45f;
		float awg4_b = (1023.0f - 95.0f) / 1023.0f;
		float awg4_c = 95.0f / 1023.0f;
		float awg4_s = (7.0f * log(2.0f) * pow(2.0f, 7.0f - 14.0f * awg4_c / awg4_b)) / (awg4_a * awg4_b);
		float awg4_t = (pow(2.0f, 14.0f * (-awg4_c / awg4_b) + 6.0f) - 64.0f) / awg4_a;
		
		
		bool3 belowZero = x < float3(0.0f);

		float3 linPart = x * awg4_s + awg4_t;
		float3 p = 14.0f * (x - awg4_c) / awg4_b + 6.0f;
		float3 logPart = (pow(2.0f, p) - 64.0f) / awg4_a;

		return select(logPart, linPart, belowZero);
	}
	
	float4 AWG4_to_LinearP3(coreimage::sample_t s) {
		float3 rgb = s.rgb;

		// Decode Arri LogC4
		rgb = normalizedLogC4ToRelativeSceneLinear(rgb);

//		// Apply AWG4 to Linear Display P3 matrix
//		rgb = float3x3(
//			float3( 1.520502f, -0.404299f, -0.116204f),
//			float3(-0.136032f,  1.269848f, -0.133816f),
//			float3( 0.005879f, -0.054876f,  1.048997f)
//		) * rgb;
		
		// Apply AWG4 to Linear AWG3 matrix
		rgb = float3x3(
			float3( 1.138221f, -0.144940f,  0.006719f),
			float3(-0.095585f,  1.008229f,  0.087357f),
			float3(-0.008318f,  0.058954f,  0.949363f)
		) * rgb;

		return float4(rgb, 1.0f);
	}

	// MARK: - Tone Map function
	float4 toneMapLinear(coreimage::sample_t s) {
		float r = s.r;
		float g = s.g;
		float b = s.b;
		
		r = whitePoint * (r / (r + toneMapVal)) + blackPoint;
		g = whitePoint * (g / (g + toneMapVal)) + blackPoint;
		b = whitePoint * (b / (b + toneMapVal)) + blackPoint;
		
		return float4(r, g, b, s.a);
	}
	
	float4 gamutMap(coreimage::sample_t s){
		float3 rgb = float3(s.r, s.g, s.b);
		float3 sph = rgbToSphericalFloat3(rgb);
		float bp = 0.0;
		float wp = 1.0;
		float val = 0.5;
		sph.z = wp * (sph.z / (sph.z + val)) + bp;
		rgb = sphericalToRgbFloat3(sph);
		return float4(rgb, s.a);
	}
	
	
	// MARK: - Adobe Camera Raw Curve
	float4 applyAdobeCameraRawCurveKernel(coreimage::sample_t s){
		float3 rgb = float3(s.r, s.g, s.b);
		for (int i = 0; i < 3; i++) {
			rgb[i] = linearInterpolation10x(rgb[i], inputMap1, outputMap1);
		}
		return float4(rgb, s.a);
	}
	
	
	// MARK: - Color Space Conversion Kernels
	
	float4 rgbToSpherical(coreimage::sample_t s) {
		float3 rgb = float3(s.r, s.g, s.b);
		
		// Compute intermediate values
		const float rtr = rgb.x * 0.81649658f + rgb.y * -0.40824829f + rgb.z * -0.40824829f;
		const float rtg = rgb.x * 0.0f + rgb.y * 0.70710678f + rgb.z * -0.70710678f;
		const float rtb = rgb.x * 0.57735027f + rgb.y * 0.57735027f + rgb.z * 0.57735027f;
		
		const float art = atan2(rtg, rtr);
		
		// Calculate spherical coordinates (branchless version)
		const float sph_x = sqrt(rtr * rtr + rtg * rtg + rtb * rtb);
		const float sph_y = art + (step(art, 0.0f) * (2.0f * 3.141592653589f));
		const float sph_z = atan2(sqrt(rtr * rtr + rtg * rtg), rtb);
		
		return float4(
			sph_x * 0.5773502691896258f,
			sph_y * 0.15915494309189535f,
			sph_z * 1.0467733744265997f,
			s.a
		);
	}
	
	
	float4 sphericalToRgb(coreimage::sample_t s) {
		float3 sph = float3(s.r, s.g, s.b);
		
		// Scale spherical values
		sph.x *= 1.7320508075688772f;
		sph.y *= 6.283185307179586f;
		sph.z *= 0.9553166181245093f;
		
		// Convert to cartesian coordinates
		float ctr = sph.x * sin(sph.z) * cos(sph.y);
		float ctg = sph.x * sin(sph.z) * sin(sph.y);
		float ctb = sph.x * cos(sph.z);
		
		// Convert to RGB
		return float4(
					  ctr * 0.81649658f + ctg * 0.0f + ctb * 0.57735027f,
					  ctr * -0.40824829f + ctg * 0.70710678f + ctb * 0.57735027f,
					  ctr * -0.40824829f + ctg * -0.70710678f + ctb * 0.57735027f,
					  s.a
					  );
	}
	
	
	
	// MARK: - Gamma Functions
	
	// LogC encoding from sensor signal (EI 800), apply baseline, return log-encoded RGB
	float4 encodeSensor(coreimage::sample_t s, float baselineEV) {
		float3 linearRGB = float3(s.r, s.g, s.b);
		
		float lift = 0.00390631f; // To match Arri's sensor signal black
		float flare = 0.00012207f; // Arris flare to avoid clipping in blacks

		linearRGB = linearRGB * (1.0f - lift) + lift;
		linearRGB += flare;

//		// Apply baseline exposure shift (in stops)
//		float exposureMult = pow(2.0, baselineEV);
//		linearRGB *= exposureMult;

		// Encode each channel using LogC v3 EI 800
		float3 logEncoded;
		for (int i = 0; i < 3; i++) {
			if (linearRGB[i] > ei800_Cut) {
				logEncoded[i] = ei800_C * log10(ei800_A * linearRGB[i] + ei800_B) + ei800_D;
			} else {
				logEncoded[i] = ei800_E * linearRGB[i] + ei800_F;
			}
		}

		return float4(logEncoded, s.a);
	}
	
	
	float4 decodeSLog3(coreimage::sample_t s) {
		float3 sonyRGB = s.rgb;       // S-Log3 encoded RGB, in range 0.0–1.0
		float3 linearRGB;

		// Constants from your formula
		const float threshold = 171.2102946929 / 1023.0;
		const float scale     = 1023.0;
		const float blackCode = 95.0;
		const float slope     = 0.01125000 / (171.2102946929 - blackCode);
		const float offset    = -0.01;
		const float gain      = 0.18 + 0.01;
		const float divisor   = 261.5;
		const float subtr     = 420.0;

		for (int i = 0; i < 3; i++) {
			float inVal = sonyRGB[i];
			float outVal;

			if (inVal >= threshold) {
				// High range: apply S-Log3 curve decoding
				outVal = pow(10.0, ((inVal * scale - subtr) / divisor)) * gain + offset;
			} else {
				// Low range: linear segment
				outVal = (inVal * scale - blackCode) * slope;
			}

			// Reflection step (IRE * 0.9) as per your note
			linearRGB[i] = outVal * 0.9;
		}

		return float4(linearRGB, 1.0);
	}

	// LogC encoding from sensor signal, apply baseline, and return linear
//	float4 encodeSensor(coreimage::sample_t s, float baselineEV) {
//		float3 linearRGB = float3(s.r, s.g, s.b);
//
//		// Precompute both paths
//		float3 logPart = ei800_C * log10(ei800_A * linearRGB + ei800_B) + ei800_D;
//		float3 linPart = ei800_E * linearRGB + ei800_F;
//
//		// Mask: 1 where x > cut, 0 otherwise
//		float3 mask = step(ei800_Cut, linearRGB);
//
//		// Mix without branching
//		float3 logEncoded = mix(linPart, logPart, mask);
//		
////		float3 linear = decodeLogCFloat3(logEncoded);
////		
////		linear *= pow(2, baselineEV);
//
//		return float4(logEncoded, s.a);
//	}
	
	// Encode LogC - without branching for cut
	float4 encodeLogC(coreimage::sample_t s) {
		float3 linearRGB = float3(s.r, s.g, s.b);
		
		// Evaluate both expressions (always computed)
		float3 logPart = c * log10(a * linearRGB + b) + d;
		float3 linPart = e * linearRGB + f;
		
		// Create a mask where linearRGB > cut (1.0 if true, 0.0 if false)
		float3 mask = step(cut, linearRGB);
		
		// Use mix (or equivalent): result = linPart * (1 - mask) + logPart * mask
		float3 logC = mix(linPart, logPart, mask);
		
		return float4(logC, s.a);
	}

	
	
	float4 decodeLogC(coreimage::sample_t s) {
		float3 logC = float3(s.r, s.g, s.b);

		// Calculate both paths:
		float3 powPart = (pow(10.0, (logC - d) / c) - b) / a;
		float3 linPart = (logC - f) / e;

		// Mask: step(edge, logC), where edge = e * cut + f
		float edge = e * cut + f;
		float3 mask = step(edge, logC);

		// Blend:
		float3 linearRGB = mix(linPart, powPart, mask);
		
		return float4(linearRGB, s.a);
	}
	
	

	
	
}
