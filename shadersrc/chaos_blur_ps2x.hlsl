// by ficool2

// tried various approaches here
// * box filter looks horrible
// * gaussian needs more taps, ideally would use a horizontal/vertical pass but can't modify pipeline
// * poisson looked best for limited taps
// * added depth awareness to remove "halos" from the viewmodel

#include "common.hlsl"

#define blurStrength Constants0.x
#define depthThreshold Constants0.y

float4 getAverageColor(float2 uv, float2 pixelSize)
{
	float4 color = float4(0, 0, 0, 0);

	for (int x = -1; x < 2; x++)
	{
		for (int y = -1; y < 2; y++)
		{
			float2 offset = float2(x, y) * pixelSize;
			color += tex2D(TexBase, uv + offset);
		}
	}

	color /= 9.0;

	return color;
}

float4 getGaussianBlur(float2 uv, float2 pixelSize)
{
	float4 c = float4(0,0,0,0);

	c += tex2D(TexBase, uv + pixelSize * float2(-1, -1)) * 1;
	c += tex2D(TexBase, uv + pixelSize * float2( 0, -1)) * 2;
	c += tex2D(TexBase, uv + pixelSize * float2( 1, -1)) * 1;

	c += tex2D(TexBase, uv + pixelSize * float2(-1,  0)) * 2;
	c += tex2D(TexBase, uv)                              * 4;
	c += tex2D(TexBase, uv + pixelSize * float2( 1,  0)) * 2;

	c += tex2D(TexBase, uv + pixelSize * float2(-1,  1)) * 1;
	c += tex2D(TexBase, uv + pixelSize * float2( 0,  1)) * 2;
	c += tex2D(TexBase, uv + pixelSize * float2( 1,  1)) * 1;

	return c * (1.0 / 16.0);
}

static const float2 poisson[12] =
{
	float2(-0.326,-0.406),
	float2(-0.840,-0.074),
	float2(-0.696, 0.457),
	float2(-0.203, 0.621),
	float2( 0.962,-0.195),
	float2( 0.473,-0.480),
	float2( 0.519, 0.767),
	float2( 0.185,-0.893),
	float2( 0.507, 0.064),
	float2( 0.896, 0.412),
	float2(-0.322,-0.933),
	float2(-0.792,-0.597)
};

float4 poissonBlur(float2 uv, float2 pixelSize)
{
	float4 c = tex2D(TexBase, uv) * 0.25;

	for (int i = 0; i < 12; i++)
		c += tex2D(TexBase, uv + poisson[i] * pixelSize);

	return c / 12.25;
}

float4 poissonBlurDepthAware(float2 uv, float2 pixelSize)
{
	float4 center = tex2D(TexBase, uv);
	float centerDepth = center.a;

	float4 c = center;
	float w = 1.0;

	for (int i = 0; i < 12; i++)
	{
		float2 offsetUV = uv + poisson[i] * pixelSize;
		float4 s = tex2D(TexBase, offsetUV);

		float depthDiff = abs(s.a - centerDepth);

		float depthWeight = saturate(1.0 - depthDiff / depthThreshold);

		c += s * depthWeight;
		w += depthWeight;
	}

	return c / w;
}

float4 main( PS_INPUT i ) : COLOR
{
	float2 pixelSize = TexBaseSize.xy * blurStrength;
	float4 blurredColor = poissonBlurDepthAware(i.uv, pixelSize);
	return blurredColor;
}
