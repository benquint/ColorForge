import Foundation
import simd

struct WhiteBalanceModel {
    
    static let shared = WhiteBalanceModel()
    
    // MARK: - Temperature Table Data Structure
    
    private struct RUVT {
        let r: Float  // Reciprocal temperature (1/T)
        let u: Float  // u chromaticity coordinate (CIE 1960 uv space)
        let v: Float  // v chromaticity coordinate (CIE 1960 uv space)
        let t: Float  // Slope of the blackbody curve at this temperature
    }
    
    // MARK: - Constants
    
    private static let kTintScale: Float = -3000.0
    
    private static let tempTable: [RUVT] = [
        RUVT(r: 0, u: 0.18006, v: 0.26352, t: -0.24341),
        RUVT(r: 10, u: 0.18066, v: 0.26589, t: -0.25479),
        RUVT(r: 20, u: 0.18133, v: 0.26846, t: -0.26876),
        RUVT(r: 30, u: 0.18208, v: 0.27119, t: -0.28539),
        RUVT(r: 40, u: 0.18293, v: 0.27407, t: -0.30470),
        RUVT(r: 50, u: 0.18388, v: 0.27709, t: -0.32675),
        RUVT(r: 60, u: 0.18494, v: 0.28021, t: -0.35156),
        RUVT(r: 70, u: 0.18611, v: 0.28342, t: -0.37915),
        RUVT(r: 80, u: 0.18740, v: 0.28668, t: -0.40955),
        RUVT(r: 90, u: 0.18880, v: 0.28997, t: -0.44278),
        RUVT(r: 100, u: 0.19032, v: 0.29326, t: -0.47888),
        RUVT(r: 125, u: 0.19462, v: 0.30141, t: -0.58204),
        RUVT(r: 150, u: 0.19962, v: 0.30921, t: -0.70471),
        RUVT(r: 175, u: 0.20525, v: 0.31647, t: -0.84901),
        RUVT(r: 200, u: 0.21142, v: 0.32312, t: -1.0182),
        RUVT(r: 225, u: 0.21807, v: 0.32909, t: -1.2168),
        RUVT(r: 250, u: 0.22511, v: 0.33439, t: -1.4512),
        RUVT(r: 275, u: 0.23247, v: 0.33904, t: -1.7298),
        RUVT(r: 300, u: 0.24010, v: 0.34308, t: -2.0637),
        RUVT(r: 325, u: 0.24702, v: 0.34655, t: -2.4681),
        RUVT(r: 350, u: 0.25591, v: 0.34951, t: -2.9641),
        RUVT(r: 375, u: 0.26400, v: 0.35200, t: -3.5814),
        RUVT(r: 400, u: 0.27218, v: 0.35407, t: -4.3633),
        RUVT(r: 425, u: 0.28039, v: 0.35577, t: -5.3762),
        RUVT(r: 450, u: 0.28863, v: 0.35714, t: -6.7262),
        RUVT(r: 475, u: 0.29685, v: 0.35823, t: -8.5955),
        RUVT(r: 500, u: 0.30505, v: 0.35907, t: -11.324),
        RUVT(r: 525, u: 0.31320, v: 0.35968, t: -15.628),
        RUVT(r: 550, u: 0.32129, v: 0.36011, t: -23.325),
        RUVT(r: 575, u: 0.32931, v: 0.36038, t: -40.770),
        RUVT(r: 600, u: 0.33724, v: 0.36051, t: -116.45)
    ]
    
    // MARK: - Public Interface
    
