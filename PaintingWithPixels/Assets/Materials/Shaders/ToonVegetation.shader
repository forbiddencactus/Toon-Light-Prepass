// Swiped from: https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/master/DefaultResourcesExtra/Unlit/Unlit-AlphaTest.shader
// Modded to fit our toon pipe. 

Shader "Toon/Toon Vegetation" 
{
    Properties 
    {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }

    SubShader 
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 100
        Cull Off // Don't cull the vegetation's backface. 

        Pass 
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t 
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;

                // Screen UV for the fragment.
                float4 fragScreenUV: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;
            uniform sampler2D _globalRamp;
            uniform sampler2D _lightTexture;
            uniform float4 _globalFogColour;
            uniform float _globalFogFadeFactor;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                // Transform clip space vertex to screenspace, so we can sample from our normal and depth buffers. 
                o.fragScreenUV = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord);
                clip(col.a - _Cutoff);

                // Sample deferred light and ramp texture...
                //float4 deferredLight = tex2D(_lightTexture, i.fragScreenUV.xy / i.fragScreenUV.w); 
                float4 rampCol = tex2D(_globalRamp, float2(0.1, 0.5));

                // Apply our atmospheric fog...
                float4 fragColour = col * rampCol;// + (deferredLight * deferredLight.w); // Little glitches with the transparency cutout that I won't fix. 
                float interpolationValue = (1 - i.vertex.z) * _globalFogFadeFactor;
                return lerp(fragColour, _globalFogColour,smoothstep(0,1, interpolationValue));
            }
            ENDCG
        }
    }
}