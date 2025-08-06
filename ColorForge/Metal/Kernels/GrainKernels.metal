//
//  GrainKernels.metal
//  ColorForge
//
//  Created by Ben Quinton on 10/07/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "GlobalHelperFunctions.metal"
using namespace metal;



//
//
//float3 mod289(float3 x) {
//    return x - floor(x * (1.0 / 289.0)) * 289.0;
//}
//
//float4 mod289(float4 x) {
//    return x - floor(x * (1.0 / 289.0)) * 289.0;
//}
//
//float4 permute(float4 x) {
//    return mod289(((x * 34.0) + 1.0) * x);
//}
//
//float4 taylorInvSqrt(float4 r) {
//    return 1.79284291400159 - 0.85373472095314 * r;
//}
//
//float snoise(float3 v) {
//    float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
//    float4 D = float4(0.0, 0.5, 1.0, 2.0);
//
//    // First corner
//    float3 i = floor(v + dot(v, C.yyy));
//    float3 x0 = v - i + dot(i, C.xxx);
//
//    // Other corners
//    float3 g = step(x0.yzx, x0.xyz);
//    float3 l = 1.0 - g;
//    float3 i1 = min(g.xyz, l.zxy);
//    float3 i2 = max(g.xyz, l.zxy);
//
//    float3 x1 = x0 - i1 + C.xxx;
//    float3 x2 = x0 - i2 + C.yyy;
//    float3 x3 = x0 - D.yyy;
//
//    // Permutations
//    i = mod289(i);
//    float4 p = permute(permute(permute(
//                i.z + float4(0.0, i1.z, i2.z, 1.0)) +
//                i.y + float4(0.0, i1.y, i2.y, 1.0)) +
//                i.x + float4(0.0, i1.x, i2.x, 1.0));
//
//    float n_ = 0.142857142857; // 1.0/7.0
//    float3 ns = n_ * D.wyz - D.xzx;
//
//    float4 j = p - 49.0 * floor(p * ns.z * ns.z);
//
//    float4 x_ = floor(j * ns.z);
//    float4 y_ = floor(j - 7.0 * x_);
//
//    float4 x = x_ * ns.x + ns.yyyy;
//    float4 y = y_ * ns.x + ns.yyyy;
//    float4 h = 1.0 - abs(x) - abs(y);
//
//    float4 b0 = float4(x.xy, y.xy);
//    float4 b1 = float4(x.zw, y.zw);
//
//    float4 s0 = floor(b0) * 2.0 + 1.0;
//    float4 s1 = floor(b1) * 2.0 + 1.0;
//    float4 sh = -step(h, float4(0.0));
//
//    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
//    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
//
//    float3 p0 = float3(a0.xy, h.x);
//    float3 p1 = float3(a0.zw, h.y);
//    float3 p2 = float3(a1.xy, h.z);
//    float3 p3 = float3(a1.zw, h.w);
//
//    float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
//    p0 *= norm.x;
//    p1 *= norm.y;
//    p2 *= norm.z;
//    p3 *= norm.w;
//
//    float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
//    m = m * m;
//
//    return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
//}
//
//
//
//float3 fade(float3 t) {
//    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
//}
//
//float pnoise(float3 P, float3 rep) {
//    float3 Pi0 = fmod(floor(P), rep);               // Integer part, modulo period
//    float3 Pi1 = fmod(Pi0 + 1.0, rep);              // Integer part + 1, modulo period
//    Pi0 = mod289(Pi0);
//    Pi1 = mod289(Pi1);
//    
//    float3 Pf0 = fract(P);                          // Fractional part
//    float3 Pf1 = Pf0 - 1.0;
//
//    float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
//    float4 iy = float4(Pi0.yy, Pi1.yy);
//    float4 iz0 = Pi0.zzzz;
//    float4 iz1 = Pi1.zzzz;
//
//    float4 ixy = permute(permute(ix) + iy);
//    float4 ixy0 = permute(ixy + iz0);
//    float4 ixy1 = permute(ixy + iz1);
//
//    float4 gx0 = fract(ixy0 * (1.0 / 7.0));
//    float4 gy0 = fract(floor(ixy0 * (1.0 / 7.0)) * (1.0 / 7.0)) - 0.5;
//    float4 gz0 = 0.5 - abs(gx0) - abs(gy0);
//    float4 sz0 = step(gz0, float4(0.0));
//    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
//    gy0 -= sz0 * (step(0.0, gy0) - 0.5);
//
//    float4 gx1 = fract(ixy1 * (1.0 / 7.0));
//    float4 gy1 = fract(floor(ixy1 * (1.0 / 7.0)) * (1.0 / 7.0)) - 0.5;
//    float4 gz1 = 0.5 - abs(gx1) - abs(gy1);
//    float4 sz1 = step(gz1, float4(0.0));
//    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
//    gy1 -= sz1 * (step(0.0, gy1) - 0.5);
//
//    float3 g000 = float3(gx0.x, gy0.x, gz0.x);
//    float3 g100 = float3(gx0.y, gy0.y, gz0.y);
//    float3 g010 = float3(gx0.z, gy0.z, gz0.z);
//    float3 g110 = float3(gx0.w, gy0.w, gz0.w);
//    float3 g001 = float3(gx1.x, gy1.x, gz1.x);
//    float3 g101 = float3(gx1.y, gy1.y, gz1.y);
//    float3 g011 = float3(gx1.z, gy1.z, gz1.z);
//    float3 g111 = float3(gx1.w, gy1.w, gz1.w);
//
//    float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
//    g000 *= norm0.x;
//    g010 *= norm0.y;
//    g100 *= norm0.z;
//    g110 *= norm0.w;
//
//    float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
//    g001 *= norm1.x;
//    g011 *= norm1.y;
//    g101 *= norm1.z;
//    g111 *= norm1.w;
//
//    float n000 = dot(g000, Pf0);
//    float n100 = dot(g100, float3(Pf1.x, Pf0.yz));
//    float n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
//    float n110 = dot(g110, float3(Pf1.xy, Pf0.z));
//    float n001 = dot(g001, float3(Pf0.xy, Pf1.z));
//    float n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
//    float n011 = dot(g011, float3(Pf0.x, Pf1.yz));
//    float n111 = dot(g111, Pf1);
//
//    float3 fade_xyz = fade(Pf0);
//    float4 n_z = mix(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
//    float2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
//    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
//
//    return 2.2 * n_xyz;
//}
//
//float randomFromFloat(float x) {
//    return fract(sin(x * 12.9898) * 43758.5453);
//}
//
//
//float perlin(float2 texCoord, float2 resolution, float gridSize, float repeatDistance) {
//    float2 uv = texCoord / resolution;
//
//    float2 scaledUV = uv * gridSize;
//    
//    
//
//    // Now we repeat only every `repeatDistance` noise units (which can be much larger than gridSize)
//    float3 rep = float3(repeatDistance, repeatDistance, repeatDistance);
//
//    float3 noiseCoord = float3(scaledUV, 0.0);
//
//    float n = pnoise(noiseCoord, rep); // still periodic, but over a longer span
//    return n * 0.5 + 0.5;
//}

