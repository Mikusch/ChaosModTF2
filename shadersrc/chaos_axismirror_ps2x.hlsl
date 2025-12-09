
#include "common.hlsl"

float4 main( PS_INPUT i ) : COLOR
{
	float2 uv = i.uv;
	
	float2 flip = uv;
	flip.y *= -1.0;
	flip = frac(flip);
	
	if(uv.y > 0.5)
		return tex2D(TexBase, flip);
		
	return tex2D(TexBase, uv);
}
