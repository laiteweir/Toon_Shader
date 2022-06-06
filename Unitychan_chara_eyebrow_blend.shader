Shader "Toon_Shader/Eyebrow - Transparent"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_ShadowColor ("Shadow Color", Color) = (0.8, 0.8, 1, 1)
		_StencilValue ("Stencil Value", Int) = 0
	
		_MainTex ("Diffuse", 2D) = "white" {}
		_FalloffSampler ("Falloff Control", 2D) = "white" {}
		_RimLightSampler ("RimLight Control", 2D) = "white" {}
	}

	SubShader
	{ 
		Tags
		{
			"Queue"="Geometry-100"
		}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha, One One
			Tags
			{
				"RenderType"="Overlay"
				"LightMode"="ForwardBase"
			}
			Cull Back
			ZTest LEqual
			Stencil
			{
                Ref [_StencilValue]
                Comp Always
                Pass Replace
                Fail Replace
            }
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CharaSkin.hlsl"
			ENDCG
		}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha, One One
			Tags
			{
				"RenderType"="Overlay"
				"LightMode"="ForwardAdd"
			}
			ZWrite off
			Cull Back
			ZTest LEqual
			Stencil
			{
                Ref [_StencilValue]
                Comp Always
                Pass Replace
                Fail Replace
            }
			CGPROGRAM
			#pragma multi_compile_fwd
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CharaSkin.hlsl"
			ENDCG
		}
	}

	FallBack "Transparent/Cutout/Diffuse"
}
