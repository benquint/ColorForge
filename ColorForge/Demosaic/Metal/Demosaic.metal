//
//  Demosaic.metal
//  Demosaicer
//
//  Created by Ben Quinton on 13/08/2025.
//


/*
 Demosaic: Malvar–He–Cutler (ICASSP’04)
 Single-pass, gradient-corrected bilinear with Wiener gains:
 alpha = 0.5  (G at R/B)
 beta  = 0.625 (R/B at G)
 gamma = 0.75 (R at B, B at R)
 Reference: Malvar, He, Cutler, "High-Quality Linear Interpolation for Demosaicing of Bayer-Patterned Color Images", ICASSP 2004.  [Ben’s attached PDF]
 */

#include <metal_stdlib>
using namespace metal;


// Constants for Log C encoding
constant float cut = 0.010591;
constant float a = 5.555556;
constant float b = 0.052272;
constant float c = 0.247190;
constant float d = 0.385537;
constant float e = 5.367655;
constant float f = 0.092809;


// MARK: - Debayer

enum CFAPattern : uint { CFA_RGGB=0, CFA_BGGR=1, CFA_GRBG=2, CFA_GBRG=3 };

	
	struct Params {
		float blackLevel;       // 0
		float blackLevelRed;    // 4
		float blackLevelGreen;  // 8
		float blackLevelBlue;   // 12
		float whiteLevel;       // 16
		uint  cfaPattern;       // 20
		uint  coreSize;         // 24
		float3 camToAWG3[3];    // 32–79 (16-byte aligned each)
		float rMul;             // 80
		float bMul;             // 84
		float _pad[2];          // 88–95
	};
    
    // 8 masks (fill with your 5×5 taps, row-major)
    struct Masks {
        float G_at_R[25];
        float G_at_B[25];
        float R_at_G_Rrow[25];
        float R_at_G_Brow[25];
        float B_at_G_Rrow[25];
        float B_at_G_Brow[25];
        float R_at_B[25];
        float B_at_R[25];
    };
    
    
    inline float encodeLogC(float x) {
        // Evaluate both expressions (always computed)
        float logPart = c * log10(a * x + b) + d;
        float linPart = e * x + f;
        
        // Create a mask where linearRGB > cut (1.0 if true, 0.0 if false)
        float mask = step(cut, x);
        
        // Use mix (or equivalent): result = linPart * (1 - mask) + logPart * mask
        float logC = mix(linPart, logPart, mask);
        
        return logC;
    }
	
	
	inline float encodeArriFromSensor(float x) {
		const float ei800_Cut    = 0.004201;
		const float ei800_A      = 200.0;
		const float ei800_B      = -0.729169;
		const float ei800_C      = 0.247190;
		const float ei800_D      = 0.385537;
		const float ei800_E      = 193.235573;
		const float ei800_F      = -0.662201;
		const float ei800_ECutF  = 0.149658;
		
		const float ei200_Cut    = 0.004597;
		const float ei200_A      = 50.0;
		const float ei200_B      = -0.118740;
		const float ei200_C      = 0.266007;
		const float ei200_D      = 0.382478;
		const float ei200_E      = 51.986387;
		const float ei200_F      = -0.110339;
		const float ei200_ECutF  = 0.128643;

		float scale = 0.0625f;
		
		float lift = 0.00390631f; // To match Arri's sensor signal black
		float flare = 0.00012207f; // Arris flare to avoid clipping in blacks
		
		float linearRGB = x * (1.0f - lift) + lift;
		linearRGB += flare;
		
		// Encode each channel using LogC v3 EI 800
		float logEncoded;
		
		if (linearRGB > ei800_Cut) {
			return logEncoded = ei800_C * log10(ei800_A * linearRGB + ei800_B) + ei800_D;
		} else {
			return logEncoded = ei800_E * linearRGB + ei800_F;
		}
	}
	
	

	
	inline float3 applyCamToAWGMatrix(float3 rgb, constant Params &P) {

		
		
		// First matrix (from Params.camToAWG3)
		float r1 = P.camToAWG3[0].x * rgb.x +
				   P.camToAWG3[0].y * rgb.y +
				   P.camToAWG3[0].z * rgb.z;

		float g1 = P.camToAWG3[1].x * rgb.x +
				   P.camToAWG3[1].y * rgb.y +
				   P.camToAWG3[1].z * rgb.z;

		float b1 = P.camToAWG3[2].x * rgb.x +
				   P.camToAWG3[2].y * rgb.y +
				   P.camToAWG3[2].z * rgb.z;

		

		
		
		// Second fixed matrix
//		float r2 =  1.659196 * r1 + (-0.524579) * g1 + (-0.134618) * b1;
//		float g2 = (-0.625423) * r1 +  1.421150  * g1 +  0.204273  * b1;
//		float b2 = (-0.030082) * r1 +  0.066094  * g1 +  0.963988  * b1;

		return float3(r1, g1, b1);
	}
    
	inline float applyCamMul(float x, int channel, constant Params &P) {
		if (channel == 0) {
			return x * P.rMul;
		} else if (channel == 1) {
			return x * P.bMul;
		} else {
			return x;
		}
	}

	inline int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }
	
	// Returns: 0 = R, 1 = G, 2 = B
	inline ushort cfa_at(uint2 coord, ushort pattern)
	{
		uint x = coord.x & 1u; // parity of x (0 or 1)
		uint y = coord.y & 1u; // parity of y (0 or 1)

		switch (pattern)
		{
			case 0u: // RGGB
				// Row 0: R G
				// Row 1: G B
				if (y == 0) return (x == 0) ? 0u : 1u; // R or G
				else        return (x == 0) ? 1u : 2u; // G or B

			case 1u: // BGGR
				// Row 0: B G
				// Row 1: G R
				if (y == 0) return (x == 0) ? 2u : 1u; // B or G
				else        return (x == 0) ? 1u : 0u; // G or R

			case 2u: // GRBG
				// Row 0: G R
				// Row 1: B G
				if (y == 0) return (x == 0) ? 1u : 0u; // G or R
				else        return (x == 0) ? 2u : 1u; // B or G

			case 3u: // GBRG
				// Row 0: G B
				// Row 1: R G
				if (y == 0) return (x == 0) ? 1u : 2u; // G or B
				else        return (x == 0) ? 0u : 1u; // R or G

			default:
				return 1u; // default to G
		}
	}
	
	enum GType : ushort { G_RROW_BCOL=0, G_BROW_RCOL=1 };

	// Map (pat, x&1, y&1) -> GType (only meaningful when site==G)
	inline GType g_type(uint2 p, CFAPattern pat){
		const uint px = p.x & 1u, py = p.y & 1u;

		switch (pat) {
			case CFA_RGGB:
				// (0,0)=R (red row), (1,0)=G (red row, blue column),
				// (0,1)=G (blue row, red column), (1,1)=B
				return (py==0u) ? G_RROW_BCOL : G_BROW_RCOL;

			case CFA_BGGR:
				// (0,0)=B, (1,0)=G (blue row, red column),
				// (0,1)=G (red row, blue column), (1,1)=R
				return (py==0u) ? G_BROW_RCOL : G_RROW_BCOL;

			case CFA_GRBG:
				// row0: G R  (red in row0) ; row1: B G
				return (py==0u) ? G_RROW_BCOL : G_BROW_RCOL;

			case CFA_GBRG:
			default:
				// row0: G B  (blue in row0) ; row1: R G
				return (py==0u) ? G_BROW_RCOL : G_RROW_BCOL;
		}
	}
	
	inline float norm01(float raw, float black, float span) {
		return clamp((raw - black) / max(span, 1e-8f), 0.0f, 1.0f);
	}
		
		// MARK: - Blend highlights
		
		inline float3 blend_highlights_inline(float3 cam, float clipLevel, float rMul, float bMul) {
			
			if (clipLevel <= 16384.0f) {
				clipLevel /= 16384.0f;
			} else {
				clipLevel /= 65535.0f;
			}
			

			// compute per-channel clip thresholds
//			float clipRed   = clipLevel * rMul;
//			float clipGreen = clipLevel;       // G multiplier is always 1.0
//			float clipBlue  = clipLevel * bMul;
            
            
            float clipRed   = clipLevel / rMul;
            float clipGreen = clipLevel;       // G multiplier is always 1.0
            float clipBlue  = clipLevel / bMul;

			// clamp each channel individually
			float3 cam1 = float3(
				min(cam.r, clipRed),
				min(cam.g, clipGreen),
				min(cam.b, clipBlue)
			);

			// dcraw's 3×3 transform for 3-channel case
			const float3x3 trans = float3x3(
				float3( 1.0,         1.0,        1.0),
				float3( 1.7320508,  -1.7320508,  0.0),
				float3(-1.0,        -1.0,        2.0)
			);

			const float3x3 itrans = float3x3(
				float3( 1.0,  0.8660254, -0.5),
				float3( 1.0, -0.8660254, -0.5),
				float3( 1.0,  0.0,        1.0)
			);

			// convert to "lab" space (Y + two chroma components)
			float3 lab0 = trans * cam;   // unclipped
			float3 lab1 = trans * cam1;  // clipped

			// compute squared chroma magnitudes
			float sum0 = dot(lab0.yz, lab0.yz);
			float sum1 = dot(lab1.yz, lab1.yz);

			if (sum0 > 1e-8f) {
				// scale chroma magnitude to match clipped version
				float chratio = sqrt(sum1 / sum0);
				lab0.yz *= chratio;

				// inverse transform back to RGB and average over channels
				return (itrans * lab0) / 3.0;
			} else {
				// if no chroma, return original
				return cam;
			}
		}
		
		
	
	
	
	
	// MARK: - Linear
	kernel void demosaic_linear(
		texture2d<ushort, access::read>  inBayer       [[texture(0)]],
		texture2d<float,   access::write> outRGBA      [[texture(1)]],
		constant Params&                  P            [[buffer(0)]],
		constant Masks&                   M            [[buffer(1)]], // unused but kept for signature
		constant uint&                    leftMargin   [[buffer(2)]],
		constant uint&                    topMargin    [[buffer(3)]],
		threadgroup float*                tRaw         [[threadgroup(0)]],
		uint2                             tid          [[thread_position_in_threadgroup]],
		uint2                             tpg          [[threadgroup_position_in_grid]],
		uint2                             gid          [[thread_position_in_grid]],
		uint2                             tgSize       [[threads_per_threadgroup]])
	{
		const CFAPattern pat = CFAPattern(P.cfaPattern);
		const int apron = 1; // only need 1 pixel for bilinear
		const int core  = int(P.coreSize);
		const int tileW = core + 2*apron;
		const int tileH = core + 2*apron;

		const int W = int(inBayer.get_width());
		const int H = int(inBayer.get_height());

		const int coreX0 = int(tpg.x) * core;
		const int coreY0 = int(tpg.y) * core;
		const int tileX0 = coreX0 - apron;
		const int tileY0 = coreY0 - apron;

		float black = P.blackLevel;
		if (P.blackLevel == 0) {
			black = (P.blackLevelRed + P.blackLevelGreen + P.blackLevelBlue) / 3.0f;
		}

		// Load tile into shared memory, normalized to [0,1]
		for (int yy = int(tid.y); yy < tileH; yy += int(tgSize.y)) {
			const int gy = clampi(tileY0 + yy, 0, H - 1);
			for (int xx = int(tid.x); xx < tileW; xx += int(tgSize.x)) {
				const int gx = clampi(tileX0 + xx, 0, W - 1);
				ushort rawU16 = inBayer.read(uint2(gx, gy)).r;
			
				
				float max;
				
				// Scaling (16bit) - new (for arri sensor encoding)
				if (P.whiteLevel <= 16384.0f) {
					max = 16384.0f;
				} else {
					max = 65535.0f;
				}
				
				float norm = clamp((float(rawU16) - black) / max, 0.0f, 1.0f);
				
				tRaw[yy * tileW + xx] = norm;
			}
		}
		threadgroup_barrier(mem_flags::mem_threadgroup);

		if (gid.x >= W || gid.y >= H) return;
		if (tid.x >= core || tid.y >= core) return;

		// Coordinates inside tile
		const int lx = int(tid.x) + apron;
		const int ly = int(tid.y) + apron;

		// Sensor coordinates for CFA pattern
//			uint2 sensorCoord = gid + uint2(leftMargin, topMargin);
		uint2 sensorCoord = gid;
		const ushort site = cfa_at(sensorCoord, pat);

		float R=0.0f, G=0.0f, B=0.0f;

		// Simple bilinear: average available same-color neighbors
		if (site == 0u) { // R site
			R = tRaw[ly * tileW + lx];
			G = (tRaw[(ly-1)*tileW + lx] + tRaw[(ly+1)*tileW + lx] +
				 tRaw[ly*tileW + (lx-1)] + tRaw[ly*tileW + (lx+1)]) * 0.25f;
			B = (tRaw[(ly-1)*tileW + (lx-1)] + tRaw[(ly-1)*tileW + (lx+1)] +
				 tRaw[(ly+1)*tileW + (lx-1)] + tRaw[(ly+1)*tileW + (lx+1)]) * 0.25f;
		}
		else if (site == 2u) { // B site
			B = tRaw[ly * tileW + lx];
			G = (tRaw[(ly-1)*tileW + lx] + tRaw[(ly+1)*tileW + lx] +
				 tRaw[ly*tileW + (lx-1)] + tRaw[ly*tileW + (lx+1)]) * 0.25f;
			R = (tRaw[(ly-1)*tileW + (lx-1)] + tRaw[(ly-1)*tileW + (lx+1)] +
				 tRaw[(ly+1)*tileW + (lx-1)] + tRaw[(ly+1)*tileW + (lx+1)]) * 0.25f;
		}
		else { // G site
			G = tRaw[ly * tileW + lx];
			if (((sensorCoord.y & 1u) == 0u && (pat == CFA_RGGB || pat == CFA_GRBG)) ||
				((sensorCoord.y & 1u) == 1u && (pat == CFA_BGGR || pat == CFA_GBRG))) {
				// Green in red row
				R = (tRaw[ly * tileW + (lx-1)] + tRaw[ly * tileW + (lx+1)]) * 0.5f;
				B = (tRaw[(ly-1) * tileW + lx] + tRaw[(ly+1) * tileW + lx]) * 0.5f;
			} else {
				// Green in blue row
				R = (tRaw[(ly-1) * tileW + lx] + tRaw[(ly+1) * tileW + lx]) * 0.5f;
				B = (tRaw[ly * tileW + (lx-1)] + tRaw[ly * tileW + (lx+1)]) * 0.5f;
			}
		}


		float3 rgb = float3(R, G, B);

		
		rgb = blend_highlights_inline(rgb, P.whiteLevel, P.rMul, P.bMul);
		
		
		rgb = applyCamToAWGMatrix(rgb, P);

		/*
		 Straight encoding:
		 
		 rgb.x = encodeLogC(rgb.x);
		 rgb.y = encodeLogC(rgb.y);
		 rgb.z = encodeLogC(rgb.z);
		 
		 */

		// sensor encoding
		
		rgb.x = encodeArriFromSensor(rgb.x);
		rgb.y = encodeArriFromSensor(rgb.y);
		rgb.z = encodeArriFromSensor(rgb.z);

		outRGBA.write(float4(rgb, 1.0f), gid);
	}
	
	
    
    
    

    
