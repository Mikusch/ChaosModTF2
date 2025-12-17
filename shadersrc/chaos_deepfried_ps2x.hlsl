#include "common.hlsl"

// Simple pseudo-random noise
float noise(float2 uv)
{
	return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float4 main( PS_INPUT i ) : COLOR
{
	float2 uv = i.uv.xy;

	// Slight bulge distortion toward center
	float2 centered = uv - 0.5;
	float dist = length(centered);
	float bulge = 1.0 + dist * 0.3;
	uv = centered / bulge + 0.5;

	// Get configurable parameters
	float brightness = Constants0.x;
	float contrast = Constants0.y;
	float saturation = Constants0.z;
	float noiseAmount = Constants0.w;
	float aberration = Constants1.x;
	float3 tint = Constants1.yzw;

	// Sample with chromatic aberration
	float r = tex2D(TexBase, uv + float2( aberration, 0)).r;
	float g = tex2D(TexBase, uv).g;
	float b = tex2D(TexBase, uv + float2(-aberration, 0)).b;
	float3 color = float3(r, g, b);

	// Brightness boost
	color = color * brightness + 0.1;

	// Extreme contrast
	color = (color - 0.5) * contrast + 0.5;

	// Extreme saturation
	float gray = dot(color, float3(0.299, 0.587, 0.114));
	color = lerp(float3(gray, gray, gray), color, saturation);

	// Apply color tint
	color *= tint;

	// Add noise/grain
	float n = noise(uv * 500.0) * noiseAmount;
	color += n;

	// Harsh posterization (JPEG artifact simulation)
	float levels = 8.0;
	color = floor(color * levels + 0.5) / levels;

	// Sharpening
	float sharp = 0.002;
	float3 blur = tex2D(TexBase, uv + float2(sharp, 0)).rgb;
	blur += tex2D(TexBase, uv + float2(-sharp, 0)).rgb;
	blur += tex2D(TexBase, uv + float2(0, sharp)).rgb;
	blur += tex2D(TexBase, uv + float2(0, -sharp)).rgb;
	blur *= 0.25;
	color += (color - blur) * 1.5;

	// Clamp to valid range
	color = saturate(color);

	return float4(color, 1.0);
}
