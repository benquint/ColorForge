//
//  Pipeline.metal
//  ColorForge
//
//  Created by Ben Quinton on 21/08/2025.
//

#include <metal_stdlib>
#include "RawAdjust.metal"
#include "Gamma.metal"

using namespace metal;


// MARK: - Matrices

constant float3x3 AWG3_to_XYZ = float3x3(
    float3(0.638008f, 0.214704f, 0.097744f),
    float3(0.291954f, 0.823841f, -0.115795f),
    float3(0.002798f, -0.067034f, 1.153294f)
);

constant float3x3 XYZ_to_AWG3 = float3x3(
    float3(1.789066f, -0.482534f, -0.200076f),
    float3(-0.639849f, 1.396400f, 0.194432f),
    float3(-0.041532f, 0.082335f, 0.878868f)
);






// MARK: - Spherical Coords

inline float3 rgbToSpherical(float3 rgb) {
    
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


inline float3 sphericalToRgb(float3 sph) {
    
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

struct PipelineParams {
    
    // Rawadjust
    float3x3 adaptationMatrix;
    float ev;
    int isLog;
    int isTiff;
    int colorSpace; // 0 for AWG3, 1 for sRGB, 2 for AdobeRGB, 3 for sGamut3.cine, 4 for Rec2020... will extend later
    float contrast;
    
    
    float hdrWhite;
    float hdrHighlight;
    float hdrShadow;
    float hdrBlack;
    
    float saturation;
    
    float redHue; float redSaturation; float redDensity;
    float greenHue; float greenSaturation; float greenDensity;
    float blueHue; float blueSaturation; float blueDensity;
    float cyanHue; float cyanSaturation; float cyanDensity;
    float magentaHue; float magentaSaturation; float magentaDensity;
    float yellowHue; float yellowSaturation; float yellowDensity;
};


kernel void pipelineKernel(texture2d<float, access::read> inputTexture [[texture(0)]],
                           texture2d<float, access::write> outputTexture [[texture(1)]],
                           constant PipelineParams& P [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= inputTexture.get_width() || gid.y >= inputTexture.get_height()) return;
    
    
    // Get float3 for processing
    float4 pixel = inputTexture.read(gid);
    float3 rgb = pixel.rgb;

    
    // MARK: - Raw adjust
    

    
    // ------ Apply chomatic adaptation matrix (caluclated on CPU), see pseudo code. ----- //
    if (P.isLog == 1) {
        rgb = LogC3_to_Lin(rgb); // Linearise input
    }
    
    
    float3 xyz = AWG3_to_XYZ * rgb; // Convert to XYZ
    xyz = P.adaptationMatrix * xyz; // Apply whiteballance
    
    rgb = XYZ_to_AWG3 * xyz; // Convert back to RGB
    
  
    

    // ------ Apply exposure ------- //
    
    rgb = rgb * pow(2, P.ev); // Need to handle the baseline EV CPU Side
    

    // ----------------------------- //
    
    
    float3 logc = Lin_to_LogC3(rgb);

    
    
    
    
    // ------ Apply contrast ------- //
    
    logc = cont(logc, P.contrast);
    
    
    
    // ------ Apply HDR ------- //
    
    logc = hdr(logc, P.hdrWhite, P.hdrHighlight, P.hdrShadow, P.hdrBlack);
    
    
    
    // ------ Spherical ------- //
    
    float3 sph = rgbToSpherical(logc);
    
    sph = sat(sph, P.saturation);
    
    // HSD
    sph = hsd(sph,
              P.redHue, P.redSaturation, P.redDensity,
              P.greenHue, P.greenSaturation, P.greenDensity,
              P.blueHue, P.blueSaturation, P.blueDensity,
              P.cyanHue, P.cyanSaturation, P.cyanDensity,
              P.magentaHue, P.magentaSaturation, P.magentaDensity,
              P.yellowHue, P.yellowSaturation, P.yellowDensity
              );
    
    logc = sphericalToRgb(sph);
    
    

    outputTexture.write(float4(logc, 1.0), gid);
}
    
/*
 
 Psuedo code for white ballance (Use simd in Swift):
 
 // Convert chromaticity (x,y) to XYZ tristimulus (assuming Y=1 for normalization)
 float3 sourceXYZ = float3(sourceXY.x / sourceXY.y,
                          1.0f,
                          (1.0f - sourceXY.x - sourceXY.y) / sourceXY.y);

 float3 targetXYZ = float3(targetXY.x / targetXY.y,
                          1.0f,
                          (1.0f - targetXY.x - targetXY.y) / targetXY.y);

 // Bradford chromatic adaptation matrix
 const float3x3 bradford = float3x3(
      0.8951f,  0.2664f, -0.1614f,
     -0.7502f,  1.7135f,  0.0367f,
      0.0389f, -0.0685f,  1.0296f
 );

 const float3x3 bradfordInv = float3x3(
      0.9869929f, -0.1470543f,  0.1599627f,
      0.4323053f,  0.5183603f,  0.0492912f,
     -0.0085287f,  0.0400428f,  0.9684867f
 );

 // Transform to cone response domain
 float3 sourceRGB = bradford * sourceXYZ;
 float3 targetRGB = bradford * targetXYZ;

 // Calculate adaptation ratios
 float3 adaptRatios = targetRGB / sourceRGB;

 // Final adaptation matrix
 float3x3 adaptationMatrix = bradfordInv *
                            float3x3(adaptRatios.x, 0, 0,
                                    0, adaptRatios.y, 0,
                                    0, 0, adaptRatios.z) *
                            bradford;

 
 */
