// Halo de luz (billboard aditivo) para simular bloom sem pós-processamento.
// Cada halo são 4 vértices no mesmo ponto; o vertex shader abre o quad virado para a câmera.
Shader "Natal/GlowHalo"
{
    Properties
    {
        _Intensity ("Intensidade", Range(0, 4)) = 1
        _CoreSize ("Tamanho do nucleo", Range(0, 0.5)) = 0.12
        _NearFade ("Some perto da camera (m)", Range(0, 5)) = 1.5
        _PushToCamera ("Puxa para a camera (x raio)", Range(0, 2)) = 1
        _Twinkle ("Pisca (0 = fixo)", Range(0, 1)) = 0
        _TwinkleSpeed ("Velocidade do pisca", Range(0, 10)) = 2.5
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent+10" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

        Pass
        {
            Name "Halo"
            Tags { "LightMode" = "UniversalForward" }
            Blend One One
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half _Intensity, _CoreSize, _NearFade, _PushToCamera, _Twinkle, _TwinkleSpeed;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;   // centro do halo
                float2 corner : TEXCOORD0;       // -1..1
                float2 sizePhase : TEXCOORD1;    // x = raio em metros, y = fase do pisca
                half4 color : COLOR;             // rgb = cor, a = ligado/desligado
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 corner : TEXCOORD0;
                half4 color : COLOR;
                half fog : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 centerWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 centerVS = TransformWorldToView(centerWS);
                // puxa o halo para a frente, para não ficar escondido dentro da casa/poste
                float size = v.sizePhase.x;
                float push = min(size * _PushToCamera, max(-centerVS.z - 0.5, 0));
                float3 posVS = centerVS + float3(v.corner * size, push);
                o.positionCS = TransformWViewToHClip(posVS);
                o.corner = v.corner;

                float dist = length(centerVS);
                half near = saturate((dist - _NearFade * 0.5) / max(_NearFade, 0.001));
                half tw = 1.0 - _Twinkle * (0.5 + 0.5 * sin(_Time.y * _TwinkleSpeed * (0.6 + frac(v.sizePhase.y * 7.31)) + v.sizePhase.y * 6.2831));
                o.color = half4(v.color.rgb * v.color.a * near * _Intensity * tw, 1);
                o.fog = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half d = length(i.corner);
                half glow = saturate(1.0 - d);
                glow = glow * glow * glow;
                half core = saturate(1.0 - d / max(_CoreSize, 0.001));
                half3 col = i.color.rgb * (glow * 0.8 + core * core * 1.5);
                // aditivo: neblina leva para preto, não para a cor da neblina
                col = MixFogColor(col, half3(0, 0, 0), i.fog);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
