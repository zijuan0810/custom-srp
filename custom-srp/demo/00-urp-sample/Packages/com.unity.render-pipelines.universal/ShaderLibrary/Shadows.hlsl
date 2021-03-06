#ifndef UNIVERSAL_SHADOWS_INCLUDED
#define UNIVERSAL_SHADOWS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
#include "Core.hlsl"

#define SHADOWS_SCREEN 0
#define MAX_SHADOW_CASCADES 4

#if !defined(_RECEIVE_SHADOWS_OFF)
    #if defined(_MAIN_LIGHT_SHADOWS)
        #define MAIN_LIGHT_CALCULATE_SHADOWS

        //未开启主光源级联阴影时，使用阴影空间坐标的顶点插值
        #if !defined(_MAIN_LIGHT_SHADOWS_CASCADE)
            #define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
    #endif

    #if defined(_ADDITIONAL_LIGHT_SHADOWS)
        #define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
    #endif
#endif

//有额外的方向光或者开启主光源级联阴影时，使用世界空间的位置插值
#if defined(_ADDITIONAL_LIGHTS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE)
    #define REQUIRES_WORLD_SPACE_POS_INTERPOLATOR
#endif

SCREENSPACE_TEXTURE(_ScreenSpaceShadowmapTexture);
SAMPLER(sampler_ScreenSpaceShadowmapTexture);

TEXTURE2D_SHADOW(_MainLightShadowmapTexture);
SAMPLER_CMP(sampler_MainLightShadowmapTexture);

TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture);
SAMPLER_CMP(sampler_AdditionalLightsShadowmapTexture);

// GLES3 causes a performance regression in some devices when using CBUFFER.
#ifndef SHADER_API_GLES3
CBUFFER_START(MainLightShadows)
#endif
// Last cascade is initialized with a no-op matrix. It always transforms
// shadow coord to half3(0, 0, NEAR_PLANE). We use this trick to avoid
// branching since ComputeCascadeIndex can return cascade index = MAX_SHADOW_CASCADES
float4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
float4      _CascadeShadowSplitSpheres0;
float4      _CascadeShadowSplitSpheres1;
float4      _CascadeShadowSplitSpheres2;
float4      _CascadeShadowSplitSpheres3;
float4      _CascadeShadowSplitSphereRadii;
half4       _MainLightShadowOffset0;
half4       _MainLightShadowOffset1;
half4       _MainLightShadowOffset2;
half4       _MainLightShadowOffset3;
half4       _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise)
float4      _MainLightShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
StructuredBuffer<ShadowData> _AdditionalShadowsBuffer;
StructuredBuffer<int> _AdditionalShadowsIndices;
half4       _AdditionalShadowOffset0;
half4       _AdditionalShadowOffset1;
half4       _AdditionalShadowOffset2;
half4       _AdditionalShadowOffset3;
float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
#else
// GLES3 causes a performance regression in some devices when using CBUFFER.
#ifndef SHADER_API_GLES3
CBUFFER_START(AdditionalLightShadows)
#endif
float4x4    _AdditionalLightsWorldToShadow[MAX_VISIBLE_LIGHTS];
half4       _AdditionalShadowParams[MAX_VISIBLE_LIGHTS];
half4       _AdditionalShadowOffset0;
half4       _AdditionalShadowOffset1;
half4       _AdditionalShadowOffset2;
half4       _AdditionalShadowOffset3;
float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif
#endif

float4 _ShadowBias; // x: depth bias, y: normal bias

#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0

struct ShadowSamplingData
{
    half4 shadowOffset0;
    half4 shadowOffset1;
    half4 shadowOffset2;
    half4 shadowOffset3;
    float4 shadowmapSize;
};

ShadowSamplingData GetMainLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData;
    shadowSamplingData.shadowOffset0 = _MainLightShadowOffset0;
    shadowSamplingData.shadowOffset1 = _MainLightShadowOffset1;
    shadowSamplingData.shadowOffset2 = _MainLightShadowOffset2;
    shadowSamplingData.shadowOffset3 = _MainLightShadowOffset3;
    shadowSamplingData.shadowmapSize = _MainLightShadowmapSize;
    return shadowSamplingData;
}

