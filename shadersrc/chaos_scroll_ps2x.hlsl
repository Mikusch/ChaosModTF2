#include "common.hlsl"

#define Time  Constants0.x
#define Vert  Constants0.y
#define Speed Constants0.z

float4 main( PS_INPUT i ) : COLOR
{
	float2 uv = i.uv;
	float scrollOffset = frac(Time * Speed);
	
	if (Vert == 1.0)
		uv.y = frac(uv.y + scrollOffset);
	else
		uv.x = frac(uv.x + scrollOffset);
	
	return tex2D(TexBase, uv);
}
