// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Character shader
// Includes falloff shadow and highlight, specular, reflection, and normal mapping

#define ENABLE_CAST_SHADOWS

// Material parameters
float4 _Color;
float4 _ShadowColor;
float4 _LightColor0;
float _SpecularPower;
float _UseAnisotropic;
float4 _MainTex_ST;

// Textures
sampler2D _MainTex;
sampler2D _FalloffSampler;
sampler2D _RimLightSampler;
sampler2D _SpecularReflectionSampler;
sampler2D _EnvMapSampler;
sampler2D _NormalMapSampler;

// Constants
#define FALLOFF_POWER 0.3

#ifdef ENABLE_CAST_SHADOWS

// Structure from vertex shader to fragment shader
struct v2f
{
	float4 pos      : SV_POSITION;
	LIGHTING_COORDS( 0, 1 )
	float2 uv       : TEXCOORD2;
	float3 eyeDir   : TEXCOORD3;
	float3 lightDir : TEXCOORD4;
	float3 normal   : TEXCOORD5;
	float3 tangent  : TEXCOORD6;
#ifdef ENABLE_NORMAL_MAP
	float3 binormal : TEXCOORD7;
#endif
};

#else

// Structure from vertex shader to fragment shader
struct v2f
{
	float4 pos      : SV_POSITION;
	float2 uv       : TEXCOORD0;
	float3 eyeDir   : TEXCOORD1;
	float3 lightDir : TEXCOORD2;
	float3 normal   : TEXCOORD3;
	float3 tangent  : TEXCOORD4;
#ifdef ENABLE_NORMAL_MAP
	float3 binormal : TEXCOORD5;
#endif
};

#endif

// Float types
#define float_t    half
#define float2_t   half2
#define float3_t   half3
#define float4_t   half4
#define float3x3_t half3x3

// Vertex shader
v2f vert( appdata_tan v )
{
	v2f o;
	o.pos = UnityObjectToClipPos( v.vertex );
	o.uv.xy = TRANSFORM_TEX( v.texcoord.xy, _MainTex );
	o.normal = normalize( mul( unity_ObjectToWorld, float4_t( v.normal, 0 ) ).xyz );
	
	// Eye direction vector
	half4 worldPos = mul( unity_ObjectToWorld, v.vertex );
	o.eyeDir.xyz = normalize( _WorldSpaceCameraPos.xyz - worldPos.xyz ).xyz;
	o.lightDir = WorldSpaceLightDir( v.vertex );
	o.tangent = normalize( mul( unity_ObjectToWorld, float4_t( v.tangent.xyz, 0 ) ).xyz );
	
#ifdef ENABLE_NORMAL_MAP	
	// Binormal and tangent (for normal map)
	o.binormal = normalize( cross( o.normal, o.tangent ) * v.tangent.w );
#endif

#ifdef ENABLE_CAST_SHADOWS
	TRANSFER_VERTEX_TO_FRAGMENT( o );
#endif

	return o;
}

// Overlay blend
inline float3_t GetOverlayColor( float3_t inUpper, float3_t inLower )
{
	float3_t oneMinusLower = float3_t( 1.0, 1.0, 1.0 ) - inLower;
	float3_t valUnit = 2.0 * oneMinusLower;
	float3_t minValue = 2.0 * inLower - float3_t( 1.0, 1.0, 1.0 );
	float3_t greaterResult = inUpper * valUnit + minValue;

	float3_t lowerResult = 2.0 * inLower * inUpper;

	half3 lerpVals = round(inLower);
	return lerp(lowerResult, greaterResult, lerpVals);
}

inline float_t ShadeSpecular( float3_t N, float3_t V, float3_t L, float_t specularPower)
{
	float3_t H = normalize(V + L);
	float_t specular = dot( N, H );
	float_t specularLog = 0.0;
    if (specular > 0.0)
    {
        specularLog = pow(specular, specularPower);
    }
	return specularLog;
}

