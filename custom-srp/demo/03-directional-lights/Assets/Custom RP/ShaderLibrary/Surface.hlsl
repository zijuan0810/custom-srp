#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface 
{
    float3 normal;
    
    float3 viewDirection;
    
    float3 color;
    float alpha;
    float metallic;
    
    /**
     * \brief 直觉光滑度，即线性光滑度
     */
    float smoothness;
};

#endif