// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "RST/Sprites diffuse dissolve"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
		[HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
		[HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
		[PerRendererData] _AlphaTex ("External Alpha", 2D) = "white" {}
		[PerRendererData] _EnableExternalAlpha ("Enable External Alpha", Float) = 0

		_DissolveTex("Dissolve Map", 2D) = "white" {}
		_DissolveEdgeColor("Dissolve Edge Color", Color) = (1,1,1,0)
		_DissolveIntensity("Dissolve Intensity", Range(0.0, 1.0)) = 0
		_DissolveEdgeRange("Dissolve Edge Range", Range(0.0, 1.0)) = 0
		_DissolveEdgeMultiplier("Dissolve Edge Multiplier", Float) = 1
	}

	SubShader
	{
		Tags
		{
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		CGPROGRAM
		#pragma surface surf Lambert vertex:vert nofog nolightmap nodynlightmap keepalpha noinstancing

		#pragma multi_compile _ PIXELSNAP_ON
		#pragma multi_compile _ ETC1_EXTERNAL_ALPHA
		
		#include "UnityCG.cginc"

		#ifdef UNITY_INSTANCING_ENABLED

			UNITY_INSTANCING_BUFFER_START(PerDrawSprite)
			// SpriteRenderer.Color while Non-Batched/Instanced.
			fixed4 unity_SpriteRendererColorArray[UNITY_INSTANCED_ARRAY_SIZE];
			// this could be smaller but that's how bit each entry is regardless of type
			float4 unity_SpriteFlipArray[UNITY_INSTANCED_ARRAY_SIZE];
			UNITY_INSTANCING_BUFFER_END(PerDrawSprite)

			#define _RendererColor unity_SpriteRendererColorArray[unity_InstanceID]
			#define _Flip unity_SpriteFlipArray[unity_InstanceID]

		#endif // instancing

		CBUFFER_START(UnityPerDrawSprite)
		#ifndef UNITY_INSTANCING_ENABLED
		fixed4 _RendererColor;
		float4 _Flip;
		#endif
		float _EnableExternalAlpha;
		CBUFFER_END

		sampler2D _MainTex;
		sampler2D _AlphaTex;
		fixed4 _Color;

		sampler2D _DissolveTex;
		uniform fixed4 _DissolveEdgeColor;
		uniform fixed _DissolveEdgeRange;
		uniform fixed _DissolveIntensity;
		uniform fixed _DissolveEdgeMultiplier;

		fixed4 SampleSpriteTexture(float2 uv)
		{
			fixed4 color = tex2D(_MainTex, uv);

			#if ETC1_EXTERNAL_ALPHA
			fixed4 alpha = tex2D(_AlphaTex, uv);
			color.a = lerp(color.a, alpha.r, _EnableExternalAlpha);
			#endif

			return color;
		}

		struct Input
		{
			float2 uv_MainTex;
			fixed4 color;
		};

		void vert(inout appdata_full v, out Input o)
		{
			v.vertex.xy *= _Flip.xy;

			#if defined(PIXELSNAP_ON)
			v.vertex = UnityPixelSnap(v.vertex);
			#endif

			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.color = v.color * _Color * _RendererColor;
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			fixed4 texColor = SampleSpriteTexture(IN.uv_MainTex) * IN.color;
			texColor.rgb *= texColor.a;

			fixed4 dissolveColor = tex2D(_DissolveTex, IN.uv_MainTex); // using IN.uv_DissolveTex
			fixed dissolveClip = dissolveColor.r - _DissolveIntensity;
			fixed edgeRamp = max(0, _DissolveEdgeRange - dissolveClip);
			clip(dissolveClip);

			fixed4 c = lerp(texColor, _DissolveEdgeColor, min(1, edgeRamp * _DissolveEdgeMultiplier));
			o.Albedo = c;
			o.Alpha = texColor.a;
		}
		ENDCG
	}
}
