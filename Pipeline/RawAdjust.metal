//
//  RawAdjust.metal
//  ColorForge
//
//  Created by Ben Quinton on 21/08/2025.
//

#include <metal_stdlib>
#include "Helpers.metal"
using namespace metal;

// MARK: - Constants

// Linear map

constant float inputMapLinear32[32] = {
    0.0000000000, 0.0322580645, 0.0645161290, 0.0967741935, 0.1290322581,
    0.1612903226, 0.1935483871, 0.2258064516, 0.2580645161, 0.2903225806,
    0.3225806452, 0.3548387097, 0.3870967742, 0.4193548387, 0.4516129032,
    0.4838709677, 0.5161290323, 0.5483870968, 0.5806451613, 0.6129032258,
    0.6451612903, 0.6774193548, 0.7096774194, 0.7419354839, 0.7741935484,
    0.8064516129, 0.8387096774, 0.8709677419, 0.9032258065, 0.9354838710,
    0.9677419355, 1.0000000000
};


// Contrast output maps

// 0.5 contrast in Log C
constant float lowerContrast[32] = {
    0.1949950000, 0.2108800645, 0.2270091290, 0.2431390000, 0.2592680000,
    0.2753973226, 0.2915263871, 0.3076560000, 0.3237850000, 0.3399145806,
    0.3560436452, 0.3721730000, 0.3883020000, 0.4044318387, 0.4205609032,
    0.4366899677, 0.4528190323, 0.4689490000, 0.4850780000, 0.5012072258,
    0.5173362903, 0.5334660000, 0.5495950000, 0.5657244839, 0.5818535484,
    0.5979826129, 0.6141120000, 0.6302417419, 0.6463708065, 0.6624998710,
    0.6786290000, 0.6947590000
};

constant float higherContrast[32] = {
    0.0000000000, 0.0117410871, 0.0225661323, 0.0335304935, 0.0458764774,
    0.0608608355, 0.0798204613, 0.1050678258, 0.1395660645, 0.1863599355,
    0.2468370645, 0.3150004516, 0.3829927097, 0.4496667097, 0.5188280323,
    0.5876413548, 0.6528290323, 0.7111191290, 0.7599425161, 0.8002095806,
    0.8332603226, 0.8602950323, 0.8825164194, 0.9011778710, 0.9172117097,
    0.9311697097, 0.9435523548, 0.9548739355, 0.9656456774, 0.9763906452,
    0.9876036452, 0.9998020000
};


// HSD Constants
constant float r_pos = 0.0f;      // Red center position
constant float g_pos = 0.333f;    // Green center position
constant float b_pos = 0.666f;    // Blue center position
constant float c_pos = 0.4999f;   // Cyan center position
constant float m_pos = 0.8333f;   // Magenta center position
constant float y_pos = 0.1666f;   // Yellow center position

constant float r_rad = 0.1666f;   // Red radius
constant float g_rad = 0.1666f;   // Green radius
constant float b_rad = 0.1666f;   // Blue radius
constant float c_rad = 0.1666f;   // Cyan radius
constant float m_rad = 0.1666f;   // Magenta radius
constant float y_rad = 0.1666f;   // Yellow radius


// Input maps for HDR (Arri Log C 3 assumed gamma)

// Whites
constant float inputMapWhiteSave32[32] = {
    0.0000000000, 0.0322544516, 0.0645229355, 0.0967774516, 0.1290448710,
    0.1613012581, 0.1935676129, 0.2258170968, 0.2580804839, 0.2903347097,
    0.3226036774, 0.3548566452, 0.3871248387, 0.4193747419, 0.4516304194,
    0.4838747097, 0.5161120323, 0.5483430323, 0.5805583871, 0.6126361290,
    0.6416417742, 0.6662879355, 0.6874277097, 0.7057451935, 0.7217209677,
    0.7357568065, 0.7481512903, 0.7591651935, 0.7690031935, 0.7778513548,
    0.7858592258, 0.7931670000
};
constant float inputMapWhiteKill32[32] = {
    0.0000000000, 0.0322590902, 0.0645096175, 0.0967680621, 0.1290192340,
    0.1612770224, 0.1935292354, 0.2257959464, 0.2580497286, 0.2903106779,
    0.3225588624, 0.3548204681, 0.3870703405, 0.4193350291, 0.4515958087,
    0.4838671251, 0.5161467611, 0.5484317681, 0.5807305364, 0.6132766754,
    0.6498071842, 0.6941574950, 0.7501475681, 0.8229145120, 0.9233282729,
    1.0000000000, 1.0766717271, 1.1533434542, 1.2300151813, 1.3066869084,
    1.3833586355, 1.4600303626
};