//float perlin(float2 texCoord, float2 resolution, float gridSize) {
//	float2 uv = texCoord / resolution;
//
//	float2 scaledUV = uv * gridSize;
//	
//	// Frequency of repetition: higher = more tiling (smaller grain)
//	float3 rep = float3(gridSize, gridSize, gridSize);
//
//	// Just use a fixed z value, or time/frame if animated
//	float3 noiseCoord = float3(scaledUV, 0.0);
//
//	float n = pnoise(noiseCoord, rep); // returns [-1, 1]
//	return n * 0.5 + 0.5;              // normalize to [0, 1]
//}

//float grain(float2 texCoord, float2 resolution, float gridSize) {
//	// Normalize to [0, 1]
//	float2 uv = texCoord / resolution;
//
//	// Scale UVs by grid size (grain frequency)
//	float2 scaledUV = uv * gridSize;
//
//	// Use simplex noise to compute an offset in the Z direction
//	// Use lower frequency input to snoise to keep offset stable
//	float zOffset = snoise(float3(uv * (gridSize * 0.1), 0.0)); // scale down to reduce visual harshness
//
//	float3 noiseCoord = float3(scaledUV, zOffset); // apply offset in Z
//
//	float3 rep = float3(gridSize, gridSize, 1.0); // fixed periodicity
//
//	float n = pnoise(noiseCoord, rep); // [-1, 1]
//	return n * 0.5 + 0.5;              // [0, 1]
//}


