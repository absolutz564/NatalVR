// Gelo do lago congelado, leve para o Quest (sem depth/opaque texture).
// - Profundidade: rachaduras em camadas a profundidades diferentes (paralaxe pelo ângulo de visão)
//   e fundo mais escuro longe da margem.
// - Refração: camada de fundo distorcida por ruído e reflexo do probe ondulado.
// - Contato: brilho ciano onde o gelo encosta em margem, pedras e blocos
//   (textura de distância gerada no editor: LakeContactDistance).
Shader "Natal/FrozenIce"
{
    Properties
    {
        [Header(Cor)]
        _DeepColor ("Cor funda", Color) = (0.01, 0.16, 0.30, 1)
        _MidColor ("Cor media", Color) = (0.03, 0.42, 0.55, 1)
        _ShallowColor ("Cor rasa (perto da margem)", Color) = (0.25, 0.95, 0.90, 1)
        _RimColor ("Cor de borda (fresnel)", Color) = (0.75, 0.95, 1.0, 1)
        _FresnelPower ("Fresnel", Range(0.5, 8)) = 3

        [Header(Contato e profundidade)]
        [NoScaleOffset] _ContactMask ("Distancia ate contato (R)", 2D) = "white" {}
        _MaskRect ("Area da mascara (minX, minZ, tamX, tamZ)", Vector) = (0, 0, 1, 1)
        _MaskMaxDistance ("Distancia maxima da mascara (m)", Float) = 12
        _IceHeight ("Altura do gelo (m)", Float) = 0
        _ContactColor ("Cor do contato", Color) = (0.45, 1.0, 1.0, 1)
        _ContactWidth ("Largura do brilho de contato (m)", Range(0.05, 4)) = 0.9
        _ContactIntensity ("Intensidade do contato", Range(0, 6)) = 2.2
        _ShallowWidth ("Largura da faixa rasa (m)", Range(0.5, 12)) = 4.5
        _DepthMeters ("Profundidade aparente (m)", Range(0.1, 6)) = 1.6
        _ContactWobble ("Ondulacao da borda de contato (m)", Range(0, 2)) = 0.5
        _Transparency ("Transparencia (ver o fundo)", Range(0, 1)) = 0.55

        [Header(Rachaduras)]
        _CrackColor ("Cor das rachaduras", Color) = (0.55, 1.0, 1.0, 1)
        _CrackIntensity ("Intensidade (superficie)", Range(0, 6)) = 1.6
        _CrackDeepIntensity ("Intensidade (camada funda)", Range(0, 3)) = 0.6
        _CrackScale ("Escala grande", Range(0.01, 2)) = 0.11
        _CrackScaleSmall ("Escala pequena", Range(0.05, 4)) = 0.4
        _CrackWidth ("Espessura", Range(0.005, 0.2)) = 0.03
        _CrackPulse ("Pulso", Range(0, 2)) = 0.35

        [Header(Refracao e reflexo)]
        _Refraction ("Distorcao da refracao", Range(0, 2)) = 0.6
        _ReflectionStrength ("Reflexo do ambiente", Range(0, 1.5)) = 0.7
        _ReflectionWobble ("Ondulacao do reflexo", Range(0, 0.3)) = 0.06
        _MoonDirection ("Direcao da lua (xyz)", Vector) = (0, 0.35, 1, 0)
        _MoonSpecColor ("Brilho da lua", Color) = (0.85, 0.92, 1.0, 1)
        _MoonSpecPower ("Nitidez do brilho", Range(8, 1024)) = 220
        _MoonSpecIntensity ("Intensidade do brilho", Range(0, 6)) = 2.5
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    CBUFFER_START(UnityPerMaterial)
        half4 _DeepColor, _MidColor, _ShallowColor, _RimColor;
        half _FresnelPower;
        float4 _MaskRect;
        float _MaskMaxDistance, _IceHeight;
        half4 _ContactColor;
        half _ContactWidth, _ContactIntensity, _ShallowWidth, _DepthMeters, _ContactWobble, _Transparency;
        half4 _CrackColor;
        half _CrackIntensity, _CrackDeepIntensity, _CrackScale, _CrackScaleSmall, _CrackWidth, _CrackPulse;
        half _Refraction, _ReflectionStrength, _ReflectionWobble;
        float4 _MoonDirection;
        half4 _MoonSpecColor;
        half _MoonSpecPower, _MoonSpecIntensity;
    CBUFFER_END
    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent-50" }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

            TEXTURE2D(_ContactMask); SAMPLER(sampler_ContactMask);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                half fog : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                VertexPositionInputs p = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = p.positionCS;
                o.positionWS = p.positionWS;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.fog = ComputeFogFactor(p.positionCS.z);
                return o;
            }

            float2 hash22(float2 p)
            {
                float3 a = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
                a += dot(a, a.yzx + 33.33);
                return frac((a.xx + a.yz) * a.zy);
            }

            float noise2(float2 p)
            {
                float2 i = floor(p), f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = hash22(i).x, b = hash22(i + float2(1, 0)).x;
                float c = hash22(i + float2(0, 1)).x, d = hash22(i + float2(1, 1)).x;
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            // distância até a borda da célula de Voronoi (F2 - F1)
            float voronoiEdge(float2 p)
            {
                float2 cell = floor(p);
                float2 f = frac(p);
                float f1 = 8.0, f2 = 8.0;
                [unroll] for (int y = -1; y <= 1; y++)
                [unroll] for (int x = -1; x <= 1; x++)
                {
                    float2 g = float2(x, y);
                    float2 r = g + hash22(cell + g) - f;
                    float d = dot(r, r);
                    if (d < f1) { f2 = f1; f1 = d; }
                    else if (d < f2) { f2 = d; }
                }
                return sqrt(f2) - sqrt(f1);
            }

            float contactDistance(float2 xz)
            {
                float2 uv = (xz - _MaskRect.xy) / _MaskRect.zw;
                return SAMPLE_TEXTURE2D(_ContactMask, sampler_ContactMask, uv).r * _MaskMaxDistance;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float3 n = normalize(i.normalWS);
                float3 v = normalize(GetWorldSpaceViewDir(i.positionWS));
                half ndv = saturate(dot(n, v));
                half fresnel = pow(1.0 - ndv, _FresnelPower);
                float2 xz = i.positionWS.xz;

                // paralaxe: deslocamento por metro de profundidade, conforme o ângulo de visão
                float2 parallax = -v.xz / max(v.y, 0.25);

                // distância até margem/pedras -> profundidade (raso perto do contato, fundo no meio)
                // ruído na posição para a borda de contato não seguir os cantos retos do modelo
                float2 wob = float2(noise2(xz * 0.45), noise2(xz * 0.45 + 13.7)) - 0.5;
                float dist = contactDistance(xz + wob * _ContactWobble * 2.0);
                half shallow = 1.0 - saturate(dist / _ShallowWidth);
                half depth01 = saturate(dist / (_ShallowWidth * 2.2));

                // ---- camada de fundo (refração): sobe/desce com a paralaxe e é distorcida por ruído
                float2 refr = float2(noise2(xz * 0.35 + _Time.y * 0.05), noise2(xz * 0.35 + 7.3 - _Time.y * 0.04)) - 0.5;
                float2 bottomXZ = xz + parallax * _DepthMeters + refr * _Refraction;
                float bottomDist = contactDistance(bottomXZ);
                half bottomDepth = saturate(bottomDist / (_ShallowWidth * 2.2));
                half3 col = lerp(_ShallowColor.rgb, _MidColor.rgb, saturate(bottomDepth * 1.6));
                col = lerp(col, _DeepColor.rgb, saturate(bottomDepth * 1.4 - 0.4));
                // manchas suaves no fundo (variação de espessura do gelo)
                col *= 0.8 + 0.4 * noise2(bottomXZ * 0.18);

                // ---- rachaduras fundas (meia profundidade, mais largas e fracas)
                float2 warp = float2(sin(xz.y * 0.9), cos(xz.x * 0.8)) * 0.6;
                float2 midXZ = xz + parallax * (_DepthMeters * 0.45) + refr * (_Refraction * 0.4);
                float deep = voronoiEdge((midXZ - warp * 0.3) * (_CrackScale * 1.7) + 3.1);
                half crackDeep = 1.0 - smoothstep(0.0, _CrackWidth * 2.2, deep);
                col += _CrackColor.rgb * crackDeep * _CrackDeepIntensity * (0.4 + 0.6 * depth01);

                // ---- reflexo do ambiente com ondulação (dá a sensação de superfície refratada)
                float3 nWobble = normalize(n + float3(refr.x, 0, refr.y) * _ReflectionWobble * 4.0);
                float3 r = reflect(-v, nWobble);
                half4 env = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, r, 1);
                half3 refl = DecodeHDREnvironment(env, unity_SpecCube0_HDR);
                col = lerp(col, col + refl * _ReflectionStrength, 0.35 + fresnel * 0.65);
                col = lerp(col, _RimColor.rgb, fresnel * 0.45);

                // ---- rachaduras da superfície (finas e brilhantes)
                float big = voronoiEdge((xz + warp) * _CrackScale);
                float small = voronoiEdge((xz - warp * 0.5) * _CrackScaleSmall);
                half crack = saturate((1.0 - smoothstep(0.0, _CrackWidth, big)) + (1.0 - smoothstep(0.0, _CrackWidth * 0.6, small)) * 0.35);
                half pulse = 1.0 + _CrackPulse * sin(_Time.y * 1.3 + xz.x * 0.15 + xz.y * 0.1);
                col += _CrackColor.rgb * crack * _CrackIntensity * pulse;

                // ---- contato: brilho ciano onde encosta em margem, pedras e blocos
                half contact = exp(-dist / max(_ContactWidth, 0.01));
                half contactWave = 0.85 + 0.15 * sin(dist * 6.0 - _Time.y * 1.5);
                col += _ContactColor.rgb * contact * contactWave * _ContactIntensity;
                col = lerp(col, _ShallowColor.rgb * 1.2, shallow * 0.25);

                // ---- brilho da lua
                float3 moonDir = normalize(_MoonDirection.xyz);
                half spec = pow(saturate(dot(r, moonDir)), _MoonSpecPower);
                col += _MoonSpecColor.rgb * spec * _MoonSpecIntensity;

                // transparência: dá para ver o leito e os modelos submersos;
                // fica opaco nas rachaduras, no contato e quando visto de lado (fresnel)
                half alpha = lerp(1.0 - _Transparency, 1.0, fresnel);
                alpha = max(alpha, saturate(crack * 0.9 + contact * 0.85 + spec));

                col = MixFog(col, i.fog);
                return half4(col, alpha);
            }
            ENDHLSL
        }

        // Para o bake: o lago contribui com luz ciano suave
        Pass
        {
            Name "Meta"
            Tags { "LightMode" = "Meta" }
            Cull Off
            HLSLPROGRAM
            #pragma vertex vertMeta
            #pragma fragment fragMeta
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            struct A { float4 positionOS : POSITION; float2 uv0 : TEXCOORD0; float2 uv1 : TEXCOORD1; float2 uv2 : TEXCOORD2; };
            struct V { float4 positionCS : SV_POSITION; };

            V vertMeta (A a)
            {
                V o;
                o.positionCS = UnityMetaVertexPosition(a.positionOS.xyz, a.uv1, a.uv2);
                return o;
            }

            half4 fragMeta (V i) : SV_Target
            {
                MetaInput m = (MetaInput)0;
                m.Albedo = _MidColor.rgb;
                m.Emission = _ContactColor.rgb * 0.3;
                return UnityMetaFragment(m);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
