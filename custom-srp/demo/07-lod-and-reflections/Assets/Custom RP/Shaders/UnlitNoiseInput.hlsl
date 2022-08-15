#ifndef CUSTOM_UNLIT_NOISE_INPUT_INCLUDED
#define CUSTOM_UNLIT_NOISE_INPUT_INCLUDED

// #include "Noise/noise2D.hlsl"
// #include "Noise/classicnoise2D.hlsl"
#include "Noise/cellular2D.hlsl"

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_NoiseMap);
SAMPLER(sampler_NoiseMap);


UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _NoiseScaleX)
	UNITY_DEFINE_INSTANCED_PROP(float, _NoiseScaleY)
	UNITY_DEFINE_INSTANCED_PROP(float, _NoiseSpeedX)
	UNITY_DEFINE_INSTANCED_PROP(float, _NoiseSpeedY)
	UNITY_DEFINE_INSTANCED_PROP(float, _NoiseBrightOffset)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float2 TransformBaseUV (float2 baseUV)
{
	return baseUV;
	// float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	// float2 outUV = baseUV * baseST.xy + baseST.zw;
	// return outUV;
}

float4 GetBase (float2 baseUV)
{
	// return float4(0.5 + 0.5 * float3(n, n, n), 1.0); // output noise
	
	float noiseSpeedX = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NoiseSpeedX);
	float noiseSpeedY = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NoiseSpeedY);
	float noiseScaleX = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NoiseScaleX);
	float noiseScaleY = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NoiseScaleY);
	float noiseBrightOffset = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NoiseBrightOffset);
	
	// 噪点图采样，用于主纹理的UV偏移的
	float4 texX = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, baseUV + float2(_Time.x * noiseSpeedX, 0));
	float4 texY = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, baseUV + float2(0, _Time.x * noiseSpeedY));
	// float2 ditherUV = float2(texX.r, texY.r);
	// float2 ditherUV = float2(RandomSampling(baseUV + float2(_Time.x * noiseSpeedX, 0)), RandomSampling(baseUV + float2(0, _Time.x * noiseSpeedY)));
	float2 ditherUV;
	// 2D Perlin noise
	{
		float x = cellular((baseUV + float2(_Time.x * noiseSpeedX, 0)) * 10.0);
		float y = cellular((baseUV + float2(0, _Time.x * noiseSpeedY)) * 10.0);
		ditherUV = 0.5 + 0.5 * float2(x, y);
	}
	
	ditherUV -= noiseBrightOffset; // 0~1 to ==> -_NoiseBrightOffset~ 1 - _NoiseBrightOffset
	ditherUV *= float2(noiseScaleX, noiseScaleY); // 扰动放大系数
	// 加上扰动UV后再采样主纹理
	
	float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV + ditherUV);
	float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	return baseMap * baseColor;
}

float3 GetEmission (float2 baseUV) {
	return GetBase(baseUV).rgb;
}

float GetCutoff (float2 baseUV) {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

float GetMetallic (float2 baseUV) {
	return 0.0;
}

float GetSmoothness (float2 baseUV) {
	return 0.0;
}

#endif