Shader "Toon_Shader/Blush - Transparent"
{
	Properties
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_ShadowColor ("Shadow Color", Color) = (0.8, 0.8, 1, 1)

		_MainTex ("Diffuse", 2D) = "white" {}
		_FalloffSampler ("Falloff Control", 2D) = "white" {}
		_RimLightSampler ("RimLight Control", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"Queue"="Geometry+3"
		}
		
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha, One One
			ZWrite Off
			Tags
			{
				"IgnoreProjector"="True"
				"RenderType"="Overlay"
				"LightMode"="ForwardBase"
			}
			Cull Back
			ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CharaBlush.hlsl"
			ENDCG
		}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha, One One
			ZWrite Off
			Tags
			{
				"IgnoreProjector"="True"
				"RenderType"="Overlay"
				"LightMode"="ForwardAdd"
			}
			Cull Back
			ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_fwdadd
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CharaBlush.hlsl"
			ENDCG
		}
	}

	FallBack "Transparent/Cutout/Diffuse"
}
