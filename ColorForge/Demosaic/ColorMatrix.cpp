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









static void printM3(const char* label, const M3& M) {
	std::cout << label << "\n";
	for (int r=0;r<3;++r) {
		for (int c=0;c<3;++c) std::cout << std::setw(12) << std::fixed << std::setprecision(6) << M[r][c] << " ";
		std::cout << "\n";
	}
}

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
		throw std::runtime_error("Matrix is singular, cannot invert");
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
    
    M3 M_RGB_Cam{};
    for (int r = 0; r < 3; ++r)
        for (int c = 0; c < 3; ++c)
            M_RGB_Cam[r][c] = color.rgb_cam[r][c];
    
    const M3 ROMM_to_AWG = {{
        {1.221544, -0.140816, -0.080727},
        {-0.108018,  0.923949,  0.184069},
        {-0.005847,  0.042831,  0.963016}
    }};

    M3 M_Cam_RGB = inverse3x3(M_RGB_Cam);
    
    // 2) Invert: Camera→XYZ (D50)
    M3 M_Cam2XYZ = inverse3x3(M_XYZ2Cam);
    
    // 3) CAT D50→D65 (Bradford)
    const M3 D50_to_D65 = {{
        { 0.9555766, -0.0230393,  0.0631636 },
        {-0.0282895,  1.0099416,  0.0210077 },
        { 0.0122982, -0.0204830,  1.3299098 }
    }};
    
    // 4) XYZ → AWG matrix (given inverse)
    const M3 M_XYZ_to_AWG = {{
        {  1.789066, -0.482534, -0.200076 },
        { -0.639849,  1.396400,  0.194432 },
        { -0.041532,  0.082335,  0.878868 }
    }};
    
    const M3 M_XYZD50_to_AWGD65_Bradford = {{
        {1.659196, -0.524579, -0.134618},
        {-0.625423,  1.421150,  0.204273},
        {-0.030082,  0.066094,  0.963988}
    }};

    // This seems correct
    M3 M_Cam_to_AWG365 = mul(M_XYZD50_to_AWGD65_Bradford, M_Cam2XYZ);

    // 5) Compose: Camera→AWG
    //    Order: (XYZ→AWG) * (CAT D50→D65) * (Camera→XYZ D50)
    M3 M_camWB_to_AWG = mul3(M_XYZ_to_AWG, D50_to_D65, M_Cam2XYZ);

    // 6) Fold WHITE BALANCE (or apply to raw before matrix)
    const double rMul = color.cam_mul[0] / color.cam_mul[1];
    const double gMul = 1.0;
    const double bMul = color.cam_mul[2] / color.cam_mul[1];

    printf("cam_mul: R=%.6f, G1=%.6f, B=%.6f, G2=%.6f\n",
      color.cam_mul[0],
      color.cam_mul[1],
      color.cam_mul[2],
      color.cam_mul[3]);
    
    
    // Get XY
    auto [chrom_x, chrom_y] = calculateChromaticity(M_Cam2XYZ, rMul, gMul, bMul);
    printf("Calculated chromaticity: x=%.4f, y=%.4f\n", chrom_x, chrom_y);
    

    // Check if it's Phase One
    bool isPhaseOne = (strstr(idata.make, "Phase One") != nullptr) ||
                      (strstr(idata.normalized_make, "Phase One") != nullptr);
    
    if (isPhaseOne) {
        
        // Create a 3x3 matrix from the multipliers:
        M3 MulMat = {{
            {rMul, 0.0,  0.0 },
            {0.0,  1.0,  0.0 },
            {0.0,  0.0,  bMul}
        }};
        
        // Get P1_color[0] ROMM→Cam matrix
        M3 M_ROMM_to_Cam{};
        for (int r = 0; r < 3; ++r)
            for (int c = 0; c < 3; ++c)
                M_ROMM_to_Cam[r][c] = color.P1_color[0].romm_cam[r*3 + c];
        
        // Invert to get Cam→ROMM (without white balance)
        M3 M_Cam_to_ROMM = inverse3x3(M_ROMM_to_Cam);
        
        // Compose in correct order: MulMat × ROMM→AWG × Cam→ROMM
        M3 M_ROMM_to_AWG_WB = mul(MulMat, ROMM_to_AWG);
        M3 M_Cam_to_AWG_P1 = mul(M_ROMM_to_AWG_WB, M_Cam_to_ROMM);
        
        printM3("P1 MulMat", MulMat);
        printM3("P1 ROMM → Cam", M_ROMM_to_Cam);
        printM3("P1 Cam → ROMM", M_Cam_to_ROMM);
        printM3("P1 ROMM → AWG (WB)", M_ROMM_to_AWG_WB);
        printM3("P1 Camera → AWG", M_Cam_to_AWG_P1);
        
        // Return Phase One specific matrix with unity multipliers (WB now baked in)
        return { M_Cam_to_AWG_P1, { 1.0, 1.0, 1.0 }, chrom_x, chrom_y };
    } else {
        
        printM3("Xyz → Cam", M_XYZ2Cam);
        printM3("Cam → Xyz", M_Cam2XYZ);
        printM3("Camera → AWG", M_camWB_to_AWG);
        
        return { M_Cam_to_AWG365, { rMul, gMul, bMul }, chrom_x, chrom_y };
    }
}