// Highlights
constant float inputMapHighlightSave32[32] = {
    0.0000000000, 0.0322615806, 0.0645381290, 0.0968007419, 0.1290751290,
    0.1613280000, 0.1935678710, 0.2258134839, 0.2580724839, 0.2903300645,
    0.3224717742, 0.3517523871, 0.3762955484, 0.3971744194, 0.4154320000,
    0.4320151613, 0.4479026774, 0.4640888387, 0.4817176129, 0.5020604516,
    0.5253004516, 0.5506445806, 0.5777377097, 0.6062007742, 0.6356863226,
    0.6658155484, 0.6962448065, 0.7267014516, 0.7571683871, 0.7876232258,
    0.8180911290, 0.8485450000
};
constant float inputMapHighlightKill32[32] = {
    0.0000000000, 0.0322516482, 0.0644945555, 0.0967474619, 0.1289899499,
    0.1612523625, 0.1935283341, 0.2257977453, 0.2580563667, 0.2903146293,
    0.3228333618, 0.3588768074, 0.4037218638, 0.4594737582, 0.5234661898,
    0.5836669850, 0.6325441485, 0.6745160516, 0.7129437394, 0.7493046426,
    0.7843612559, 0.8187620831, 0.8529358453, 0.8871014797, 0.9212590525,
    0.9554232767, 0.9895819234, 1.0000000000, 1.0104180766, 1.0208361532,
    1.0312542299, 1.0416723065
};

// Shadows
constant float inputMapShadowSave32[32] = {
    0.1300000000, 0.1571087742, 0.1840226129, 0.2105115484, 0.2363917742,
    0.2614367419, 0.2854500968, 0.3076358065, 0.3275047419, 0.3460764194,
    0.3642618710, 0.3829009677, 0.4029313226, 0.4254945161, 0.4523117742,
    0.4838717097, 0.5161162903, 0.5483496129, 0.5806043548, 0.6128506129,
    0.6451328710, 0.6774027419, 0.7096579677, 0.7419013226, 0.7741606129,
    0.8064200000, 0.8386885806, 0.8709470000, 0.9032164516, 0.9354730000,
    0.9677435161, 1.0000000000
};
constant float inputMapShadowKill32[32] = {
   -0.0997986451, -0.0672088977, -0.0346191503, -0.0020294029, 0.0019722742,
    0.0372585977, 0.0760887381, 0.1157967817, 0.1569518970, 0.2006071882,
    0.2501402369, 0.3058678773, 0.3615314936, 0.4106324286, 0.4506407065,
    0.4838688549, 0.5161435533, 0.5484233707, 0.5806858431, 0.6129529784,
    0.6451907482, 0.6774360371, 0.7096980966, 0.7419691292, 0.7742264282,
    0.8064833147, 0.8387331938, 0.8709888741, 0.9032365593, 0.9354944492,
    0.9677426594, 1.0000000000
};


// Blacks
constant float inputMapBlackSave32[32] = {
    0.1201130000, 0.1264191935, 0.1336157097, 0.1424462258, 0.1540708387,
    0.1702357742, 0.1940718710, 0.2258187097, 0.2580792258, 0.2903331935,
    0.3225930323, 0.3548419355, 0.3871072258, 0.4193644194, 0.4516379032,
    0.4838772258, 0.5161212903, 0.5483546129, 0.5806093548, 0.6128546129,
    0.6451368710, 0.6774060645, 0.7096722258, 0.7419277742, 0.7741910645,
    0.8064455806, 0.8387099032, 0.8709642581, 0.9032287419, 0.9354821290,
    0.9677485806, 1.0000000000
};
constant float inputMapBlackKill32[32] = {
   -0.0611486586, -0.0407644767, -0.0203802949, -0.0000031130, 0.0410858874,
    0.1433200784, 0.1927517725, 0.2257930212, 0.2580496277, 0.2903110440,
    0.3225682165, 0.3548339671, 0.3870875950, 0.4193450484, 0.4515902453,
    0.4838635570, 0.5161378434, 0.5484186036, 0.5806821454, 0.6129489265,
    0.6451861597, 0.6774333297, 0.7096842987, 0.7419431475, 0.7741967868,
    0.8064573458, 0.8387113389, 0.8709715477, 0.9032242983, 0.9354858018,
    0.9677382351, 1.0000000000
};





