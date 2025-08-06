//
//  ColorAdjustmentKernels.metal
//  ColorForge
//
//  Created by admin on 06/06/2025.
//

#include <metal_stdlib>
using namespace metal;


/*
 
 Outline for color harmony.
 
 Step 1: Covert image to YUV
 
 Step 2: Treat U and V as X / Y coordinates after normalising by adding 0.5 (so as to avoid a range of -0.5 - 0.5)
 
 Step 3: perform linear regression on the "coordinates" aka U V values to find best fitting line
 
 Step 4: Find the first and last UV values on the line
 
 Step 5: Find distance from centre for both ends of the line
 
 Step 6: Subtract each end of the line from the equal width of the line

 i.e. if one half from the centre is 0.7 long, and the other is 0.3, and the line length is 1.0
 we would subtract 0.7 from 0.5, and 0.3 from o.5
 
 
 Step 7: we then shift the U and V values along the lines direction so that the end points marry up with the new points calculated above, however we make sure that we dont apply this shift to neutrals aka those close to 0.5, and we apply the shift less to values closer to 0.5, 0.5 (neutral)
 
 To do the above, 
 
 Since we're treating U and V values as "coordinates" but they arent, we could use convolution kernels to "shift" or warp
 
 
 
 */
