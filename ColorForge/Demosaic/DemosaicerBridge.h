//
//  DemosaicerBridge.h
//  ColorForge
//
//  Created by admin on 15/08/2025.
//

// DemosaicerBridge.h
#pragma once
#include <CoreFoundation/CoreFoundation.h>
#include <CoreVideo/CoreVideo.h>

#ifdef __cplusplus
extern "C" {
#endif

// NEW: Extract raw image data and parameters for Swift Metal processing
// Returns CFDictionary with all raw data and processing parameters
CFDictionaryRef _Nullable ExtractRawImageData(CFURLRef _Nonnull url) CF_RETURNS_RETAINED;

#ifdef __cplusplus
}
#endif
