Shader "Toon/ToonDeferred"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                
                // Screen UV for the fragment.
                float4 fragScreenUV: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform sampler2D _globalRamp;
            uniform sampler2D _lightTexture;
            uniform float4 _globalFogColour;
            uniform float _globalFogFadeFactor;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // Transform clip space vertex to screenspace, so we can sample from our normal and depth buffers. 
                o.fragScreenUV = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 deferredLight = tex2D(_lightTexture, i.fragScreenUV.xy / i.fragScreenUV.w);

                float4 rampCol = tex2D(_globalRamp, float2(0.1, 0.5));
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                float4 fragColour = col * rampCol + (deferredLight * deferredLight.w);
                float interpolationValue = (1 - i.vertex.z) * _globalFogFadeFactor;
                return lerp(fragColour, _globalFogColour,smoothstep(0,1, interpolationValue));
            }
            ENDCG
        }
    }
}
