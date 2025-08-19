//
//  Demosaic.cpp
//  Demosaicer
//
//  Created by Ben Quinton on 13/08/2025.
//

#include <iostream>
#include <fstream>
#include <string>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <algorithm>
#include <array>
#include <climits>
#include "libraw.h"
#include <filesystem>
#include "ColorMatrix.hpp"
#include <CoreFoundation/CoreFoundation.h>
#include "DemosaicerBridge.h"




static std::string PathFromCFURL(CFURLRef url) {
	CFStringRef cfPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
	char buf[PATH_MAX];
	Boolean ok = CFStringGetCString(cfPath, buf, sizeof(buf), kCFStringEncodingUTF8);
	CFRelease(cfPath);
	return ok ? std::string(buf) : std::string();
}



// MARK: -  Get Black


struct BlackRGB { float r, g, b; };

// Compute per-channel black levels at the visible-window phase.
// - raw : LibRaw handle (non-const because COLOR() isn't const)
// - LM/TM : left/top margins (visible-window origin in the full raster)
// - Returns R/G/B black levels = global + per-channel + pattern-map cell for that site.
static BlackRGB compute_black_levels(LibRaw& raw, uint32_t LM, uint32_t TM)
{
    const auto& cd = raw.imgdata.color;
    const auto& rd = raw.imgdata.rawdata;

    const int global = int(cd.black);

    // Per-channel corrections: order is R, G1, B, G2 in LibRaw
    const int offR  = int(cd.cblack[0]);
    const int offG1 = int(cd.cblack[1]);
    const int offB  = int(cd.cblack[2]);
    const int offG2 = int(cd.cblack[3]);

    const unsigned pw = cd.cblack[4];
    const unsigned ph = cd.cblack[5];


    // Calculate average black levels from statistics if available
    if (cd.black_stat[4] > 0 && cd.black_stat[5] > 0 && cd.black_stat[6] > 0 && cd.black_stat[7] > 0) {
        float avgR = float(cd.black_stat[0]) / float(cd.black_stat[4]);
        float avgG1 = float(cd.black_stat[1]) / float(cd.black_stat[5]);
        float avgB = float(cd.black_stat[2]) / float(cd.black_stat[6]);
        float avgG2 = float(cd.black_stat[3]) / float(cd.black_stat[7]);
        float avgG = (avgG1 + avgG2) * 0.5f;
        
    }
    
    // Helper to read the pattern-map value at visible phase (LM,TM)
    auto map_at = [&](unsigned x, unsigned y) -> int {
        if (pw == 0u || ph == 0u) return 0;              // no map
        const unsigned ix = (LM + x) % pw;
        const unsigned iy = (TM + y) % ph;
        const unsigned* map = &cd.cblack[6];
        return int(map[iy * pw + ix]);
    };

    // Find which cell (within one 2×2) is R, which is B, and the two Greens
    // We look at the 2×2 block starting at the visible origin phase.
    int rMap = 0, bMap = 0, g1Map = 0, g2Map = 0;
    bool g1Set = false;

    for (unsigned dy = 0; dy < 2; ++dy) {
        for (unsigned dx = 0; dx < 2; ++dx) {
            int code = raw.COLOR(int(LM + dx), int(TM + dy)); // 0=R, 1/3=G, 2=B
            int mv   = map_at(dx, dy);
            if (code == 0)       rMap = mv;
            else if (code == 2)  bMap = mv;
            else { // green (1 or 3)
                if (!g1Set) { g1Map = mv; g1Set = true; }
                else         { g2Map = mv; }
            }
        }
    }

    // Combine: global + per-channel + pattern-map
    const float rBlack = float(global + offR  + rMap);
    const float gBlack = float(global + ((offG1 + g1Map) + (offG2 + g2Map)) * 0.5f);
    const float bBlack = float(global + offB  + bMap);


    return { rBlack, gBlack, bBlack };
}












// MARK: - Get CFA Pattern


static uint32_t deduce_cfa_pattern_at(LibRaw& raw, int x0, int y0)
{
	auto C = [&](int x,int y){ return raw.COLOR(x, y); };
	
	int c00 = C(x0,     y0);
	int c10 = C(x0 + 1, y0);
	int c01 = C(x0,     y0 + 1);
	int c11 = C(x0 + 1, y0 + 1);
	
	auto label = [](int v) -> const char* {
		if (v == 0) return "R";
		if (v == 2) return "B";
		if (v == 1 || v == 3) return "G";
		return "?";
	};
	
	auto isR = [&](int v){ return v == 0; };
	auto isG = [&](int v){ return v == 1 || v == 3; };
	auto isB = [&](int v){ return v == 2; };
	
	uint32_t pat = 0;
	const char* patName = "RGGB";
	
	if (isR(c00) && isG(c10) && isG(c01) && isB(c11)) { pat = 0; patName = "RGGB"; }
	else if (isB(c00) && isG(c10) && isG(c01) && isR(c11)) { pat = 1; patName = "BGGR"; }
	else if (isG(c00) && isR(c10) && isB(c01) && isG(c11)) { pat = 2; patName = "GRBG"; }
	else if (isG(c00) && isB(c10) && isR(c01) && isG(c11)) { pat = 3; patName = "GBRG"; }
	
//	std::cerr << "CFA pattern at origin (" << x0 << "," << y0 << "): " << patName
//	<< "  [" << pat << "]\n";
//	std::cerr << label(c00) << " " << label(c10) << "\n"
//	<< label(c01) << " " << label(c11) << "\n";
	
	return pat;
}

