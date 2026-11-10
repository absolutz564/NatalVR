// Lâmpadas do pisca-pisca modeladas na mesh dos pinheiros.
// Cor vem da cor de vértice; UV.x guarda a fase do pisca de cada lâmpada.
// Brilho só um pouco acima do limiar do bloom para ficar suave.
Shader "Natal/Bulb"
{
    Properties
    {
        _Intensity ("Intensidade", Range(0, 6)) = 1.6
        _Twinkle ("Pisca (0 = fixo)", Range(0, 1)) = 0.5
        _TwinkleSpeed ("Velocidade do pisca", Range(0, 10)) = 2
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Bulb"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half _Intensity, _Twinkle, _TwinkleSpeed;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 color : COLOR;
                half fog : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                float ph = v.uv.x;
                half tw = 1.0 - _Twinkle * (0.5 + 0.5 * sin(_Time.y * _TwinkleSpeed * (0.6 + frac(ph * 7.31)) + ph * 6.2831));
                o.color = v.color.rgb * _Intensity * tw;
                o.fog = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half3 col = MixFog(i.color, i.fog);
                return half4(col, 1);
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Unlit/DEPTHONLY"
    }
    Fallback Off
}
