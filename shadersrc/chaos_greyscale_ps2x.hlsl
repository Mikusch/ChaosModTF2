#include "common.hlsl"

float4 main( PS_INPUT i ) : COLOR
{
	float4 color = tex2D(TexBase, i.uv.xy);

	// Convert to grayscale using luminance weights
	float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));

	return float4(gray, gray, gray, color.a);
}