inline float_t ShadeAnisotropic( float3_t T, float3_t V, float3_t L, float_t specularPower)
{
	float3_t H = normalize(V + L);
    float_t dotTH = dot(T, H);
    float_t sinTH = sqrt(1.0 - dotTH * dotTH);
    float_t dirAtten = smoothstep(-1.0, 0.0, dotTH);
    return dirAtten * pow(sinTH, specularPower);
}

#ifdef ENABLE_NORMAL_MAP

// Compute normal from normal map
inline float3_t GetNormalFromMap( v2f input )
{
	float3_t normalVec = normalize( tex2D( _NormalMapSampler, input.uv ).xyz * 2.0 - 1.0 );
	float3x3_t localToWorldTranspose = float3x3_t(
		input.tangent,
		input.binormal,
		input.normal
	);
	
	normalVec = normalize( mul( normalVec, localToWorldTranspose ) );
	return normalVec;
}

#endif

// Fragment shader
float4 frag( v2f i ) : COLOR
{
	float4_t diffSamplerColor = tex2D( _MainTex, i.uv.xy );

#ifdef ENABLE_NORMAL_MAP
	float3_t normalVec = GetNormalFromMap( i );
#else
	float3_t normalVec = i.normal;
#endif

	// Falloff. Convert the angle between the normal and the camera direction into a lookup for the gradient
	float_t normalDotEye = dot( normalVec, i.eyeDir.xyz );
	float_t falloffU = clamp( 1.0 - abs( normalDotEye ), 0.02, 0.98 );
	float4_t falloffSamplerColor = FALLOFF_POWER * tex2D( _FalloffSampler, float2( falloffU, 0.25f ) );
	float3_t shadowColor = diffSamplerColor.rgb * diffSamplerColor.rgb;
	float3_t combinedColor = lerp( diffSamplerColor.rgb, shadowColor, falloffSamplerColor.r );
	combinedColor *= ( 1.0 + falloffSamplerColor.rgb * falloffSamplerColor.a );

	// Specular
	// Use the eye vector as the light vector
	float4_t reflectionMaskColor = tex2D( _SpecularReflectionSampler, i.uv.xy );
	float3_t highlight = _UseAnisotropic ? ShadeAnisotropic(i.tangent, i.eyeDir, i.lightDir, _SpecularPower) : ShadeSpecular(normalVec, i.eyeDir, i.lightDir, _SpecularPower);
	float3_t highlightColor = highlight * reflectionMaskColor.rgb * diffSamplerColor.rgb;
	combinedColor += highlightColor;
	
	// Reflection
	float3_t reflectVector = reflect( -i.eyeDir.xyz, normalVec ).xzy;
	float2_t sphereMapCoords = 0.5 * ( float2_t( 1.0, 1.0 ) + reflectVector.xy );
	float3_t reflectColor = tex2D( _EnvMapSampler, sphereMapCoords ).rgb;
	reflectColor = GetOverlayColor( reflectColor, combinedColor );

	combinedColor = lerp( combinedColor, reflectColor, reflectionMaskColor.a );
	combinedColor *= _Color.rgb * _LightColor0.rgb;
	float opacity = diffSamplerColor.a * _Color.a * _LightColor0.a;

#ifdef ENABLE_CAST_SHADOWS
	// Cast shadows
	shadowColor = _ShadowColor.rgb * combinedColor;
	float_t attenuation = saturate( 2.0 * LIGHT_ATTENUATION( i ) - 1.0 );
	combinedColor = lerp( shadowColor, combinedColor, attenuation );
#endif

	// Rimlight
	float_t rimlightDot = saturate( 0.5 * ( dot( normalVec, i.lightDir ) + 1.0 ) );
	falloffU = saturate( rimlightDot * falloffU );
	falloffU = tex2D( _RimLightSampler, float2( falloffU, 0.25f ) ).r;
	float3_t lightColor = diffSamplerColor.rgb; // * 2.0;
	combinedColor += falloffU * lightColor;

	return float4( combinedColor, opacity );
}