//    inline ushort cfa_at(uint2 p, CFAPattern pat)
//    {
//        const uint px = p.x & 1u, py = p.y & 1u;
//        switch (pat) {
//            case CFA_RGGB: return (py==0u) ? (px==0u?0:1) : (px==0u?1:2); // 0:R,1:G,2:B
//            case CFA_BGGR: return (py==0u) ? (px==0u?2:1) : (px==0u?1:0);
//            case CFA_GRBG: return (py==0u) ? (px==0u?1:0) : (px==0u?2:1);
//            case CFA_GBRG:
//            default:       return (py==0u) ? (px==0u?1:2) : (px==0u?0:1);
//        }
//    }
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
    
    
    
    
    // 16×16 core, apron=2 (so tile = 20×20) – dynamic via threadgroup memory length
    kernel void demosaic_mhc_tiled_FIR(
                                       texture2d<ushort, access::read> inBayer        [[texture(0)]],
                                       texture2d<float,   access::write> outRGBA        [[texture(1)]],
                                       constant Params&                  P              [[buffer(0)]],
                                       constant Masks&                   M              [[buffer(1)]],
									   constant uint& leftMargin  [[buffer(2)]],  // Add these
									   constant uint& topMargin   [[buffer(3)]],  // Add these
                                       threadgroup float*                tRaw           [[threadgroup(0)]],
                                       uint2                             tid            [[thread_position_in_threadgroup]],
                                       uint2                             tpg            [[threadgroup_position_in_grid]],
                                       uint2                             gid            [[thread_position_in_grid]],
                                       uint2                             tgSize         [[threads_per_threadgroup]])
    {
        const CFAPattern pat = CFAPattern(P.cfaPattern);
        const int apron = 2;
        const int core  = int(P.coreSize);
        const int tileW = core + 2*apron;   // 16 + 4 = 20
        const int tileH = core + 2*apron;
        
        const int W = int(inBayer.get_width());
        const int H = int(inBayer.get_height());
        
        const int coreX0 = int(tpg.x) * core;
        const int coreY0 = int(tpg.y) * core;
        
        const int tileX0 = coreX0 - apron;
        const int tileY0 = coreY0 - apron;
		
		


		// Cooperative load with clamp, per your 3-step normalization
		for (int yy = int(tid.y); yy < tileH; yy += int(tgSize.y)) {
			const int gy = clampi(tileY0 + yy, 0, H - 1);
			for (int xx = int(tid.x); xx < tileW; xx += int(tgSize.x)) {
				const int gx = clampi(tileX0 + xx, 0, W - 1);

				// Read raw
				ushort rawU16 = inBayer.read(uint2(gx, gy)).r;

				// FIXED: Use sensor coordinates for CFA pattern detection
				uint2 sensorCoord = uint2(gx + leftMargin, gy + topMargin);
				const ushort s = cfa_at(sensorCoord, pat);

//				// Step 1: subtract global + per-channel black
//				float perChanBlack =
//					  (s == 0u) ? P.blackLevelRed
//					: (s == 2u) ? P.blackLevelBlue
//								: P.blackLevelGreen;


//				float lin = float(rawU16) - perChanBlack;
				float lin = float(rawU16);

				// Step 2: scale by cam_mul for this channel
				float wb = (s == 0u) ? P.rMul
						 : (s == 2u) ? P.bMul
									 : 1.0;
//				lin *= wbDebug;


//				const float max = P.whiteLevel;
				
				
				// Step 3: divide by 14-bit max (we'll handle 16-bit later)
				const float denom14 = P.whiteLevel;
				float v = lin / denom14;

				// Clamp to [0,1] to keep kernels well-behaved
				tRaw[yy * tileW + xx] = clamp(v, 0.0f, 1.0f);
			}
		}
		threadgroup_barrier(mem_flags::mem_threadgroup);
        
        if (int(gid.x) >= W || int(gid.y) >= H) return;
        if (int(tid.x) >= core || int(tid.y) >= core) return;
        
        // Local coords inside tile
        const int lx = int(tid.x) + apron;
        const int ly = int(tid.y) + apron;
        
        // Build 5×5 window into thread-local array
        float W5x5[25];
        {
            int k = 0;
            int base = (ly - 2) * tileW + (lx - 2);
            // row 0
            W5x5[k++] = tRaw[base+0]; W5x5[k++] = tRaw[base+1]; W5x5[k++] = tRaw[base+2]; W5x5[k++] = tRaw[base+3]; W5x5[k++] = tRaw[base+4];
            // row 1
            base += tileW;
            W5x5[k++] = tRaw[base+0]; W5x5[k++] = tRaw[base+1]; W5x5[k++] = tRaw[base+2]; W5x5[k++] = tRaw[base+3]; W5x5[k++] = tRaw[base+4];
            // row 2
            base += tileW;
            W5x5[k++] = tRaw[base+0]; W5x5[k++] = tRaw[base+1]; W5x5[k++] = tRaw[base+2]; W5x5[k++] = tRaw[base+3]; W5x5[k++] = tRaw[base+4];
            // row 3
            base += tileW;
            W5x5[k++] = tRaw[base+0]; W5x5[k++] = tRaw[base+1]; W5x5[k++] = tRaw[base+2]; W5x5[k++] = tRaw[base+3]; W5x5[k++] = tRaw[base+4];
            // row 4
            base += tileW;
            W5x5[k++] = tRaw[base+0]; W5x5[k++] = tRaw[base+1]; W5x5[k++] = tRaw[base+2]; W5x5[k++] = tRaw[base+3]; W5x5[k++] = tRaw[base+4];
        }
        
        const float centerN = tRaw[ly * tileW + lx];

		
//		uint2 sensorCoord = gid + uint2(leftMargin, topMargin);
		uint2 sensorCoord = gid /*+ uint2(leftMargin, topMargin)*/;
		const ushort site = cfa_at(sensorCoord, pat);

		// Orientation for G-sites - also use sensor coordinates
		bool gInRRow = false;
        if (site == 1u) {
			const uint yParity = sensorCoord.y & 1u;  // Use sensorCoord instead of gid
            switch (pat) {
                case CFA_RGGB: gInRRow = (yParity == 0u); break;
                case CFA_BGGR: gInRRow = (yParity == 1u); break;
                case CFA_GRBG: gInRRow = (yParity == 0u); break;
                case CFA_GBRG: gInRRow = (yParity == 1u); break;
            }
        }
        
        // Dot helper
        auto dotMask = [&](thread const float* win, constant float* mask) -> float {
            float s = 0.0f;
#pragma unroll
            for (int i=0; i<25; ++i) s = fma(win[i], mask[i], s);
            return s;
        };
        
		// REMOVE this helper entirely
		// auto wbScale = [&](float value, ushort chan) -> float { ... };

		float R=0.0f, G=0.0f, B=0.0f;

		if (site == 0u) {           // R site
			R = centerN;
			G = dotMask(W5x5, &M.G_at_R[0]);
			B = dotMask(W5x5, &M.B_at_R[0]);
		}
		else if (site == 2u) {      // B site
			B = centerN;
			G = dotMask(W5x5, &M.G_at_B[0]);
			R = dotMask(W5x5, &M.R_at_B[0]);
		}
		else {                      // G site
			GType t = g_type(sensorCoord, pat);
			G = centerN;
			if (t == G_RROW_BCOL) {
				R = dotMask(W5x5, &M.R_at_G_Rrow[0]);
				B = dotMask(W5x5, &M.B_at_G_Rrow[0]);
			} else {
				R = dotMask(W5x5, &M.R_at_G_Brow[0]);
				B = dotMask(W5x5, &M.B_at_G_Brow[0]);
			}
		}
		
		float3 rgb = float3(R, G, B);
		rgb = applyCamToAWGMatrix(rgb, P);

		// Optional debug display transform
		rgb.x = encodeLogC(rgb.x);
		rgb.y = encodeLogC(rgb.y);
		rgb.z = encodeLogC(rgb.z);

		outRGBA.write(float4(rgb, 1.0f), gid);
    }
		
		
		// MARK: - Linear
		
		inline float avgSameSite(
			int lx, int ly, int tileW, int tileH,
			uint2 sensorCoord, ushort pattern, ushort targetSite,
			threadgroup float* tRaw)
		{
			float sum = 0.0f;
			int count = 0;

			// 4-connected neighbors
			const int offsets[4][2] = { {0,-1}, {0,1}, {-1,0}, {1,0} };

			for (int i = 0; i < 4; ++i) {
				int nx = lx + offsets[i][0];
				int ny = ly + offsets[i][1];
				uint2 nCoord = uint2(sensorCoord.x + offsets[i][0], sensorCoord.y + offsets[i][1]);

				if (nx >= 0 && nx < tileW && ny >= 0 && ny < tileH) {
					if (cfa_at(nCoord, pattern) == targetSite) {
						sum += tRaw[ny * tileW + nx];
						count++;
					}
				}
			}

			return (count > 0) ? (sum / float(count)) : 0.0f;
		}

		inline float avgDiagSameSite(
			int lx, int ly, int tileW, int tileH,
			uint2 sensorCoord, ushort pattern, ushort targetSite,
			threadgroup float* tRaw)
		{
			float sum = 0.0f;
			int count = 0;

			// Diagonal neighbors
			const int offsets[4][2] = { {-1,-1}, {1,-1}, {-1,1}, {1,1} };

			for (int i = 0; i < 4; ++i) {
				int nx = lx + offsets[i][0];
				int ny = ly + offsets[i][1];
				uint2 nCoord = uint2(sensorCoord.x + offsets[i][0], sensorCoord.y + offsets[i][1]);

				if (nx >= 0 && nx < tileW && ny >= 0 && ny < tileH) {
					if (cfa_at(nCoord, pattern) == targetSite) {
						sum += tRaw[ny * tileW + nx];
						count++;
					}
				}
			}

			return (count > 0) ? (sum / float(count)) : 0.0f;
		}
		
		
		
	
		
		
		
		
		
		// MARK: - Debug
    
		// DEBUG VERSION 1: Show what CFA sites are detected during the tiling process
		kernel void demosaic_debug_threadgroup_cfa(
			texture2d<ushort, access::read> inBayer        [[texture(0)]],
			texture2d<float,   access::write> outRGBA        [[texture(1)]],
			constant Params&                  P              [[buffer(0)]],
			constant Masks&                   M              [[buffer(1)]],
			constant uint& leftMargin  [[buffer(2)]],
			constant uint& topMargin   [[buffer(3)]],
			threadgroup float*                tRaw           [[threadgroup(0)]],
			uint2                             tid            [[thread_position_in_threadgroup]],
			uint2                             tpg            [[threadgroup_position_in_grid]],
			uint2                             gid            [[thread_position_in_grid]],
			uint2                             tgSize         [[threads_per_threadgroup]])
		{
			const CFAPattern pat = CFAPattern(P.cfaPattern);
			const int apron = 2;
			const int core  = int(P.coreSize);
			const int tileW = core + 2*apron;
			const int tileH = core + 2*apron;
			
			const int W = int(inBayer.get_width());
			const int H = int(inBayer.get_height());
			
			const int coreX0 = int(tpg.x) * core;
			const int coreY0 = int(tpg.y) * core;
			const int tileX0 = coreX0 - apron;
			const int tileY0 = coreY0 - apron;

			// EXACT same cooperative loading as your original
			for (int yy = int(tid.y); yy < tileH; yy += int(tgSize.y)) {
				const int gy = clampi(tileY0 + yy, 0, H - 1);
				for (int xx = int(tid.x); xx < tileW; xx += int(tgSize.x)) {
					const int gx = clampi(tileX0 + xx, 0, W - 1);

					// Read raw
					ushort rawU16 = inBayer.read(uint2(gx, gy)).r;

					// Check CFA site with BOTH coordinate systems - for comparison
					uint2 visibleCoord = uint2(gx, gy);
					uint2 sensorCoord = uint2(gx + leftMargin, gy + topMargin);
					
					const ushort siteVisible = cfa_at(visibleCoord, pat);
					const ushort siteSensor = cfa_at(sensorCoord, pat);

					// Apply normalization using the SENSOR coordinate CFA site
					float perChanBlack = (siteSensor == 0u) ? P.blackLevelRed
									  : (siteSensor == 2u) ? P.blackLevelBlue
														  : P.blackLevelGreen;

					float lin = float(rawU16) - perChanBlack;
					float wb = (siteSensor == 0u) ? P.rMul
							 : (siteSensor == 2u) ? P.bMul
												 : 1.0;
					lin *= wb;
					float v = lin / P.whiteLevel;

					// Store the coordinate difference as a debug value
					// If sites match: store normalized value
					// If sites differ: store a debug pattern
					if (siteVisible == siteSensor) {
						tRaw[yy * tileW + xx] = clamp(v, 0.0f, 1.0f);
					} else {
						// Store a high value to indicate coordinate mismatch
						tRaw[yy * tileW + xx] = 2.0f; // This will show up as bright areas
					}
				}
			}
			threadgroup_barrier(mem_flags::mem_threadgroup);
			
			if (int(gid.x) >= W || int(gid.y) >= H) return;
			if (int(tid.x) >= core || int(tid.y) >= core) return;
			
			// Local coords inside tile
			const int lx = int(tid.x) + apron;
			const int ly = int(tid.y) + apron;
			
			const float centerN = tRaw[ly * tileW + lx];
			
			// Show the debug result
			uint2 sensorCoord = gid + uint2(leftMargin, topMargin);
			const ushort site = cfa_at(sensorCoord, pat);
			
			float3 rgb = float3(0.0f);
			
			if (centerN > 1.5f) {
				// Coordinate mismatch detected - show as bright magenta
				rgb = float3(1.0f, 0.0f, 1.0f);
			} else {
				// Normal CFA pattern display
				if (site == 0u) {       // Red pixel
					rgb = float3(centerN, 0.0f, 0.0f);
				} else if (site == 2u) { // Blue pixel
					rgb = float3(0.0f, 0.0f, centerN);
				} else {                // Green pixel
					rgb = float3(0.0f, centerN, 0.0f);
				}
			}
			
			outRGBA.write(float4(rgb, 1.0f), gid);
		}

		// DEBUG VERSION 2: Show coordinate mapping differences in threadgroup context
		kernel void demosaic_debug_threadgroup_coords(
			texture2d<ushort, access::read> inBayer        [[texture(0)]],
			texture2d<float,   access::write> outRGBA        [[texture(1)]],
			constant Params&                  P              [[buffer(0)]],
			constant Masks&                   M              [[buffer(1)]],
			constant uint& leftMargin  [[buffer(2)]],
			constant uint& topMargin   [[buffer(3)]],
			threadgroup float*                tRaw           [[threadgroup(0)]],
			uint2                             tid            [[thread_position_in_threadgroup]],
			uint2                             tpg            [[threadgroup_position_in_grid]],
			uint2                             gid            [[thread_position_in_grid]],
			uint2                             tgSize         [[threads_per_threadgroup]])
		{
			const CFAPattern pat = CFAPattern(P.cfaPattern);
			const int apron = 2;
			const int core  = int(P.coreSize);
			const int tileW = core + 2*apron;
			const int tileH = core + 2*apron;
			
			const int W = int(inBayer.get_width());
			const int H = int(inBayer.get_height());
			
			if (int(gid.x) >= W || int(gid.y) >= H) return;
			if (int(tid.x) >= core || int(tid.y) >= core) return;
			
			// Test all coordinate calculations
			uint2 visibleCoord = gid;
			uint2 sensorCoord = gid + uint2(leftMargin, topMargin);
			
			// Also test the threadgroup-based coordinates
			const int coreX0 = int(tpg.x) * core;
			const int coreY0 = int(tpg.y) * core;
			uint2 tgCoord = uint2(coreX0 + int(tid.x), coreY0 + int(tid.y));
			uint2 tgSensorCoord = tgCoord + uint2(leftMargin, topMargin);
			
			// Get CFA sites for all coordinate systems
			ushort siteVisible = cfa_at(visibleCoord, pat);
			ushort siteSensor = cfa_at(sensorCoord, pat);
			ushort siteTG = cfa_at(tgCoord, pat);
			ushort siteTGSensor = cfa_at(tgSensorCoord, pat);
			
			float3 rgb = float3(0.0f);
			
			// Color code the results
			if (siteVisible == siteSensor && siteTG == siteTGSensor && siteVisible == siteTG) {
				// All coordinate systems agree - show as gray
				rgb = float3(0.5f, 0.5f, 0.5f);
			} else {
				// Some disagreement - use different colors to show what's wrong
				if (siteVisible != siteSensor) rgb.r = 1.0f;  // Red = visible vs sensor mismatch
				if (siteTG != siteTGSensor) rgb.g = 1.0f;     // Green = threadgroup coordinate issues
				if (siteVisible != siteTG) rgb.b = 1.0f;      // Blue = gid vs threadgroup calc mismatch
			}
			
			outRGBA.write(float4(rgb, 1.0f), gid);
		}
