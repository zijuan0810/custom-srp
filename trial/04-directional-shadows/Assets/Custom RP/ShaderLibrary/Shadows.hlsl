#ifndef CUSTOM_SHADOWS_INCLUDED
#define CUSTOM_SHADOWS_INCLUDED

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
int _CascadeCount;
float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
CBUFFER_END

struct ShadowData
{
    int cascadeIndex;
    float strength;
};

struct DirectionalShadowData
{
    float strength;
    int tileIndex;
};

ShadowData GetShadowData(Surface surfaceWS)
{
    ShadowData data;
    data.strength = 1.0;

    int i;
    for (i = 0; i < _CascadeCount; i++)
    {
        float4 sphere = _CascadeCullingSpheres[i];
        float distanceSqr = DistanceSquared(surfaceWS.position, sphere.xyz);
        if (distanceSqr < sphere.w)
        {
            break;
        }
    }

    // setting it to zero if we end up beyond the last cascade
    if (i == _CascadeCount)
        data.strength = 0.0;
    
    data.cascadeIndex = i;

    return data;
}

float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);
}

float GetDirectionalShadowAttenuation(DirectionalShadowData shadowData, Surface surfaceWS)
{
    // when the shadow strength is zero then it isn't needed to sample shadows at all, as
    // they have no effect and haven't even been rendered
    if (shadowData.strength <= 0.0)
        return 1.0;

    // converts the surface position (in world space) to shadow tile space
    float3 positionSTS = mul(_DirectionalShadowMatrices[shadowData.tileIndex], float4(surfaceWS.position, 1.0)).xyz;
    float shadow = SampleDirectionalShadowAtlas(positionSTS);
    return lerp(1.0, shadow, shadowData.strength);
}

#endif