    /// Convert XY chromaticity coordinates to temperature and tint
    /// - Parameter xy: XY chromaticity coordinates as simd_float2
    /// - Returns: Temperature (K) and tint as simd_float2
    static func xyToTempAndTint(_ xy: simd_float2) -> simd_float2 {
        var temp: Float = 0.0
        var tint: Float = 0.0
        
        // Convert XY to UV coordinates using SIMD
        let denominator = 1.5 - xy.x + 6.0 * xy.y
        let uv = simd_float2(
            2.0 * xy.x / denominator,
            3.0 * xy.y / denominator
        )
        
        var lastDt: Float = 0.0
        var lastDelta = simd_float2(0, 0)  // du, dv
        
        // Main interpolation loop
        for index in 1...30 {
            let currentEntry = tempTable[index]
            
            // Convert slope to delta-u and delta-v, with length 1
            var delta = simd_float2(1.0, currentEntry.t)
            let len = simd_length(delta)
            delta /= len
            
            // Find delta from black body point to test coordinate
            let uvDelta = uv - simd_float2(currentEntry.u, currentEntry.v)
            
            // Find distance above or below line using cross product
            let dt = -uvDelta.x * delta.y + uvDelta.y * delta.x
            
            // If below line, we have found line pair
            if dt <= 0.0 || index == 30 {
                let clampedDt = min(dt, 0.0)
                let absDt = -clampedDt
                
                // Calculate fractional weight
                let f: Float = index == 1 ? 0.0 : absDt / (lastDt + absDt)
                
                // Interpolate temperature using SIMD
                let prevEntry = tempTable[index - 1]
                let rInterp = prevEntry.r * f + currentEntry.r * (1.0 - f)
                temp = 1.0E6 / rInterp
                
                // Interpolate UV coordinates
                let uvInterp = simd_float2(
                    prevEntry.u * f + currentEntry.u * (1.0 - f),
                    prevEntry.v * f + currentEntry.v * (1.0 - f)
                )
                
                // Calculate offset from interpolated black body point
                let uvOffset = uv - uvInterp
                
                // Interpolate direction vectors
                let deltaInterp = delta * (1.0 - f) + lastDelta * f
                let normalizedDelta = simd_normalize(deltaInterp)
                
                // Calculate tint as distance along slope
                tint = simd_dot(uvOffset, normalizedDelta) * Self.kTintScale
                
                break
            }
            
            // Store values for next iteration
            lastDt = -dt  // Store the positive distance value
            lastDelta = delta
        }
        
        return simd_float2(temp, tint)
    }
    
    /// Convert temperature and tint to XY chromaticity coordinates
    /// - Parameter temp: Temperature in Kelvin
    /// - Parameter tint: Tint value
    /// - Returns: XY chromaticity coordinates as simd_float2
    static func tempAndTintToXY(temp: Float, tint: Float) -> simd_float2 {
        // Find inverse temperature to use as index
        let r = 1.0E6 / temp
        
        // Convert tint to offset in UV space
        let offset = tint / Self.kTintScale
        
        // Search for line pair containing coordinate
        for index in 0...29 {
            let nextIndex = min(index + 1, tempTable.count - 1)
            let currentEntry = tempTable[index]
            let nextEntry = tempTable[nextIndex]
            
            if r < nextEntry.r || index == 29 {
                // Calculate interpolation weight using SIMD
                let f = (nextEntry.r - r) / (nextEntry.r - currentEntry.r)
                
                // Interpolate black body coordinates
                let uv = simd_float2(
                    currentEntry.u * f + nextEntry.u * (1.0 - f),
                    currentEntry.v * f + nextEntry.v * (1.0 - f)
                )
                
                // Calculate slope vectors for each line
                let slope1 = simd_normalize(simd_float2(1.0, currentEntry.t))
                let slope2 = simd_normalize(simd_float2(1.0, nextEntry.t))
                
                // Interpolate slope vector
                let interpolatedSlope = simd_normalize(slope1 * f + slope2 * (1.0 - f))
                
                // Apply tint offset
                let adjustedUV = uv + interpolatedSlope * offset
                
                // Convert UV back to XY coordinates
                let denominator = adjustedUV.x - 4.0 * adjustedUV.y + 2.0
                let xy = simd_float2(
                    1.5 * adjustedUV.x / denominator,
                    adjustedUV.y / denominator
                )
                
                return xy
            }
        }
        
        return simd_float2(0, 0) // Fallback
    }
    
    /// Convenience method matching the original Metal function signature
    /// - Parameters:
    ///   - x: X chromaticity coordinate
    ///   - y: Y chromaticity coordinate
    /// - Returns: Temperature and tint as simd_float2
    static func calculateTempFromXY(x: Float, y: Float) -> simd_float2 {
        return xyToTempAndTint(simd_float2(x, y))
    }
    