// MARK: - Hacks

// Hacks struct for camera model overrides
struct CameraHacks {
    struct ModelOverride {
        std::string originalModel;
        std::string overrideModel;
    };
    
    static const std::vector<ModelOverride> modelOverrides;
    
    static std::string getOverrideModel(const std::string& originalModel) {
        for (const auto& override : modelOverrides) {
            if (override.originalModel == originalModel) {
                return override.overrideModel;
            }
        }
        return ""; // No override found
    }
};

// Define the model overrides
const std::vector<CameraHacks::ModelOverride> CameraHacks::modelOverrides = {
    {"GFX100S II", "GFX100S"}
    // Add more overrides here as needed
    // {"OriginalModel", "OverrideModel"}
};


// MARK: - New Method

// Structure to hold all the data Swift needs
struct RawImageData {
	uint16_t* rawPixels;        // Raw pixel data
	uint32_t width;             // Image width
	uint32_t height;            // Image height
	uint32_t pitch;             // Row pitch in bytes
	uint32_t cfaPattern;        // CFA pattern (0=RGGB, 1=BGGR, etc.
    int orientation;
	float blackLevelRed;        // Black level for red
	float blackLevelGreen;      // Black level for green
	float blackLevelBlue;       // Black level for blue
	float whiteLevel;           // White level
	float camToAWG3[9];         // 3x3 color matrix (row-major)
	float rMul;                 // Red multiplier
	float bMul;                 // Blue multiplier
    double chromaticity_x;
    double chromaticity_y;
};

// C++ function to extract data (no Metal operations)
static RawImageData* ExtractRawImageDataCPP(const std::filesystem::path& path) {
	auto raw = std::make_unique<LibRaw>();
	
	if (int r = raw->open_file(path.string().c_str()); r != LIBRAW_SUCCESS) {
		std::cerr << "LibRaw open_file failed: " << libraw_strerror(r) << std::endl;
		return nullptr;
	}
	
	if (int r = raw->unpack(); r != LIBRAW_SUCCESS) {
		std::cerr << "LibRaw unpack failed: " << libraw_strerror(r) << std::endl;
		raw->recycle();
		return nullptr;
	}
    
	
	// Extract all the data Swift needs
	RawImageData* data = new RawImageData();
	
	// Image dimensions
	data->width = raw->imgdata.sizes.width;
	data->height = raw->imgdata.sizes.height;
	const uint32_t LM = raw->imgdata.sizes.left_margin;
	const uint32_t TM = raw->imgdata.sizes.top_margin;
	const uint32_t fullW = raw->imgdata.sizes.raw_width;
	
    const int orientation = raw->imgdata.sizes.flip;
    data->orientation = orientation;
    
	// Calculate pitch
	data->pitch = (raw->imgdata.sizes.raw_pitch &&
				   raw->imgdata.sizes.raw_pitch >= fullW * sizeof(uint16_t))
	? raw->imgdata.sizes.raw_pitch
	: fullW * sizeof(uint16_t);
	
	// Copy raw pixel data
	const uint16_t* base = reinterpret_cast<const uint16_t*>(raw->imgdata.rawdata.raw_image);
	const uint16_t* src = base + TM * fullW + LM;
	
	size_t dataSize = data->height * data->pitch;
	data->rawPixels = new uint16_t[dataSize / sizeof(uint16_t)];
	
	// Copy row by row to handle potential pitch differences
	for (uint32_t y = 0; y < data->height; y++) {
		const uint16_t* srcRow = src + y * fullW;
		uint16_t* dstRow = data->rawPixels + y * (data->pitch / sizeof(uint16_t));
		memcpy(dstRow, srcRow, data->width * sizeof(uint16_t));
	}
	
	// Extract color processing parameters
	const auto& c = raw->imgdata.color;
	
	// Black levels
	BlackRGB bl = compute_black_levels(*raw, LM, TM);
	data->blackLevelRed = bl.r;
	data->blackLevelGreen = bl.g;
	data->blackLevelBlue = bl.b;
    
    

    
    
	
	// White level
	float linearMax = float(std::min({c.linear_max[0], c.linear_max[1], c.linear_max[2]}));
	if (linearMax == 0.0f) linearMax = 65535.0f;
	data->whiteLevel = std::min(float(c.maximum), linearMax);
	
	// CFA pattern
	data->cfaPattern = deduce_cfa_pattern_at(*raw, LM, TM);
	
    // Color matrix and multipliers
    auto [camToAWG3, camMul, chrom_x, chrom_y] = getCamToAWG3(raw->imgdata.color, raw->imgdata.idata);
    for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
            data->camToAWG3[r * 3 + c] = float(camToAWG3[r][c]);
        }
    }
    data->rMul = camMul[0];
    data->bMul = camMul[2];
    data->chromaticity_x = chrom_x;
    data->chromaticity_y = chrom_y;
	
	raw->recycle();
	

	return data;
}

