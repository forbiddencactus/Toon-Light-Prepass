// A little shader to highlight in the editor the area of illumination of our fake deferred lights. 

Shader "Toon/EditorLight"
{
    Properties
    {
        _LightColour ("Light Colour", Color) = (1,1,1,1)
        _LightDistance ("Light Distance", Float) = 0
        _LightOrigin ("Light Origin", Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _LightColour;

            float4 vert (float4 vertex : POSITION) : SV_POSITION
            {
                return UnityObjectToClipPos(vertex);
            }

            fixed4 frag () : SV_Target
            {
                return _LightColour;
            }
            ENDCG
        }
    }
}