    /// Calculate Bradford chromatic adaptation matrix from source to target white point
    /// - Parameters:
    ///   - sourceTemp: Source temperature in Kelvin
    ///   - sourceTint: Source tint value
    ///   - targetTemp: Target temperature in Kelvin
    ///   - targetTint: Target tint value
    /// - Returns: 3x3 Bradford adaptation matrix as simd_float3x3
    static func bradfordAdaptationMatrix(
        sourceTemp: Float, sourceTint: Float,
        targetTemp: Float, targetTint: Float
    ) -> simd_float3x3 {
        
        // Convert temperatures and tints to XY chromaticity coordinates
        let sourceXY = tempAndTintToXY(temp: sourceTemp, tint: sourceTint)
        let targetXY = tempAndTintToXY(temp: targetTemp, tint: targetTint)
        
        // Convert chromaticity (x,y) to XYZ tristimulus (assuming Y=1 for normalization)
        let sourceXYZ = simd_float3(
            sourceXY.x / sourceXY.y * 0.18,                        // X scaled to 18% gray
            0.18,                                                  // Y (18% gray)
            (1.0 - sourceXY.x - sourceXY.y) / sourceXY.y * 0.18   // Z scaled to 18% gray
        )

        let targetXYZ = simd_float3(
            targetXY.x / targetXY.y * 0.18,                        // X scaled to 18% gray
            0.18,                                                  // Y (18% gray)
            (1.0 - targetXY.x - targetXY.y) / targetXY.y * 0.18   // Z scaled to 18% gray
        )
        
//        let sourceXYZ = simd_float3(
//            sourceXY.x / sourceXY.y,                           // X
//            1.0,                                               // Y (normalized)
//            (1.0 - sourceXY.x - sourceXY.y) / sourceXY.y      // Z
//        )
//        
//        let targetXYZ = simd_float3(
//            targetXY.x / targetXY.y,                           // X
//            1.0,                                               // Y (normalized)
//            (1.0 - targetXY.x - targetXY.y) / targetXY.y      // Z
//        )
        
        // Bradford chromatic adaptation matrix
        let bradford = simd_float3x3(
            simd_float3( 0.8951,  0.2664, -0.1614),
            simd_float3(-0.7502,  1.7135,  0.0367),
            simd_float3( 0.0389, -0.0685,  1.0296)
        )
        
        // Bradford inverse matrix
        let bradfordInv = simd_float3x3(
            simd_float3( 0.9869929, -0.1470543,  0.1599627),
            simd_float3( 0.4323053,  0.5183603,  0.0492912),
            simd_float3(-0.0085287,  0.0400428,  0.9684867)
        )
        
        // Transform to cone response domain
        let sourceRGB = bradford * sourceXYZ
        let targetRGB = bradford * targetXYZ
        
        // Calculate adaptation ratios
        let adaptRatios = targetRGB / sourceRGB
        
        // Create diagonal adaptation matrix
        let diagonalAdapt = simd_float3x3(
            simd_float3(adaptRatios.x, 0, 0),
            simd_float3(0, adaptRatios.y, 0),
            simd_float3(0, 0, adaptRatios.z)
        )
        
        // Final adaptation matrix: Bradford^-1 * D * Bradford
        let adaptationMatrix = bradfordInv * diagonalAdapt * bradford
        
        return adaptationMatrix
    }
}

// MARK: - Extensions for convenience

extension WhiteBalanceModel {
    /// Batch process multiple XY coordinates efficiently
    static func batchXYToTempAndTint(_ xyCoordinates: [simd_float2]) -> [simd_float2] {
        return xyCoordinates.map { xyToTempAndTint($0) }
    }
    
    /// Batch process multiple temp/tint pairs efficiently
    static func batchTempAndTintToXY(_ tempTintPairs: [(temp: Float, tint: Float)]) -> [simd_float2] {
        return tempTintPairs.map { tempAndTintToXY(temp: $0.temp, tint: $0.tint) }
    }
    
    /// Calculate Bradford adaptation matrix using initial and target temp/tint values
    /// - Parameters:
    ///   - initTemp: Initial/source temperature in Kelvin
    ///   - initTint: Initial/source tint value
    ///   - temp: Target temperature in Kelvin
    ///   - tint: Target tint value
    /// - Returns: 3x3 Bradford adaptation matrix as simd_float3x3
    static func adaptationMatrix(initTemp: Float, initTint: Float, temp: Float, tint: Float) -> simd_float3x3 {
        let matrix = bradfordAdaptationMatrix(
            sourceTemp: initTemp, sourceTint: initTint,
            targetTemp: temp, targetTint: tint
        )
        return matrix.inverse  // Apply the inverse transformation
    }
}