//
//float grain(float2 texCoord, float2 resolution) {
//  float2 mult = texCoord * resolution;
//    float offset = snoise(float3(mult, 0));
//    float n1 = pnoise(float3(mult, offset), float3(1.0/texCoord * resolution, 1.0));
//  return n1 / 2.0 + 0.5;
//}



//float grain( texCoord, float2 resolution) {
//    float2 mult = texCoord * resolution;
//    float offset = snoise(float3(mult / 2.5, 0.0)); // equivalent to default multiplier
//    float3 rep = float3(1.0 / texCoord * resolution, 1.0);
//    float n1 = pnoise(float3(mult, offset), rep);
//    return n1 * 0.5 + 0.5;
//}


// MARK: - Main CoreImage

inline float softLight(float background, float foreground) {
    float blended = sqrt(background) * (2.0 * foreground - 1.0) + 2.0 * background * (1.0 - foreground);
    return mix(blended, background, step(foreground, 0.5));
}

extern "C" {
    
    float3 toneMapToDisplay(float3 rgb) {
        float blackPoint = 0.0;
        float whitePoint = 1.0;
        float toneMapVal = 0.82;
        
        rgb = decodeLogCFloat3(rgb); // make linear
        
        
        rgb.r = whitePoint * (rgb.r / (rgb.r + toneMapVal)) + blackPoint;
        rgb.g = whitePoint * (rgb.g / (rgb.g + toneMapVal)) + blackPoint;
        rgb.b = whitePoint * (rgb.b / (rgb.b + toneMapVal)) + blackPoint;
        
        float3 gamma22 = pow(rgb, (1.0 / 2.2));
        
        return gamma22;
    }
////    	float perlinNoise = perlin(uv, resolution, size);
//    float randomFromSeed(float seed) {
//        return fract(sin(seed * 12.9898) * 43758.5453);
//    }
//	
//	// Perlin Noise Test
//	float4 filmGrain3D(coreimage::sample_t s, float width, float height, float size, coreimage::destination dest) {
//		
//		float2 uv = dest.coord(); // pixel coords
//        
//        float rand = randomFromSeed(42.123);
//        float repeatDistance = mix(size * 0.2, size, rand);
//
//        
//		float2 resolution = float2(width, height);
//		
//		float perlinNoise = perlin(uv, resolution, size, repeatDistance);
//		
//		float3 finalNoise = float3(perlinNoise, perlinNoise, perlinNoise);
//		
//		return float4(finalNoise, s.a);
//	}
	
//	
////     Params:
////    
////     Resoltion: Float 2 of the width and height of the image
////     Effect: Int, 0 to skip, 1 to apply
////     Zoom: How big the grain is.
//    float4 filmGrain3D(coreimage::sample_t s, float width, float height, float size, coreimage::destination dest) {
//
//        
//        float2 uv = dest.coord(); // pixel coords
//        float2 resolution = float2(width, height);
//        
//        size = clamp(0.2, 100.0, size); // ensure its never 0
//
//        
////        float2 jitter = float2(17.0, 71.0) * fract(sin(dot(uv, float2(91.3, 123.7))) * 43758.5453);
////        float2 uvJittered = uv + jitter * 0.001;
////        float2 uvClamped = clamp(uvJittered, 0.0, 1.0);
//        float3 grainF3 = float3(grain(uv, resolution, size));
//        
//        float logCMidtone = 0.391;
//        
//        float3 color = float3(logCMidtone, logCMidtone, logCMidtone);
//        float3 linear = decodeLogCFloat3(s.rgb);
//        float3 toneMapped = toneMapToDisplay(linear);
//        float luminance = dot(toneMapped, float3(0.299, 0.587, 0.114));
//        
//        
////
////        float3 grainApplied = sqrt(color) * (2.0 * grainF3 - 1.0) + 2.0 * color * (1.0 - grainF3);
////        float response = smoothstep(0.05, 0.5, luminance);
////        float3 finalColor = mix(grainF3, color, pow(response, 2.0));
//		
//		float3 finalColor = mix(grainF3, color, luminance);
//        
//        return float4(finalColor, s.a);
//    }
    
    
//    float4 filmGrain3D(coreimage::sample_t s, float width, float height, float size, coreimage::destination dest) {
//        float grainSize = size;
//        float2 uv = dest.coord();
//        
//        float2 resolution = float2(width, height);
//        
//        float g = grain(uv, resolution / grainSize);
//
//        float3 finalColor = float3(g);
//
//        return float4(finalColor, s.a);
//    }

    
    
    
    
    float4 smoothStepMetal(coreimage::sample_t s, coreimage::sample_t x, coreimage::sample_t m, float fade, float lowStep, float highStep) {
        float background = s.g;
        float foreground = x.g;
        
        lowStep /= 2.0;
        lowStep = clamp(lowStep, 0.0, 1.0);
        
//        float3 toneMappedMask = toneMapToDisplay(m.rgb);
        float3 toneMappedMask = m.rgb;
        
        float r = toneMappedMask.r;
        float g = toneMappedMask.g;
        float b = toneMappedMask.b;


        float r_weight = 1.0 - smoothstep(lowStep, highStep, r);
        float g_weight = 1.0 - smoothstep(lowStep, highStep, g);
        float b_weight = 1.0 - smoothstep(lowStep, highStep, b);

        r_weight = clamp(pow((r_weight * 0.6) + 0.4, 2.0), 0.0, 1.0);
        g_weight = clamp(pow((g_weight * 0.6) + 0.4, 2.0), 0.0, 1.0);
        b_weight = clamp(pow((b_weight * 0.6) + 0.4, 2.0), 0.0, 1.0);
        
        float rMix = mix(background, foreground, r_weight);
        float gMix = mix(background, foreground, g_weight);
        float bMix = mix(background, foreground, b_weight);

        float3 finalBlend = float3(rMix, gMix, bMix);

        finalBlend = (finalBlend.r + finalBlend.g + finalBlend.b) / 3.0;
        
        float3 result = mix(background, finalBlend, fade);

        return float4(result, 1.0);
    }
    
    
    
    // Returns a float3 of selected channel replicated across RGB, with alpha = 1.0
    // 0 - red
    // 1 - green
    // 2 - blue
    // 3 - alpha
    float4 returnChannelF3(coreimage::sample_t s, int channel) {
        float value = 0.0;

        switch (channel) {
            case 0:
                value = s.r;
                break;
            case 1:
                value = s.g;
                break;
            case 2:
                value = s.b;
                break;
            case 3:
                value = s.a;
                break;
            default:
                value = 0.0; // fallback for invalid channel index
                break;
        }

        return float4(float3(value), 1.0);
    }
    
    float4 combineChannelsF3(coreimage::sample_t r, coreimage::sample_t g, coreimage::sample_t b) {
        return float4(r.g, g.g, b.g, 1.0);
    }
    
    
    
}
