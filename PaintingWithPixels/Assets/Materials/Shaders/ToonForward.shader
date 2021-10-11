Shader "Toon/ToonForward"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightColour ("Light Colour", Color) = (1,1,1,1)
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
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                // World space normal for the fragment
                float3 fragNormal: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform sampler2D _globalRamp;
            uniform float4 _globalDefaultLightDir;
            uniform float4 _globalFogColour;
            uniform float _globalFogFadeFactor;
            float4 _LightColour;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Transform the vertex normal from object space to world space (this is using matrices internally!)
                o.fragNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Get the dot product, and convert from [-1,1] to [0,1]
                float theDot = dot(i.fragNormal, _globalDefaultLightDir.xyz) * 0.5 + 0.5;

                float4 rampCol = tex2D(_globalRamp, float2(theDot, 0.5));
                
                // sample the main texture
                fixed4 col = tex2D(_MainTex, i.uv);

                // Apply our atmospheric fog..
                float4 fragColour = col * rampCol + (_LightColour * 0.1);
                float interpolationValue = (1 - i.vertex.z) * _globalFogFadeFactor;
                return lerp(fragColour, _globalFogColour,smoothstep(0,1, interpolationValue));
            }
            ENDCG
        }
    }
}
