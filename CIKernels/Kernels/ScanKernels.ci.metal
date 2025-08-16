//
//  ScanKernels.metal
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
	
	constant float scanContrastPlus[32] = {
		0.0000000000, 0.0000000000, 0.0000000000, 0.0007320000, 0.0063480000,
		0.0165100000, 0.0323790000, 0.0551150000, 0.0858150000, 0.1245420000,
		0.1703190000, 0.2219850000, 0.2784730000, 0.3386230000, 0.4013980000,
		0.4656680000, 0.5303650000, 0.5943600000, 0.6566470000, 0.7161560000,
		0.7719420000, 0.8229060000, 0.8680420000, 0.9063420000, 0.9368590000,
		0.9598390000, 0.9764100000, 0.9875790000, 0.9944460000, 0.9980770000,
		0.9995730000, 1.0000000000
	};
	
	
	constant float scanContrastMinus[32] = {
		0.0000000000, 0.1932955848, 0.2356847000, 0.2671930924, 0.2934867687,
		0.3162183309, 0.3370840917, 0.3570209897, 0.3754422956, 0.3934516293,
		0.4107514253, 0.4276875732, 0.4442639607, 0.4606257064, 0.4768165066,
		0.4929470069, 0.5090309479, 0.5252134601, 0.5414738356, 0.5579905224,
		0.5746967810, 0.5919052390, 0.6093913793, 0.6278101246, 0.6465864256,
		0.6670044211, 0.6887140209, 0.7121416171, 0.7393108788, 0.7727399651,
		0.8218359230, 1.0000000000
	};
	
	
	
	// MARK: - Offsets
	
	// Requires offsets normalised 0–1
	float4 offsetRGB(coreimage::sample_t s, float offsetRGB, float offsetRed, float offsetGreen, float offsetBlue, int blackAndWhite) {
		float3 rgb = float3(s.r, s.g, s.b);

		if (blackAndWhite != 1) {
			rgb.x += offsetRed;
			rgb.y += offsetGreen;
			rgb.z += offsetBlue;
			rgb += offsetRGB;
		} else {
			float avgOffset = (offsetRed + offsetGreen + offsetBlue) / 3.0;
			rgb += avgOffset;
			rgb += offsetRGB;
		}

		return float4(rgb, s.a);
	}
    
    
    float4 lift(coreimage::sample_t s, float lift) {
        float3 rgb = s.rgb;
        rgb = (rgb + lift) / (1.0 + lift);
        return float4(rgb, s.a);
    }

	
	
	// Scan contrast with sCurve
	float4 scanContrast(coreimage::sample_t s, float contrast) {
		float3 rgb = float3(s.r, s.g, s.b);
		float3 increase = inputOutputMapSingleDimension(rgb, scanContrastPlus);
		float3 decrease = inputOutputMapSingleDimension(rgb, scanContrastMinus);
		
		if (contrast > 0.0) {
			rgb = mix(rgb, increase, contrast);
		} else {
			rgb = mix(rgb, decrease, -contrast);
		}
		
		return float4(rgb, s.a);
	}
	
	
}
