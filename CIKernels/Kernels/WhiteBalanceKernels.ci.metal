//
//  WhiteBalanceKernels.metal
//  ColorForge
//
//  Created by admin on 02/06/2025.
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
	
	
	struct ruvt
	{
		float r;  // Reciprocal temperature (1/T)
		float u;  // u chromaticity coordinate (CIE 1960 uv space)
		float v;  // v chromaticity coordinate (CIE 1960 uv space)
		float t;  // Slope of the blackbody curve at this temperature
	};
	
	constant ruvt kTempTable[] =
		{
		{	0, 0.18006, 0.26352, -0.24341 },
		{  10, 0.18066, 0.26589, -0.25479 },
		{  20, 0.18133, 0.26846, -0.26876 },
		{  30, 0.18208, 0.27119, -0.28539 },
		{  40, 0.18293, 0.27407, -0.30470 },
		{  50, 0.18388, 0.27709, -0.32675 },
		{  60, 0.18494, 0.28021, -0.35156 },
		{  70, 0.18611, 0.28342, -0.37915 },
		{  80, 0.18740, 0.28668, -0.40955 },
		{  90, 0.18880, 0.28997, -0.44278 },
		{ 100, 0.19032, 0.29326, -0.47888 },
		{ 125, 0.19462, 0.30141, -0.58204 },
		{ 150, 0.19962, 0.30921, -0.70471 },
		{ 175, 0.20525, 0.31647, -0.84901 },
		{ 200, 0.21142, 0.32312, -1.0182 },
		{ 225, 0.21807, 0.32909, -1.2168 },
		{ 250, 0.22511, 0.33439, -1.4512 },
		{ 275, 0.23247, 0.33904, -1.7298 },
		{ 300, 0.24010, 0.34308, -2.0637 },
		{ 325, 0.24702, 0.34655, -2.4681 },
		{ 350, 0.25591, 0.34951, -2.9641 },
		{ 375, 0.26400, 0.35200, -3.5814 },
		{ 400, 0.27218, 0.35407, -4.3633 },
		{ 425, 0.28039, 0.35577, -5.3762 },
		{ 450, 0.28863, 0.35714, -6.7262 },
		{ 475, 0.29685, 0.35823, -8.5955 },
		{ 500, 0.30505, 0.35907, -11.324 },
		{ 525, 0.31320, 0.35968, -15.628 },
		{ 550, 0.32129, 0.36011, -23.325 },
		{ 575, 0.32931, 0.36038, -40.770 },
		{ 600, 0.33724, 0.36051, -116.45 }
		};
	
	inline float2 xy_to_temp(float2 xy) {
		float temp = 0.0;
		float tint = 0.0;

		float kTintScale = -3000.0;
		float u = 2.0 * xy.x / (1.5 - xy.x + 6.0 * xy.y);
		float v = 3.0 * xy.y / (1.5 - xy.x + 6.0 * xy.y);

		float last_dt = 0.0;
		float last_dv = 0.0;
		float last_du = 0.0;

		for (uint index = 1; index <= 30; index++)
		{
			// Convert slope to delta-u and delta-v, with length 1.
			
			float du = 1.0;
			float dv = kTempTable [index] . t;
			
			float len = sqrt (1.0 + dv * dv);
			
			du /= len;
			dv /= len;
			
			// Find delta from black body point to test coordinate.
			
			float uu = u - kTempTable [index] . u;
			float vv = v - kTempTable [index] . v;
			
			// Find distance above or below line.
			
			float dt = - uu * dv + vv * du;
			
			// If below line, we have found line pair.
			
			if (dt <= 0.0 || index == 30)
				{
					
				// Find fractional weight of two lines.
				
				if (dt > 0.0)
					dt = 0.0;
								
				dt = -dt;
				
				float f;
				
				if (index == 1)
					{
					f = 0.0;
					}
				else
					{
					f = dt / (last_dt + dt);
					}
				
				// Interpolate the temperature.
				
				temp = 1.0E6 / (kTempTable [index - 1] . r * f +
										kTempTable [index	 ] . r * (1.0 - f));
									
				// Find delta from black body point to test coordinate.
				
				uu = u - (kTempTable [index - 1] . u * f +
						  kTempTable [index	   ] . u * (1.0 - f));
						  
				vv = v - (kTempTable [index - 1] . v * f +
						  kTempTable [index	   ] . v * (1.0 - f));
				
				// Interpolate vectors along slope.
				
				du = du * (1.0 - f) + last_du * f;
				dv = dv * (1.0 - f) + last_dv * f;
				
				len = sqrt (du * du + dv * dv);
				
				du /= len;
				dv /= len;

				// Find distance along slope.
				
				tint = (uu * du + vv * dv) * kTintScale;
		
				break;
				
				}
				
			// Try next line pair.
				
			last_dt = dt;
			
			last_du = du;
			last_dv = dv;
			
			}

		return float2(temp, tint);
	}
	
	inline float2 tempAndTintToXY(float temp, float tint) {
		float x = 0.0;
		float y = 0.0;
		float kTintScale = -3000.0;
		
		// Find inverse temperature to use as index.
		
		float r = 1.0E6 / temp;
		
		// Convert tint to offset is uv space.
		
		float offset = tint * (1.0 / kTintScale);
		
		// Search for line pair containing coordinate.
		
		for (uint index = 0; index <= 29; index++)
			{
			
			if (r < kTempTable [index + 1] . r || index == 29)
				{
				
				// Find relative weight of first line.
				
				float f = (kTempTable [index + 1] . r - r) /
						   (kTempTable [index + 1] . r - kTempTable [index] . r);
						   
				// Interpolate the black body coordinates.
				
				float u = kTempTable [index	] . u * f +
						   kTempTable [index + 1] . u * (1.0 - f);
						   
				float v = kTempTable [index	] . v * f +
						   kTempTable [index + 1] . v * (1.0 - f);
						   
				// Find vectors along slope for each line.
				
				float uu1 = 1.0;
				float vv1 = kTempTable [index] . t;
				
				float uu2 = 1.0;
				float vv2 = kTempTable [index + 1] . t;
				
				float len1 = sqrt (1.0 + vv1 * vv1);
				float len2 = sqrt (1.0 + vv2 * vv2);
				
				uu1 /= len1;
				vv1 /= len1;
				
				uu2 /= len2;
				vv2 /= len2;
				
				// Find vector from black body point.
				
				float uu3 = uu1 * f + uu2 * (1.0 - f);
				float vv3 = vv1 * f + vv2 * (1.0 - f);
				
				float len3 = sqrt (uu3 * uu3 + vv3 * vv3);
				
				uu3 /= len3;
				vv3 /= len3;
				
				// Adjust coordinate along this vector.
				
				u += uu3 * offset;
				v += vv3 * offset;
						   
				// Convert to xy coordinates.
				
				x = 1.5 * u / (u - 4.0 * v + 2.0);
				y =		 v / (u - 4.0 * v + 2.0);
		
				break;
				
				}
			
			}
		
		return float2(x, y);
		
		}
	
	// MARK: - Main Functions
	
	// Main func for calculating temp and tint
	float4 calculateTempFromXY(coreimage::sample_t s, float x, float y) {
		float2 xy = float2(x, y);
		
		float2 tempTint = xy_to_temp(xy);
		float temp = tempTint.x;
		float tint = tempTint.y;
		
		return float4(temp, tint, 1.0, 1.0);
	}
	
    

	
	
}
