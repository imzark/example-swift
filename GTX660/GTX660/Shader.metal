//
//  Shader.metal
//  GTX660
//
//  Created by Harry Tang on 2019/6/4.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

kernel void yuvToRGB(texture2d<float, access::read> y_inTexture [[ texture(0) ]],
										 texture2d<float, access::read> uv_inTexture [[ texture(1) ]],
										 texture2d<float, access::write> outTexture [[ texture(2) ]],
										 uint2 gid [[ thread_position_in_grid ]]) {
	float4 yFloat4 = y_inTexture.read(gid);
	float4 uvFloat4 = uv_inTexture.read(gid/2);
	float y = yFloat4.x;
	float u = uvFloat4.x - 0.5;
	float v = uvFloat4.y - 0.5;
	
	float r = y + 1.403 * v;
	r = (r < 0.0) ? 0.0 : ((r > 1.0) ? 1.0 : r);
	float g = y - 0.343 * u - 0.714 * v;
	g = (g < 0.0) ? 0.0 : ((g > 1.0) ? 1.0 : g);
	float b = y + 1.770 * u;
	b = (b < 0.0) ? 0.0 : ((b > 1.0) ? 1.0 : b);
	outTexture.write(float4(r, g, b, 1.0), gid);
}
