#ifndef CUSTOM_UNLIT_BLEND_PASS_INCLUDED
#define CUSTOM_UNLIT_BLEND_PASS_INCLUDED

#include "../ShaderLibrary/Common.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float4 _MainTex_ST;
CBUFFER_END


struct Attributes 
{
    float3 positionOS : POSITION;
    float2 baseUV : TEXCOORD0;
};

struct Varying 
{
    float4 positionCS : SV_POSITION;
    float2 baseUV : VAR_BASE_UV;
};

Varying UnlitPassVertex(Attributes input)
{
    Varying output;
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(positionWS);
    float4 basesT = _MainTex_ST;
    output.baseUV = input.baseUV * basesT.xy + basesT.zw;
    return output;
}

float4 UnlitPassFragment(Varying input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    float4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.baseUV);
    float4 baseColor = _BaseColor;
    return baseMap * baseColor;
}

#endif //CUSTOM_UNLIT_BLEND_PASS_INCLUDED