// ColorMatrix.hpp
// Demosaicer
// Created by Ben Quinton on 14/08/2025.

#pragma once

#include <array>
#include "libraw.h"

// 3×3 matrix of doubles
using M3 = std::array<std::array<double, 3>, 3>;

// Return type for Camera→AWG3 computation
struct CamToAWG3Result {
    M3 camToAWG3;                 // Camera → Arri Wide Gamut 3 (D65) matrix
    std::array<double, 3> camMul; // WB multipliers (e.g., from LibRaw), order: R,G,B
    double chromaticity_x;
    double chromaticity_y;
};

// Build Camera → AWG3 transform and WB multipliers from LibRaw color data
CamToAWG3Result getCamToAWG3(const libraw_colordata_t& color, const libraw_iparams_t& idata);