ShadowSamplingData GetAdditionalLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData;
    shadowSamplingData.shadowOffset0 = _AdditionalShadowOffset0;
    shadowSamplingData.shadowOffset1 = _AdditionalShadowOffset1;
    shadowSamplingData.shadowOffset2 = _AdditionalShadowOffset2;
    shadowSamplingData.shadowOffset3 = _AdditionalShadowOffset3;
    shadowSamplingData.shadowmapSize = _AdditionalShadowmapSize;
    return shadowSamplingData;
}

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
half4 GetMainLightShadowParams()
{
    return _MainLightShadowParams;
}


// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
half4 GetAdditionalLightShadowParams(int lightIndex)
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    return _AdditionalShadowsBuffer[lightIndex].shadowParams;
#else
    return _AdditionalShadowParams[lightIndex];
#endif
}

half SampleScreenSpaceShadowmap(float4 shadowCoord)
{
    shadowCoord.xy /= shadowCoord.w;

    // The stereo transform has to happen after the manual perspective divide
    shadowCoord.xy = UnityStereoTransformScreenSpaceTex(shadowCoord.xy);

#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
    half attenuation = SAMPLE_TEXTURE2D_ARRAY(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, shadowCoord.xy, unity_StereoEyeIndex).x;
#else
    half attenuation = SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, shadowCoord.xy).x;
#endif

    return attenuation;
}

real SampleShadowmapFiltered(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData)
{
    real attenuation;

#if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
    // 4-tap hardware comparison
    real4 attenuation4;
    attenuation4.x = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset0.xyz);
    attenuation4.y = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset1.xyz);
    attenuation4.z = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset2.xyz);
    attenuation4.w = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset3.xyz);
    attenuation = dot(attenuation4, 0.25);
#else
    //为了实现类似半阴影一样的软阴影效果，肯定要对ShadowMap做某种模糊操作。
    //这里使用5x5的卷积核，输入shadowMap的长宽以及倒数，实际UV，输出9个采样点的UV和权重
    //为了防止出现采样失真，必须先做模糊后采样
    float fetchesWeights[9];
    float2 fetchesUV[9];
    SampleShadow_ComputeSamples_Tent_5x5(samplingData.shadowmapSize, shadowCoord.xy, fetchesWeights, fetchesUV);

    //不再单点采样，而是根据uv进行加权计算
    attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[0].xy, shadowCoord.z));
    attenuation += fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[1].xy, shadowCoord.z));
    attenuation += fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[2].xy, shadowCoord.z));
    attenuation += fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[3].xy, shadowCoord.z));
    attenuation += fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[4].xy, shadowCoord.z));
    attenuation += fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[5].xy, shadowCoord.z));
    attenuation += fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[6].xy, shadowCoord.z));
    attenuation += fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[7].xy, shadowCoord.z));
    attenuation += fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[8].xy, shadowCoord.z));
#endif

    return attenuation;
}

// 采样阴影贴图
real SampleShadowmap(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord,
    ShadowSamplingData samplingData, half4 shadowParams, bool isPerspectiveProjection = true)
{
    // Compiler will optimize this branch away as long as isPerspectiveProjection is known at compile time
    if (isPerspectiveProjection)
        shadowCoord.xyz /= shadowCoord.w;

    //阴影强度决定了投影是死黑还是半透明，因为场景里现在没有环境光而且是单光源，所以除了照亮的地方之外，所有的景物都是一片死黑。
    //每个光源投下的阴影强度都是不一致的，所以我们传一个ShadowStrength进去用来做插值
    real attenuation;
    real shadowStrength = shadowParams.x;

    // TODO: We could branch on if this light has soft shadows (shadowParams.y) to save perf on some platforms.
    //使用软阴影时需要多重采样
#ifdef _SHADOWS_SOFT
    attenuation = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(ShadowMap, sampler_ShadowMap), shadowCoord, samplingData);
#else
    // 1-tap hardware comparison
    attenuation = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz);
#endif

    attenuation = LerpWhiteTo(attenuation, shadowStrength);

    // Shadow coords that fall out of the light frustum volume must always return attenuation 1.0
    // TODO: We could use branch here to save some perf on some platforms.
    return BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;
}

/**
 * \brief 计算世界空间中顶点位置的级联索引值
 * \param positionWS 世界空间的顶点位置
 * \return 级联索引
 */
