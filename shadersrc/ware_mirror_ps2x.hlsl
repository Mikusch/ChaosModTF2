#include "common.hlsl"

float4 main( PS_INPUT i ) : COLOR
{
	float2 uv = i.baseTexCoord;
	uv.x = 1.0 - uv.x;
	return tex2D(TexBase, uv);
}
