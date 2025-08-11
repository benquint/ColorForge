//
//  GrainTiling.metal
//  ColorForge
//
//  Created by Ben Quinton on 22/07/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

float randFromTile(int2 tilePos) {
    uint h = uint(tilePos.x * 374761393U + tilePos.y * 668265263U);
    h = (h ^ (h >> 13U)) * 1274126177U;
    return float(h & 0x00FFFFFFU) / float(0x01000000U);
}

extern "C" float4 tileGrainTiles(
    coreimage::sampler grain,
    float2 tileSize,
    float maxRotationRadians,
    float canvasWidth,
    float canvasHeight,
    coreimage::destination dest
) {
    float2 uv = dest.coord();
    float4 result = float4(0.0); // Start fully transparent

    int cols = int(ceil(canvasWidth / tileSize.x)) + 1;
    int rows = int(ceil(canvasHeight / tileSize.y)) + 1;

    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            int2 tileIndex = int2(col, row);
            float2 tileOrigin = float2(col, row) * tileSize;
            float2 localPos = uv - tileOrigin;

            if (localPos.x < 0.0 || localPos.y < 0.0 ||
                localPos.x > tileSize.x || localPos.y > tileSize.y) {
                continue;
            }

            // Tile rotation
            float randVal = randFromTile(tileIndex);
            float angle = (randVal * 2.0 - 1.0) * maxRotationRadians;

            float2 center = tileSize * 0.5;
            float s = sin(angle);
            float c = cos(angle);
            float2 offset = localPos - center;
            float2 rotated = float2(
                offset.x * c - offset.y * s,
                offset.x * s + offset.y * c
            ) + center;

            // Sample grain in pixel space (no fract shrink)
            float2 grainCoord = rotated / tileSize * grain.size();
            float4 sampleColor = grain.sample(grainCoord / grain.size());

            // Simple "over" composite: replace transparent areas
            if (sampleColor.a > 0.0) {
                result = sampleColor;
            }
        }
    }

    return result;
}


extern "C" float4 tileTest(coreimage::sampler canvas,
                           coreimage::sampler tile,
                           float canvasWidth,
                           float canvasHeight,
                           float tileSize,
                           float rotationRange) // radians
{
    // Pixel position in pixel coordinates (e.g., 0..4000)
    float2 pos = canvas.coord() * float2(canvasWidth, canvasHeight);

    // Which tile in the grid is this pixel in?
    float2 tileIndex = floor(pos / tileSize);
    float2 tileOrigin = tileIndex * tileSize;           // top-left corner of this tile
    float2 tileCenter = tileOrigin + float2(tileSize * 0.5, tileSize * 0.5);

    // Generate deterministic rotation for this tile
    float seed = fract(sin(dot(tileIndex, float2(12.9898,78.233))) * 43758.5453);
    float angle = mix(-rotationRange, rotationRange, seed);

    // Local position relative to tile center
    float2 rel = pos - tileCenter;

    // Rotate this local coordinate
    float s = sin(angle);
    float c = cos(angle);
    float2 rotated = float2(c * rel.x - s * rel.y,
                             s * rel.x + c * rel.y);

    // Map to tile UV space (0–1) relative to *this tile only*
    float2 tileCoord = (rotated + tileSize * 0.5) / tileSize;

    // Wrap coordinates (optional, if you want seamless edges)
    tileCoord = fract(tileCoord);

    // Sample the tile texture
    return tile.sample(tileCoord);
}
