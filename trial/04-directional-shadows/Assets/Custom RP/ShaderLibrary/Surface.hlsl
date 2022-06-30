#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface
{
    /**
     * \brief the vertex postion in the world space
     */
    float3 position;
    float3 normal;
    float3 viewDirection;
    float depth;
    float3 color;
    float alpha;
    float metallic;
    float smoothness;
    float dither;
};

#endif
