#include "common.hlsl"

float4 main( PS_INPUT i ) : COLOR
{
	float2 uv = i.uv;
	float h = Constants0.x;
	float2 mirrored = 0.5 - abs(uv - 0.5);

	float2 final_uv;
	final_uv.x = lerp(uv.x, mirrored.x, h);
	final_uv.y = lerp(uv.y, mirrored.y, 1.0 - h);
	
	return tex2D(TexBase, final_uv);
}