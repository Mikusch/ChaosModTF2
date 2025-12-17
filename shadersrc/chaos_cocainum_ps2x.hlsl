// by ficool2

#include "common.hlsl"

#define PI 3.14159265

#define Time				Constants0.x
#define ColorIntensity		Constants0.y
#define ColorDistortion		Constants0.z
#define ColorSpeed			Constants0.w
#define WaveFrequency		Constants1.x
#define WaveAmplitude		Constants1.y
#define RadialStrength		Constants1.z
#define OscillationPeriod	Constants1.w
#define Contrast			Constants2.x
#define HueShift			Constants2.y

float3 rgb2hsv(float3 c)
{
	float4 K = float4(0.0, -1.0 / 6.0, 2.0 / 6.0, -1.0);
	float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
	float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float4 adjust_contrast(float4 color, float contrast)
{
	color.rgb = ((color.rgb - 0.5) * contrast + 0.5);
	return color;
}

float4 hue_shift(float4 color, float hueShift)
{
	float3 hsv = rgb2hsv(color.rgb);
	hsv.x += hueShift;
	if (hsv.x > 1.0) 
		hsv.x -= 1.0;
	if (hsv.x < 0.0) 
		hsv.x += 1.0;

	color.rgb = hsv2rgb(hsv);
	return color;
}

float4 main( PS_INPUT i ) : COLOR
{
	float2 uv = i.baseTexCoord;
	
	float oscillation = 0.4 + 0.6 * (0.5 + 0.5 * sin(Time * (2.0 * PI / OscillationPeriod)));

	// radial gradient
	float edge_intensity = length(uv - float2(0.5, 0.5)) * RadialStrength; 
	edge_intensity = (saturate(edge_intensity) + 1.0) * oscillation;
	
	// wave
	float2 offset;
	offset.x = sin(i.baseTexCoord.y * WaveFrequency + Time) * WaveAmplitude * edge_intensity;
	offset.y = cos(i.baseTexCoord.x * WaveFrequency + Time * 1.5) * WaveAmplitude * edge_intensity;
	
	uv += offset;

	// glitch
	float glitch = sin(uv.y * 10.0 + Time * ColorSpeed) * ColorDistortion * 0.005 * edge_intensity;
	float shift = sin(Time * ColorSpeed) * ColorIntensity * edge_intensity;
	
	uv.x += glitch;
	
	float4 result = tex2D(TexBase, uv);
	result.r = tex2D(TexBase, uv + float2(shift, 0)).r;
	result.g = tex2D(TexBase, uv + float2(-shift, shift)).g;
	result.b = tex2D(TexBase, uv + float2(0, -shift)).b;
	
	// color shifts
	result = adjust_contrast(result, Contrast);
	result = hue_shift(result, HueShift * sin(Time * 0.5)); 

	return result;
}