half ComputeCascadeIndex(float3 positionWS)
{
    //计算当前像素世界坐标与包围球中心的距离
    float3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
    float3 fromCenter1 = positionWS - _CascadeShadowSplitSpheres1.xyz;
    float3 fromCenter2 = positionWS - _CascadeShadowSplitSpheres2.xyz;
    float3 fromCenter3 = positionWS - _CascadeShadowSplitSpheres3.xyz;
    //这里用点乘其实就是算距离的平方
    float4 distances2 = float4(
        dot(fromCenter0, fromCenter0),
        dot(fromCenter1, fromCenter1),
        dot(fromCenter2, fromCenter2),
        dot(fromCenter3, fromCenter3));

    //判断像素是否在包围求内
    half4 weights = half4(distances2 < _CascadeShadowSplitSphereRadii);
    //如果像素同时在多个包围球内，则取index最小的（即离相机更近的）
    //CSM中通常如果不同层级的shadowmap overlap，然后同时处于两张shadowmap overlap处的像素点会同时在两个shadowmap上做采样然后插值
    weights.yzw = saturate(weights.yzw - weights.xyz);

    return 4 - dot(weights, half4(4, 3, 2, 1));
}

float4 TransformWorldToShadowCoord(float3 positionWS)
{
#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
    half cascadeIndex = ComputeCascadeIndex(positionWS);
#else
    half cascadeIndex = 0;
#endif

    return mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));
}

/**
 * \brief 获取主光源实时阴影的衰减值，即通过顶点在阴影贴图中的坐标位置从ShadowMap深度贴图中采样
 * \param shadowCoord 顶点在阴影贴图中的坐标位置
 * \return 阴影的衰减值
 */
half MainLightRealtimeShadow(float4 shadowCoord)
{
#if !defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    return 1.0h;
#endif

    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture),
        shadowCoord, shadowSamplingData, shadowParams, false);
}

half AdditionalLightRealtimeShadow(int lightIndex, float3 positionWS)
{
#if !defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
    return 1.0h;
#endif

    ShadowSamplingData shadowSamplingData = GetAdditionalLightShadowSamplingData();

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    lightIndex = _AdditionalShadowsIndices[lightIndex];

    // We have to branch here as otherwise we would sample buffer with lightIndex == -1.
    // However this should be ok for platforms that store light in SSBO.
    UNITY_BRANCH
    if (lightIndex < 0)
        return 1.0;

    float4 shadowCoord = mul(_AdditionalShadowsBuffer[lightIndex].worldToShadowMatrix, float4(positionWS, 1.0));
#else
    float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[lightIndex], float4(positionWS, 1.0));
#endif

    half4 shadowParams = GetAdditionalLightShadowParams(lightIndex);
    return SampleShadowmap(TEXTURE2D_ARGS(_AdditionalLightsShadowmapTexture, sampler_AdditionalLightsShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, true);
}

float4 GetShadowCoord(VertexPositionInputs vertexInput)
{
    return TransformWorldToShadowCoord(vertexInput.positionWS);
}

/**
 * \brief 应用阴影偏移
 */
float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
{
    float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
    float scale = invNdotL * _ShadowBias.y; //法线偏移

    // normal bias is negative since we want to apply an inset normal offset
    positionWS = lightDirection * _ShadowBias.xxx + positionWS;
    positionWS = normalWS * scale.xxx + positionWS;
    return positionWS;
}

///////////////////////////////////////////////////////////////////////////////
// Deprecated                                                                 /
///////////////////////////////////////////////////////////////////////////////

// Renamed -> _MainLightShadowParams
#define _MainLightShadowData _MainLightShadowParams

// Deprecated: Use GetMainLightShadowParams instead.
half GetMainLightShadowStrength()
{
    return _MainLightShadowData.x;
}

// Deprecated: Use GetAdditionalLightShadowParams instead.
half GetAdditionalLightShadowStrenth(int lightIndex)
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    return _AdditionalShadowsBuffer[lightIndex].shadowParams.x;
#else
    return _AdditionalShadowParams[lightIndex].x;
#endif
}

// Deprecated: Use SampleShadowmap that takes shadowParams instead of strength.
real SampleShadowmap(float4 shadowCoord, TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), ShadowSamplingData samplingData, half shadowStrength, bool isPerspectiveProjection = true)
{
    half4 shadowParams = half4(shadowStrength, 1.0, 0.0, 0.0);
    return SampleShadowmap(TEXTURE2D_SHADOW_ARGS(ShadowMap, sampler_ShadowMap), shadowCoord, samplingData, shadowParams, isPerspectiveProjection);
}

#endif
