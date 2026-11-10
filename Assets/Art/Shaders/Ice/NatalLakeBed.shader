// Leito do lago (visto através do gelo): degradê por profundidade e cáusticas animadas. Unlit, leve.
Shader "Natal/LakeBed"
{
    Properties
    {
        _ShallowColor ("Cor rasa", Color) = (0.10, 0.45, 0.55, 1)
        _DeepColor ("Cor funda", Color) = (0.01, 0.07, 0.16, 1)
        _IceHeight ("Altura do gelo (m)", Float) = 0
        _MaxDepth ("Profundidade maxima (m)", Float) = 2.5
        _CausticColor ("Cor das causticas", Color) = (0.35, 0.95, 1.0, 1)
        _CausticIntensity ("Intensidade das causticas", Range(0, 2)) = 0.35
        _CausticScale ("Escala das causticas", Range(0.05, 2)) = 0.45
        _CausticSpeed ("Velocidade das causticas", Range(0, 2)) = 0.25
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _ShallowColor, _DeepColor, _CausticColor;
                float _IceHeight, _MaxDepth;
                half _CausticIntensity, _CausticScale, _CausticSpeed;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct Varyings { float4 positionCS : SV_POSITION; float3 positionWS : TEXCOORD0; half fog : TEXCOORD1; float3 normalWS : TEXCOORD2; UNITY_VERTEX_OUTPUT_STEREO };

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                VertexPositionInputs p = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = p.positionCS;
                o.positionWS = p.positionWS;
                o.fog = ComputeFogFactor(p.positionCS.z);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

            float2 hash22(float2 p)
            {
                float3 a = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
                a += dot(a, a.yzx + 33.33);
                return frac((a.xx + a.yz) * a.zy);
            }

            // cáustica barata: borda de Voronoi animada
            float caustic(float2 p, float t)
            {
                float2 cell = floor(p), f = frac(p);
                float f1 = 8.0, f2 = 8.0;
                [unroll] for (int y = -1; y <= 1; y++)
                [unroll] for (int x = -1; x <= 1; x++)
                {
                    float2 g = float2(x, y);
                    float2 o = hash22(cell + g);
                    o = 0.5 + 0.4 * sin(t + 6.2831 * o);
                    float2 r = g + o - f;
                    float d = dot(r, r);
                    if (d < f1) { f2 = f1; f1 = d; } else if (d < f2) { f2 = d; }
                }
                return 1.0 - smoothstep(0.0, 0.18, sqrt(f2) - sqrt(f1));
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half depth = saturate((_IceHeight - i.positionWS.y) / _MaxDepth);
                half3 col = lerp(_ShallowColor.rgb, _DeepColor.rgb, depth);
                // sombreamento simples: luz vem de cima, através do gelo
                half up = saturate(normalize(i.normalWS).y);
                col *= 0.45 + 0.75 * up;
                float t = _Time.y * _CausticSpeed;
                half c = caustic(i.positionWS.xz * _CausticScale, t) * caustic(i.positionWS.xz * _CausticScale * 1.7 + 4.1, -t * 1.3);
                col += _CausticColor.rgb * c * _CausticIntensity * (1.0 - depth * 0.7) * up;
                col = MixFog(col, i.fog);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
