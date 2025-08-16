//
//  PerlinNoise.metal
//  ColorForge
//
//  Created by Ben Quinton on 24/07/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "GlobalHelperFunctions.ci.metal"


using namespace metal;


// MARK: - Helpers

float3 mod289(float3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

float4 taylorInvSqrt(float4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}



float3 fade(float3 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float pnoise(float3 P, float3 rep) {
    float3 Pi0 = fmod(floor(P), rep);               // Integer part, modulo period
    float3 Pi1 = fmod(Pi0 + 1.0, rep);              // Integer part + 1, modulo period
    Pi0 = mod289(Pi0);
    Pi1 = mod289(Pi1);
    
    float3 Pf0 = fract(P);                          // Fractional part
    float3 Pf1 = Pf0 - 1.0;

    float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    float4 iy = float4(Pi0.yy, Pi1.yy);
    float4 iz0 = Pi0.zzzz;
    float4 iz1 = Pi1.zzzz;

    float4 ixy = permute(permute(ix) + iy);
    float4 ixy0 = permute(ixy + iz0);
    float4 ixy1 = permute(ixy + iz1);

    float4 gx0 = fract(ixy0 * (1.0 / 7.0));
    float4 gy0 = fract(floor(ixy0 * (1.0 / 7.0)) * (1.0 / 7.0)) - 0.5;
    float4 gz0 = 0.5 - abs(gx0) - abs(gy0);
    float4 sz0 = step(gz0, float4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);

    float4 gx1 = fract(ixy1 * (1.0 / 7.0));
    float4 gy1 = fract(floor(ixy1 * (1.0 / 7.0)) * (1.0 / 7.0)) - 0.5;
    float4 gz1 = 0.5 - abs(gx1) - abs(gy1);
    float4 sz1 = step(gz1, float4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);

    float3 g000 = float3(gx0.x, gy0.x, gz0.x);
    float3 g100 = float3(gx0.y, gy0.y, gz0.y);
    float3 g010 = float3(gx0.z, gy0.z, gz0.z);
    float3 g110 = float3(gx0.w, gy0.w, gz0.w);
    float3 g001 = float3(gx1.x, gy1.x, gz1.x);
    float3 g101 = float3(gx1.y, gy1.y, gz1.y);
    float3 g011 = float3(gx1.z, gy1.z, gz1.z);
    float3 g111 = float3(gx1.w, gy1.w, gz1.w);

    float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
    g000 *= norm0.x;
    g010 *= norm0.y;
    g100 *= norm0.z;
    g110 *= norm0.w;

    float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
    g001 *= norm1.x;
    g011 *= norm1.y;
    g101 *= norm1.z;
    g111 *= norm1.w;

    float n000 = dot(g000, Pf0);
    float n100 = dot(g100, float3(Pf1.x, Pf0.yz));
    float n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
    float n110 = dot(g110, float3(Pf1.xy, Pf0.z));
    float n001 = dot(g001, float3(Pf0.xy, Pf1.z));
    float n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
    float n011 = dot(g011, float3(Pf0.x, Pf1.yz));
    float n111 = dot(g111, Pf1);

    float3 fade_xyz = fade(Pf0);
    float4 n_z = mix(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
    float2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);

    return 2.2 * n_xyz;
}


// MARK: - CoreImage Kernel

extern "C" {
    
    float4 maskPerlinNoise(coreimage::sample_t s, coreimage::sample_t n, coreimage::sample_t g, float blend) {
        float3 rgb = s.rgb;
        float3 noise = n.rgb;
        float3 base = g.rgb; // Gradient
        float3 black = float3(0.0);
        
        base = mix(black, base, noise);

        float3 blended = rgb + base;
        
        float3 result = mix(rgb, blended, (blend / 100.0));
        
        return float4(result, 1.0);
    }
    
    
    float4 perlinNoise(coreimage::sample_t s,
                       float width, float height,
                             float scale,  // 0–100
                             float offsetX,
                             float offsetY,
                             coreimage::destination dest) {
        
        float2 uv = dest.coord();
        float2 offset = float2(offsetX, offsetY);
        
        float minWavelength = width / 10.0;
        float maxWavelength = width * 0.7;
        float wavelength = mix(minWavelength, maxWavelength, clamp(scale / 100.0, 0.0, 1.0));
        float frequency = 1.0 / wavelength;

        uv *= frequency;
        uv += offset;
        
        float3 p = float3(uv.x, uv.y, 0.0);
        float3 rep = float3(10000.0);
        
        float n = pnoise(p, rep);
        n = n * 0.5 + 0.5;
        
        // Clamp Coords
        float2 coord = dest.coord();
        if (coord.x < 0.0 || coord.x >= width || coord.y < 0.0 || coord.y >= height) {
            return float4(0.0);              // Transparent outside the extent
        }
        
        return float4(n, n, n, 1.0);
    }
    
    float4 perlinNoiseColorGradient(coreimage::sample_t s,
                       float width, float height,
                             float scale,  // 0–100
                             float offsetX,
                             float offsetY,
                             float amount,
                             coreimage::destination dest) {
        
        float3 rgb = s.rgb;
        
        // Perlin Noise Setup
        float2 uv = dest.coord();
        float2 offset = float2(offsetX, offsetY);
        
        float minWavelength = width / 10.0;
        float maxWavelength = width * 0.7;
        float wavelength = mix(minWavelength, maxWavelength, clamp(scale / 100.0, 0.0, 1.0));
        float frequency = 1.0 / wavelength;

        uv *= frequency;
        uv += offset;
        
        float3 p = float3(uv.x, uv.y, 0.0);
        float3 rep = float3(10000.0);
        
        float n = pnoise(p, rep);
        n = n * 0.5 + 0.5;
        
        
        // Second Perlin Noise (larger for masking)
        float frequency2 = 1.0 / width * 0.5;
        float2 uv2 = dest.coord();
        uv2 *= frequency2;
        uv2 += offset * 2.0;
        float3 p2 = float3(uv2.x, uv2.y, 0.0);
        float3 rep2 = float3(10000.0);
        float n2 = pnoise(p2, rep2);
        n2 = (n2 * 0.5 + 0.5);
        n2 = (n2 + 0.5) / (1.0 - n2);
        n2 = clamp(0.0, 1.0, n2);
        
        
        // Gradient Setup
        float2 uv3 = dest.coord();
        float2 startPoint = float2(width * 0.2, height * 0.1);
        float2 endPoint = float2(width * 0.9, height * 0.8);
        float3 startColor = float3(0.0, 0.13, 0.03);
        float3 endColor = float3(0.01, 0.03, 0.13);
        
        float2 dir = endPoint - startPoint;
        float len = length(dir);
        float2 dirNorm = dir / len;
        
        // Project current pixel onto the gradient line
        float t = dot(uv3 - startPoint, dirNorm) / len;
        
        // Clamp so we don't go beyond start/end
        t = clamp(t, 0.0, 1.0);
        
        
        
        float3 gradient = mix(startColor, endColor, t);
        float3 base = float3(0.0);
        base = mix(base, gradient, n); // Apply first noise mask
        float3 base2 = float3(0.0);
        base2 = mix(base2, base, n2);
        
        float3 blended = rgb + base;
        
        rgb = mix(rgb, blended, amount / 100.0);
        
        
        
        // Clamp Coords
        float2 coord = dest.coord();
        if (coord.x < 0.0 || coord.x >= width || coord.y < 0.0 || coord.y >= height) {
            return float4(1.0);              // Transparent outside the extent
        }
        
        return float4(rgb, 1.0);
    }
    
    
    float4 perlinNoiseMix(coreimage::sample_t s,
                          coreimage::sample_t t,
                          coreimage::sample_t u,
                          float waveLength,
                          coreimage::destination dest) {
        
        float3 noise1 = s.rgb;
        float3 noise2 = t.rgb;
        float3 noise3 = u.rgb;
        
        float3 result = float3(0.5, 0.5, 0.5);
        
        float2 baseUV = dest.coord();
        float3 rep = float3(10000.0);
        
        float nValues[3];
        
        // Loop over three passes
        for (int pass = 0; pass < 3; pass++) {
            float frequency = 1.0 / waveLength;
            
            float2 uv = baseUV * frequency;
            uv += float2(pass * 10.0, pass * 20.0); // offset per pass
            
            float3 p = float3(uv.x, uv.y, pass * 50.0); // z-offset per pass
            float n = pnoise(p, rep);
            n = n * 0.5 + 0.5; // normalize to 0–1
            
            waveLength += 0.001;
            nValues[pass] = n;
        }
        
        noise1 *= nValues[0];
        noise2 *= nValues[1];
        noise3 *= nValues[2];
        
        noise1 = noise1 * (1.0 - 0.5) + 0.5;
        noise2 = noise2 * (1.0 - 0.5) + 0.5;
        noise3 = noise3 * (1.0 - 0.5) + 0.5;
        
        
        result = mix(result, noise1, nValues[0]);
        result = mix(result, noise2, nValues[1]);
        result = mix(result, noise3, nValues[2]);
        
        float3 unchangedResult = result;
        
        // Convert result to arri gamma
        result -= (0.5 - 0.459);
        result = pow(result, 2.2);
        result = encodeLogCFloat3(result);
        result += (0.5 - 0.396);
        
        result = mix(unchangedResult, result, 0.2);
        
        return float4(result, 1.0);
    }

	// Simple hash → random 0–1
	inline float random1(float2 st) {
		return fract(sin(dot(st, float2(12.9898,78.233))) * 43758.5453);
	}

	// Make it a float2 in range [0, maxVal)
	inline float2 random2(float2 st, float maxVal) {
		return float2(random1(st), random1(st.yx + 3.1)) * maxVal;
	}
	
	
	// x,y: frame-constant random offset you pass from Swift (0..50)
	// length: some scene scale you use (keep your 0.004 factor if you like)
	float4 perlinNoiseSmall(coreimage::sample_t s,
							float length,
							float x,
							float y,
							float width,
							float height,
                            float waveLengthRand,
							coreimage::destination dest)
	{
		float2 px   = dest.coord();     // pixel coords
		float2 size = float2(width, height);      // image size in pixels
		float2 uv   = px / size;        // 0..1, continuous

		// Wavelength in *pixels* for the noise (keep it comfortably > 1 px)
		float wavePx = max(1.5, waveLengthRand * length);

		// Convert normalized uv to Perlin "lattice units":
		// cellsAcross = shortestDim / wavePx  (how many cells across the image)
		float cellsAcross = (min(size.x, size.y) / wavePx);

		// Non-integer tweak to avoid locking to the pixel grid
		cellsAcross *= 1.037;

		// Build the noise point (in lattice units) and add a frame-constant offset
		float2 p2 = uv * cellsAcross + float2(x, y);

		float n = pnoise(float3(p2, 0.0), float3(100000.0));
		n = n * 0.5 + 0.5;

		return float4(n, n, n, 1.0);
	}
	
	
	float4 perlinNoiseSmallRandom(coreimage::sample_t s,
							float length,
							float x,
							float y,
							coreimage::destination dest) {
		
		float2 uv = dest.coord();
		
		float waveLength = 0.01 * length;
		
		float frequency = 1.0 / waveLength;
		
		// Add random float2 between 0 and 50
		float2 randOffset = random2(uv, 50.0);
		uv += randOffset;
		
		uv *= frequency;
		
		float3 p = float3(uv.x, uv.y, 0.0);
		float3 rep = float3(10000.0);
		
		float n = pnoise(p, rep);
		n = n * 0.5 + 0.5;
		
		return float4(n, n, n, 1.0);
	}
    
	
	
	
}
