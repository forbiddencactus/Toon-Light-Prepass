Shader "Toon/ToonForwardDeferred"
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

                // Screen UV for the fragment.
                float4 fragScreenUV: TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform sampler2D _globalRamp;
            uniform float4 _globalDefaultLightDir;
            uniform sampler2D _lightTexture;
            uniform float4 _globalFogColour;
            uniform float _globalFogFadeFactor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Transform the vertex normal from object space to world space (this is using matrices internally!)
                o.fragNormal = UnityObjectToWorldNormal(v.normal);

                // Transform clip space vertex to screenspace, so we can sample from our normal and depth buffers. 
                o.fragScreenUV = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Screenspace sample of our light buffer. Since the light buffer was already depth tested, we can assume the data here is good for us. 
                float4 deferredLight = 0;
                deferredLight = tex2D(_lightTexture, i.fragScreenUV.xy / i.fragScreenUV.w);


                // Get the dot product, and convert from [-1,1] to [0,1]
                float theDot = dot(i.fragNormal, _globalDefaultLightDir.xyz) * 0.5 + 0.5;

                // Having the ramp edge looks ugly when the fragment is deferred lit. So let's move the ramp back to 0 if there's deferred light going on. 
                theDot = lerp(0, theDot, step(length(deferredLight.rgb), 0.1));

                // Sample the ramp texture. 
                float4 rampCol = tex2D(_globalRamp, float2(theDot, 0.5));
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // Add our little atmospheric fog...
                float4 fragColour = col * rampCol + (deferredLight * deferredLight.w);
                float interpolationValue = (1 - i.vertex.z) * _globalFogFadeFactor;
                return lerp(fragColour, _globalFogColour,smoothstep(0,1, interpolationValue));
            }
            ENDCG
        }
    }
}
