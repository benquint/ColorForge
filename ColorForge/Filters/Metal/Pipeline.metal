//
//  Pipeline.metal
//  ColorForge
//
//  Created by Ben Quinton on 21/08/2025.
//

#include <metal_stdlib>
#include "RawAdjust.metal"
#include "Gamma.metal"
#include "ColorSpace.metal"
#include "Texture.metal"

using namespace metal;


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
    
    rgb = LogC3_to_Lin(rgb); // Linearise input
    
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

    outputTexture.write(float4(logc, pixel.a), gid);
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
