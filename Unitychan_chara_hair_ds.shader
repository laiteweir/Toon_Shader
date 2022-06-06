Shader "Toon_Shader/Hair - Double-sided"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_ShadowColor ("Shadow Color", Color) = (0.8, 0.8, 1, 1)
		_SpecularPower ("Specular Power", Float) = 20
		_UseAnisotropic ("Use Anisotropic", Float) = 0.0
		_EdgeThickness ("Outline Thickness", Float) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _UseStencil ("Stencil Setting", Float) = 8
        _StencilValue ("Stencil Value", Int) = 0
		
		_MainTex ("Diffuse", 2D) = "white" {}
		_FalloffSampler ("Falloff Control", 2D) = "white" {}
		_RimLightSampler ("RimLight Control", 2D) = "white" {}
		_SpecularReflectionSampler ("Specular / Reflection Mask", 2D) = "white" {}
		_EnvMapSampler ("Environment Map", 2D) = "" {} 
		_NormalMapSampler ("Normal Map", 2D) = "" {} 
	}

	SubShader
	{		
		Tags
		{
			"Queue"="Geometry"
		}
		
		Pass
		{
			Tags
			{
				"RenderType"="Opaque"
				"LightMode"="ForwardBase"
			}
			Cull Off
			ZTest LEqual
			Stencil
			{
                Ref [_StencilValue]
                Comp [_UseStencil]
                Pass Keep
                Fail Keep
            }
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#define ENABLE_NORMAL_MAP
			#include "CharaMain.hlsl"
			ENDCG
		}

		Pass
		{
			Tags
			{
				"RenderType"="Opaque"
				"LightMode"="ForwardBase"
			}
			Cull Front
			ZTest Less
			Stencil
			{
                Ref [_StencilValue]
                Comp [_UseStencil]
                Pass Keep
                Fail Keep
            }
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "CharaOutline.hlsl"
			ENDCG
		}

		Pass
		{
			Tags
			{
				"RenderType"="Opaque"
				"LightMode"="ForwardAdd"
			}
			ZWrite off
			Blend One One
			Cull Off
			ZTest LEqual
			Stencil
			{
                Ref [_StencilValue]
                Comp [_UseStencil]
                Pass Keep
                Fail Keep
            }
			CGPROGRAM
			#pragma multi_compile_fwdadd
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#define ENABLE_NORMAL_MAP
			#include "CharaMain.hlsl"
			ENDCG
		}

	}

	FallBack "Transparent/Cutout/Diffuse"
}
