#include "common.hlsl"

#define Mult Constants0.x

float4 main( PS_INPUT i ) : COLOR
{
	float2 uv = i.uv;
	float2 tile = frac(uv * Mult);
	return tex2D(TexBase, tile);
}
