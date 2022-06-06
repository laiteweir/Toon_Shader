Shader "Toon_Shader/Eyelash - Transparent"
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
			"Queue"="Geometry+2"
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
				"Queue"="Geometry+2"
				// "IgnoreProjector"="True"
				"RenderType"="Overlay"
				"LightMode"="ForwardAdd"
			}
			ZWrite off
			Cull Back
			ZTest LEqual
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
