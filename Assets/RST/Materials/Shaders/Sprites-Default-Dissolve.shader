// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "RST/Sprites default dissolve"
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

		Pass
		{
		CGPROGRAM
			#pragma vertex SpriteVert
			#pragma fragment SpriteFrag
			#pragma target 2.0
			#pragma multi_compile_instancing
			#pragma multi_compile _ PIXELSNAP_ON
			#pragma multi_compile _ ETC1_EXTERNAL_ALPHA

			// from here on the code is copied from UnitySprites.cginc (5.6.1 builtin shaders) and modified
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

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color	: COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f SpriteVert(appdata_t IN)
			{
				v2f OUT;

				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

				#ifdef UNITY_INSTANCING_ENABLED
				IN.vertex.xy *= _Flip.xy;
				#endif

				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color * _Color * _RendererColor;

				#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap(OUT.vertex);
				#endif
				return OUT;
			}

			fixed4 SampleSpriteTexture(float2 uv)
			{
				fixed4 color = tex2D(_MainTex, uv);

				#if ETC1_EXTERNAL_ALPHA
				fixed4 alpha = tex2D(_AlphaTex, uv);
				color.a = lerp(color.a, alpha.r, _EnableExternalAlpha);
				#endif

				return color;
			}

			fixed4 SpriteFrag(v2f IN) : SV_Target
			{
				fixed4 texColor = SampleSpriteTexture(IN.texcoord) * IN.color;
				texColor.rgb *= texColor.a;
				
				fixed4 dissolveColor = tex2D(_DissolveTex, IN.texcoord); // using IN.uv_DissolveTex
				fixed dissolveClip = dissolveColor.r - _DissolveIntensity;
				fixed edgeRamp = max(0, _DissolveEdgeRange - dissolveClip);
				clip(dissolveClip);

				fixed4 c = lerp(texColor, _DissolveEdgeColor, min(1, edgeRamp * _DissolveEdgeMultiplier));
				c.a = texColor.a;
				return c;
			}

		ENDCG
		}
	}
}
