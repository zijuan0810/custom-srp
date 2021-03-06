Shader "Custom RP/Unlit Blend"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Op", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 0
    }
    
    SubShader
    {
        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            BlendOp [_BlendOp] // (is default anyway)
            ZWrite [_ZWrite]
            
            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #include "./UnlitBlendPass.hlsl"
            ENDHLSL
        }
    }
}