// MARK: - Helpers



// New linear interpolation function for 32 points
inline float linearInterpolate32(float input, float x0, float y0, float x1, float y1) {
    return y0 + (input - x0) * (y1 - y0) / (x1 - x0);
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


// MARK: - Functions

inline float3 cont(float3 logC, float contrast) {
    
    if (contrast < 0.0) {
        float3 lowContrast = inputOutputMapSingleDimension(logC, lowerContrast);
        logC = mix(logC, lowContrast, abs(contrast));
    } else if (contrast > 0.0) {
        float3 lowContrast = inputOutputMapSingleDimension(logC, higherContrast);
        logC = mix(logC, lowContrast, abs(contrast));
    } else {
        return logC;
    }
    return logC;
}


// Requires image in logC
inline float3 hdr(float3 logC, float hdrWhite, float hdrHighlight, float hdrShadow, float hdrBlack) {

    // Highlights
    if (hdrHighlight != 0.0) {
        if (hdrHighlight < 0.0) {
            float3 highlightKill = inputOutputMapSingleDimension(logC, inputMapHighlightKill32);
            logC = mix(logC, highlightKill, -hdrHighlight); // Use -hdrHighlight for positive blend weight
        } else {
            float3 highlightSave = inputOutputMapSingleDimension(logC, inputMapHighlightSave32);
            logC = mix(logC, highlightSave, hdrHighlight);
        }
    }

    // Shadows
    if (hdrShadow != 0.0) {
        if (hdrShadow < 0.0) {
            float3 shadowKill = inputOutputMapSingleDimension(logC, inputMapShadowKill32);
            logC = mix(logC, shadowKill, -hdrShadow);
        } else {
            float3 shadowSave = inputOutputMapSingleDimension(logC, inputMapShadowSave32);
            logC = mix(logC, shadowSave, hdrShadow);
        }
    }

    // Whites
    if (hdrWhite != 0.0) {
        if (hdrWhite < 0.0) {
            float3 whiteKill = inputOutputMapSingleDimension(logC, inputMapWhiteKill32);
            logC = mix(logC, whiteKill, -hdrWhite);
        } else {
            float3 whiteSave = inputOutputMapSingleDimension(logC, inputMapWhiteSave32);
            logC = mix(logC, whiteSave, hdrWhite);
        }
    }

    // Blacks
    if (hdrBlack != 0.0) {
        if (hdrBlack < 0.0) {
            float3 blackKill = inputOutputMapSingleDimension(logC, inputMapBlackKill32);
            logC = mix(logC, blackKill, -hdrBlack);
        } else {
            float3 blackSave = inputOutputMapSingleDimension(logC, inputMapBlackSave32);
            logC = mix(logC, blackSave, hdrBlack);
        }
    }

    return logC;
}




inline float3 sat(float3 sph, float saturation) {
    float mask = 1.0 - sph.z;
    float saturationInput = sph.z;
    sph.z *= saturation;
    sph.z = clamp(sph.z, 0.0f, 100.0f);
    
    sph.z = mix(saturationInput, sph.z, mask);
    
    return sph;
}


inline float3 hsd(float3 sph,
                 float redHue, float redSaturation, float redDensity,
                 float greenHue, float greenSaturation, float greenDensity,
                 float blueHue, float blueSaturation, float blueDensity,
                 float cyanHue, float cyanSaturation, float cyanDensity,
                 float magentaHue, float magentaSaturation, float magentaDensity,
                 float yellowHue, float yellowSaturation, float yellowDensity)
{
    float densityChannel = sph.x;
    float hueChannel = sph.y;
    float satChannel = sph.z;
    
    float originalSaturation = sph.z;
    float saturationMask = 1.0f - sph.z;
    
    // RED
    if (redHue != 0.0f || redDensity != 0.0f || redSaturation != 1.0f) {
        float rHue0 = bellCurveLooping(hueChannel, r_pos, r_rad);
        float rHue1 = bellCurveLooping(hueChannel, r_pos + 1.0f, r_rad); // wraparound for red
        float rWeight = rHue0 + rHue1;
        
        if (redSaturation != 1.0f) {
            float rSat = mix(satChannel, satChannel * redSaturation, rWeight) - satChannel;
            satChannel += rSat;
        }
        if (redDensity != 0.0f) {
            densityChannel *= (redDensity * rWeight * satChannel + 1.0f);
        }
        if (redHue != 0.0f) {
            hueChannel += redHue * rWeight;
        }
    }
    
    // GREEN
    if (greenHue != 0.0f || greenDensity != 0.0f || greenSaturation != 1.0f) {
        float gWeight = bellCurveLooping(hueChannel, g_pos, g_rad);
        
        if (greenSaturation != 1.0f) {
            float gSat = mix(satChannel, satChannel * greenSaturation, gWeight) - satChannel;
            satChannel += gSat;
        }
        if (greenDensity != 0.0f) {
            densityChannel *= (greenDensity * gWeight * satChannel + 1.0f);
        }
        if (greenHue != 0.0f) {
            hueChannel += greenHue * gWeight;
        }
    }
    
    // BLUE
    if (blueHue != 0.0f || blueDensity != 0.0f || blueSaturation != 1.0f) {
        float bWeight = bellCurveLooping(hueChannel, b_pos, b_rad);
        
        if (blueSaturation != 1.0f) {
            float bSat = mix(satChannel, satChannel * blueSaturation, bWeight) - satChannel;
            satChannel += bSat;
        }
        if (blueDensity != 0.0f) {
            densityChannel *= (blueDensity * bWeight * satChannel + 1.0f);
        }
        if (blueHue != 0.0f) {
            hueChannel += blueHue * bWeight;
        }
    }
    
    // CYAN
    if (cyanHue != 0.0f || cyanDensity != 0.0f || cyanSaturation != 1.0f) {
        float cWeight = bellCurveLooping(hueChannel, c_pos, c_rad);
        
        if (cyanSaturation != 1.0f) {
            float cSat = mix(satChannel, satChannel * cyanSaturation, cWeight) - satChannel;
            satChannel += cSat;
        }
        if (cyanDensity != 0.0f) {
            densityChannel *= (cyanDensity * cWeight * satChannel + 1.0f);
        }
        if (cyanHue != 0.0f) {
            hueChannel += cyanHue * cWeight;
        }
    }
    
    // MAGENTA
    if (magentaHue != 0.0f || magentaDensity != 0.0f || magentaSaturation != 1.0f) {
        float mWeight = bellCurveLooping(hueChannel, m_pos, m_rad);
        
        if (magentaSaturation != 1.0f) {
            float mSat = mix(satChannel, satChannel * magentaSaturation, mWeight) - satChannel;
            satChannel += mSat;
        }
        if (magentaDensity != 0.0f) {
            densityChannel *= (magentaDensity * mWeight * satChannel + 1.0f);
        }
        if (magentaHue != 0.0f) {
            hueChannel += magentaHue * mWeight;
        }
    }
    
    // YELLOW
    if (yellowHue != 0.0f || yellowDensity != 0.0f || yellowSaturation != 1.0f) {
        float yWeight = bellCurveLooping(hueChannel, y_pos, y_rad);
        
        if (yellowSaturation != 1.0f) {
            float ySat = mix(satChannel, satChannel * yellowSaturation, yWeight) - satChannel;
            satChannel += ySat;
        }
        if (yellowDensity != 0.0f) {
            densityChannel *= (yellowDensity * yWeight * satChannel + 1.0f);
        }
        if (yellowHue != 0.0f) {
            hueChannel += yellowHue * yWeight;
        }
    }
    
    // Wrap hue 0–1
    hueChannel -= step(1.0f, hueChannel);
    hueChannel += step(hueChannel, 0.0f);
    
    // Clamp to zero to avoid very strange colors
    satChannel = clamp(satChannel, 0.0f, 100.0f);
    
    // Now we blend back the original saturation with the mask to only effect
    // the lower saturation areas similar to vibrance
    satChannel = mix(originalSaturation, satChannel, saturationMask);
    
    sph = float3(densityChannel, hueChannel, satChannel);
    return sph;
}
