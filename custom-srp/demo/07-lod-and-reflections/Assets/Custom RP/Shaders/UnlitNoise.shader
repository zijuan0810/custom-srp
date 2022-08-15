Shader "Custom RP/Unlit Noise"
{
    Properties
    {
        [NoScaleOffset] _BaseMap ("Texture", 2D) = "white" {}
        [NoScaleOffset] _NoiseMap ("NoiseTex", 2D) = "white" {}             // 噪点图
        _NoiseScaleX ("NoiseScaleX", Range(0, 1)) = 0.1                     // 水平噪点放大系数
        _NoiseScaleY ("NoiseScaleY", Range(0, 1)) = 0.1                     // 垂直放大系数
        _NoiseSpeedX ("NoiseSpeedX", Range(0, 10)) = 1                      // 水平扰动速度
        _NoiseSpeedY ("NoiseSpeedY", Range(0, 10)) = 1                      // 垂直扰动速度
        _NoiseBrightOffset ("NoiseBrightOffset", Range(0, 0.9)) = 0.25      // 噪点图整体的数值偏移
        
        [HDR] _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
        [KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
    }

    SubShader
    {
        HLSLINCLUDE
        #include "../ShaderLibrary/Common.hlsl"
        #include "UnlitNoiseInput.hlsl"
        ENDHLSL

        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma target 3.5
            #pragma shader_feature _CLIPPING
            #pragma multi_compile_instancing
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #include "UnlitNoisePass.hlsl"
            ENDHLSL
        }
    }

    CustomEditor "CustomShaderGUI"
}