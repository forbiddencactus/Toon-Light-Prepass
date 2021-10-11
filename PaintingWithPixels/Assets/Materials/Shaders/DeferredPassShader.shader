// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// A little minimalist shader that will render our deferred buffers. 

Shader "Toon/DeferredPassShader"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Blend Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct VertexToFragment
            {
                // Clip space position of the fragment.
                float4 fragPosition: SV_POSITION;

                // World space normal for the fragment.
                float3 fragNormal: TEXCOORD0;
            };

            // Output for our pixel (fragment) shader
            struct PixelOutput
            {
                float4 normalMap: SV_Target0;
                float depthMap: SV_DEPTH;
            };

            VertexToFragment vert (float4 vertex : POSITION, float3 normal : NORMAL) 
            {
                VertexToFragment toFragmentData;

                // Transform the vertex from object space to clip space (this is using matrices internally!)
                toFragmentData.fragPosition = UnityObjectToClipPos(vertex);

                // Transform the vertex normal from object space to world space (this is using matrices internally!)
                toFragmentData.fragNormal = UnityObjectToWorldNormal(normal);

                // Off to the pixel shader!
                return toFragmentData;
            }

            PixelOutput frag (VertexToFragment vertData)
            {
                // Declare our output struct...
                PixelOutput pixelOut;

                // Write depth to depthMap pixel...
                pixelOut.depthMap = vertData.fragPosition.z;

                // Write normal to normalMap pixel., also transform from [-1 to 1] to [0 to 1]
                // Note that our render target texture supports negative pixel values! But it's good to know to do it both ways, plus our normal map looks prettier this way. :D
                pixelOut.normalMap.xyz = vertData.fragNormal * 0.5 + 0.5; 

                // Get rid of the warnings (and avoid writing garbage to our lovely buffers!)
                pixelOut.normalMap.w = 1;

                // Off to our textures it goes. 
                return pixelOut;
            }
            ENDCG
        }
    }
}
