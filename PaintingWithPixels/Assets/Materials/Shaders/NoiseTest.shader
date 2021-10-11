// https://www.clicktorelease.com/blog/vertex-displacement-noise-3d-webgl-glsl-three-js/
Shader "Toon/NoiseTest"
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
            #include "Packages/jp.keijiro.noiseshader/Shader/ClassicNoise3D.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            float turbulence( float3 p ) 
            {
                float w = 100.0;
                float t = -.5;

                for (float f = 1.0 ; f <= 10.0 ; f++ ){
                    float power = pow( 2.0, f );
                    t += abs( PeriodicNoise(float3( power * p ), float3( 10.0, 10.0, 10.0 ) ) / power);
                }

                return t;
            }

            v2f vert (appdata v)
            {
                    float speed = 0.1;
                    float intensity = 0.2;
                    float noise = 10.0 *  -.10 * turbulence( .5 * v.normal +  (_Time.y * speed) );
                    float3 newPosition = v.vertex + v.normal * (-noise * intensity);

                v2f o;
                o.vertex = UnityObjectToClipPos( newPosition );
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
