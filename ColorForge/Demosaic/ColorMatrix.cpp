//
//  ColorMatrix.cpp
//  Demosaicer
//
//  Created by admin on 14/08/2025.
//

#include "ColorMatrix.hpp"
#include <iostream>


//using M3 = std::array<std::array<double,3>,3>;

static M3 mul3(const M3& A, const M3& B, const M3& C) {
	M3 R{};
	for (int r = 0; r < 3; ++r) {
		for (int c = 0; c < 3; ++c) {
			R[r][c] =
				A[r][0] * (B[0][0] * C[0][c] + B[0][1] * C[1][c] + B[0][2] * C[2][c]) +
				A[r][1] * (B[1][0] * C[0][c] + B[1][1] * C[1][c] + B[1][2] * C[2][c]) +
				A[r][2] * (B[2][0] * C[0][c] + B[2][1] * C[1][c] + B[2][2] * C[2][c]);
		}
	}
	return R;
}

static M3 normalizeRowsToOne(const M3& M) {
	M3 R = M;
	for (int r = 0; r < 3; ++r) {
		double sum = R[r][0] + R[r][1] + R[r][2];
		if (std::fabs(sum) > 1e-12) {
			R[r][0] /= sum;
			R[r][1] /= sum;
			R[r][2] /= sum;
		}
	}
	return R;
}


static M3 identity3() {
	return {{{1,0,0},{0,1,0},{0,0,1}}};
}



// MARK: - XY Chromaticity

static std::array<double, 3> matVecMul(const M3& matrix, const std::array<double, 3>& vec) {
    std::array<double, 3> result{};
    for (int r = 0; r < 3; ++r) {
        result[r] = matrix[r][0] * vec[0] + matrix[r][1] * vec[1] + matrix[r][2] * vec[2];
    }
    return result;
}

// Calculate XY chromaticity from white balance multipliers
static std::pair<double, double> calculateChromaticity(const M3& cam_to_xyz,
                                                       double rMul, double gMul, double bMul) {
    // Create white balance corrected neutral point in camera space
    // This represents what a perfect white reflector would look like after white balance
    std::array<double, 3> wb_neutral = {0.18/rMul, 0.18/gMul, 0.18/bMul};
    
    // Convert to XYZ
    std::array<double, 3> xyz = matVecMul(cam_to_xyz, wb_neutral);
    
    // Calculate chromaticity coordinates
    double sum = xyz[0] + xyz[1] + xyz[2];
    if (sum < 1e-12) {
        return {0.3127, 0.3290}; // Default to D65 if something goes wrong
    }
    
    double x = xyz[0] / sum;
    double y = xyz[1] / sum;
    
    return {x, y};
}









//static void printM3(const char* label, const M3& M) {
//	// std::cout << label << "\n";
//	for (int r=0;r<3;++r) {
//		for (int c=0;c<3;++c) // std::cout << std::setw(12) << std::fixed << std::setprecision(6) << M[r][c] << " ";
//		// std::cout << "\n";
//	}
//}

//struct CamToAWG3Result {
//	M3 camToAWG3;
//	std::array<double, 3> camMul;  // raw values from LibRaw
//};


static M3 mul(const M3& A, const M3& B) {
	M3 R{};
	for (int r=0;r<3;++r)
		for (int c=0;c<3;++c)
			R[r][c] = A[r][0]*B[0][c] + A[r][1]*B[1][c] + A[r][2]*B[2][c];
	return R;
}

// Diagonal from cam_mul (normalize to G=1)
static M3 wbDiagonal(double rMul, double gMul, double bMul) {
	if (gMul == 0.0) gMul = 1.0;
	return {{
		{ rMul/gMul, 0.0,        0.0 },
		{ 0.0,       1.0,        0.0 },
		{ 0.0,       0.0,  bMul/gMul }
	}};
}


static M3 inverse3x3(const M3& M) {
    M3 R{};
    double det =
        M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1]) -
        M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0]) +
        M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0]);

    if (std::fabs(det) < 1e-12) {
        // Return identity matrix instead of throwing
        return identity3();  // Returns [[1,0,0],[0,1,0],[0,0,1]]
    }

    double invDet = 1.0 / det;

    R[0][0] =  (M[1][1] * M[2][2] - M[1][2] * M[2][1]) * invDet;
    R[0][1] = -(M[0][1] * M[2][2] - M[0][2] * M[2][1]) * invDet;
    R[0][2] =  (M[0][1] * M[1][2] - M[0][2] * M[1][1]) * invDet;

    R[1][0] = -(M[1][0] * M[2][2] - M[1][2] * M[2][0]) * invDet;
    R[1][1] =  (M[0][0] * M[2][2] - M[0][2] * M[2][0]) * invDet;
    R[1][2] = -(M[0][0] * M[1][2] - M[0][2] * M[1][0]) * invDet;

    R[2][0] =  (M[1][0] * M[2][1] - M[1][1] * M[2][0]) * invDet;
    R[2][1] = -(M[0][0] * M[2][1] - M[0][1] * M[2][0]) * invDet;
    R[2][2] =  (M[0][0] * M[1][1] - M[0][1] * M[1][0]) * invDet;

    return R;
}
// Build Camera → AWG
CamToAWG3Result getCamToAWG3(const libraw_colordata_t& color, const libraw_iparams_t& idata) {
    // 1) XYZ→Camera (D50) from LibRaw
    M3 M_XYZ2Cam{};
    for (int r = 0; r < 3; ++r)
        for (int c = 0; c < 3; ++c)
            M_XYZ2Cam[r][c] = color.cam_xyz[r][c];
    
    // 2) Invert: Camera→XYZ (D50)
    M3 M_Cam2XYZ = inverse3x3(M_XYZ2Cam);
    
    // 3) Combined transformation matrix: D50→D65 + XYZ→AWG
    const M3 M_XYZD50_to_AWGD65_Bradford = {{
        {1.659196, -0.524579, -0.134618},
        {-0.625423,  1.421150,  0.204273},
        {-0.030082,  0.066094,  0.963988}
    }};

    // 4) Final transformation: Camera → AWG
    M3 M_Cam_to_AWG = mul(M_XYZD50_to_AWGD65_Bradford, M_Cam2XYZ);

    // 5) White balance multipliers
    const double rMul = color.cam_mul[0] / color.cam_mul[1];
    const double gMul = 1.0;
    const double bMul = color.cam_mul[2] / color.cam_mul[1];

    // 6) Calculate XY chromaticity
    auto [chrom_x, chrom_y] = calculateChromaticity(M_Cam2XYZ, rMul, gMul, bMul);
    
    return { M_Cam_to_AWG, { rMul, gMul, bMul }, chrom_x, chrom_y };
}
