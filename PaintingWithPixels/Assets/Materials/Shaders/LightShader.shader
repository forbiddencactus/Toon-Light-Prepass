// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// A little minimalist shader that will render to our depth buffer. 

Shader "Toon/LightShader"
{
    Properties
    {
        _LightColour ("Light Colour", Color) = (1,1,1,1)
        _LightDistance ("Light Distance", Float) = 0
        _LightOrigin ("Light Origin", Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Cull front faces instead of backfaces. This is a standard trick in deferred pipelines that avoids light volumes from clipping when you're inside them. 
        Cull Front

        // We also don't want any Z testing. 
        ZTest Always

        // But we want blending so out light volumes can intersect nicely. 
        Blend SrcAlpha One//MinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Packages/jp.keijiro.noiseshader/Shader/ClassicNoise3D.hlsl"

            float4 _LightColour;
            float _LightDistance;
            float4 _LightOrigin;
            uniform sampler2D _depthTexture;
            uniform sampler2D _normalTexture;
            uniform sampler2D _posTexture;
            uniform float4x4 _inverseViewProjMatrix;

            struct VertexToFragment
            {
                // Clip space position of the fragment.
                float4 fragPosition: SV_POSITION;

                // Screen UV for the fragment.
                float4 fragScreenUV: TEXCOORD0;

                // Front face frag, for depth testing. 
                float4 fragFrontFacePosition: TEXCOORD1;
            };

            float4 WorldPosFromDepth(float2 uv) 
            {
                float depth = tex2D(_depthTexture, uv);
                float4 clipSpace = float4( (uv.x) * 2 - 1, (uv.y) * 2 - 1, depth, 1.0f );
                float4 D = mul( _inverseViewProjMatrix, clipSpace );

                return D / D.w;
            }

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

            VertexToFragment vert (float4 vertex : POSITION, float3 normal: NORMAL) 
            {
                float speed = 0.5;
                float intensity = 0.2;
                float noise = 10.0 *  -.10 * turbulence( .5 * normal +  (_Time.y * speed) );
                float3 vertNoise = vertex - normal * ( (noise * intensity) );
                                
                //Smooth out the effect a bit. 
                float4 smoothPos = lerp(vertex, float4(vertNoise,1.0), 0.3);
                
                VertexToFragment toFrag;
                // Transform object space vertex to clip space...
                toFrag.fragPosition = UnityObjectToClipPos(smoothPos);

                // Transform clip space vertex to screenspace, so we can sample from our normal and depth buffers. 
                toFrag.fragScreenUV = ComputeScreenPos(toFrag.fragPosition);

                toFrag.fragFrontFacePosition = UnityObjectToClipPos(-vertex);

                return toFrag;
            }

            fixed4 frag (VertexToFragment vertData) : SV_Target
            {
                // Sample the depth from our depth buffer. 
                float depth = tex2D(_depthTexture, vertData.fragScreenUV.xy / vertData.fragScreenUV.w);

                // Sample our normal buffer. 
                float3 normal = tex2D(_normalTexture, vertData.fragScreenUV.xy / vertData.fragScreenUV.w).xyz * 2 - 1;

                // Compute the world space position of this fragment from the depth buffer. 
                float4 fragWorldPos = WorldPosFromDepth(vertData.fragScreenUV.xy / vertData.fragScreenUV.w);

                // Get the distance between our light and the fragment. 
                float intersectionDistance = distance(_LightOrigin,fragWorldPos);

                // Get the light normal based on our world fragment. 
                float3 lightNormal = normalize(fragWorldPos - _LightOrigin);
        
                // Check to see if the fragment we just transformed from the depth buffer sits inside the light volume. 
                if(intersectionDistance < _LightDistance && (depth < vertData.fragFrontFacePosition.z))
                {
                    // Check to see that our fragment isn't facing away from the light source. 
                    if ( dot(normal, lightNormal) < 0 ) // Aesthetically I think it sometimes looks nicer when fragments that are facing away are lit by the light volume, and sometimes not. Such a dilemma.  
                    {
                        return _LightColour;
                    }
                }
                else
                {
                    // Don't bother rendering this fragment. 
                    discard;
                }

                return 0;
                
            }
            ENDCG
        }
    }
}