extern "C" {
	// Bridge function for Swift
	CFDictionaryRef ExtractRawImageData(CFURLRef url) {
		std::string p = PathFromCFURL(url);
		if (p.empty()) return nullptr;
		
		RawImageData* data = ExtractRawImageDataCPP(std::filesystem::path(p));
		if (!data) return nullptr;
		
		// Convert to CFDictionary for Swift
		CFMutableDictionaryRef dict = CFDictionaryCreateMutable(
																kCFAllocatorDefault, 0,
																&kCFTypeDictionaryKeyCallBacks,
																&kCFTypeDictionaryValueCallBacks
																);
		
		// Add all data to dictionary
		CFNumberRef width = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &data->width);
		CFDictionarySetValue(dict, CFSTR("width"), width);
		CFRelease(width);
		
		CFNumberRef height = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &data->height);
		CFDictionarySetValue(dict, CFSTR("height"), height);
		CFRelease(height);
		
		CFNumberRef pitch = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &data->pitch);
		CFDictionarySetValue(dict, CFSTR("pitch"), pitch);
		CFRelease(pitch);
		
		CFNumberRef cfaPattern = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &data->cfaPattern);
		CFDictionarySetValue(dict, CFSTR("cfaPattern"), cfaPattern);
		CFRelease(cfaPattern);
        
        
        CFNumberRef orient = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &data->orientation);
        CFDictionarySetValue(dict, CFSTR("orientation"), orient);
        CFRelease(orient);
        
		
		// Add raw pixel data as CFData
		size_t dataSize = data->height * data->pitch;
		CFDataRef pixelData = CFDataCreate(kCFAllocatorDefault, (const UInt8*)data->rawPixels, dataSize);
		CFDictionarySetValue(dict, CFSTR("rawPixels"), pixelData);
		CFRelease(pixelData);
		
		// Add processing parameters
		CFNumberRef blackR = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &data->blackLevelRed);
		CFDictionarySetValue(dict, CFSTR("blackLevelRed"), blackR);
		CFRelease(blackR);
		
		CFNumberRef blackG = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &data->blackLevelGreen);
		CFDictionarySetValue(dict, CFSTR("blackLevelGreen"), blackG);
		CFRelease(blackG);
		
		CFNumberRef blackB = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &data->blackLevelBlue);
		CFDictionarySetValue(dict, CFSTR("blackLevelBlue"), blackB);
		CFRelease(blackB);
		
		CFNumberRef white = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &data->whiteLevel);
		CFDictionarySetValue(dict, CFSTR("whiteLevel"), white);
		CFRelease(white);
		
		CFNumberRef rMul = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &data->rMul);
		CFDictionarySetValue(dict, CFSTR("rMul"), rMul);
		CFRelease(rMul);
		
		CFNumberRef bMul = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &data->bMul);
		CFDictionarySetValue(dict, CFSTR("bMul"), bMul);
		CFRelease(bMul);
        
        // Add chromaticity coordinates
        CFNumberRef chromX = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &data->chromaticity_x);
        CFDictionarySetValue(dict, CFSTR("chromaticity_x"), chromX);
        CFRelease(chromX);

        CFNumberRef chromY = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &data->chromaticity_y);
        CFDictionarySetValue(dict, CFSTR("chromaticity_y"), chromY);
        CFRelease(chromY);
		
		// Add color matrix as CFArray
		CFMutableArrayRef matrix = CFArrayCreateMutable(kCFAllocatorDefault, 9, &kCFTypeArrayCallBacks);
		for (int i = 0; i < 9; i++) {
			CFNumberRef val = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &data->camToAWG3[i]);
			CFArrayAppendValue(matrix, val);
			CFRelease(val);
		}
		CFDictionarySetValue(dict, CFSTR("camToAWG3"), matrix);
		CFRelease(matrix);
		
		// Clean up C++ data
		delete[] data->rawPixels;
		delete data;
		
		return dict; // Transferred to Swift
	}
}
