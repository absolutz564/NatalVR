// Lit do URP com acabamento estilizado de neve/rocha à noite:
// luz suave vinda do lado de quem olha (as faces das rochas não ficam pretas),
// degradê de altura, borda refletindo o céu (fresnel) e brilho da lua sobre a neve.
// Reaproveita o forward pass e as demais passes do URP Lit (sombra, profundidade, meta para o bake).
Shader "Natal/SnowLit"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0
        _Metallic("Metallic", Range(0.0, 1.0)) = 0
        [HDR] _EmissionColor("Emission", Color) = (0,0,0)

        [Header(Luz frontal suave)]
        _FillColor ("Cor", Color) = (0.45, 0.58, 1.0, 1)
        _FillIntensity ("Intensidade", Range(0, 2)) = 0.45
        _FillWrap ("Suavidade (0 = so de frente)", Range(0, 1)) = 0.35
        _FillDir ("Direcao fixa da luz (xyz)", Vector) = (-0.45, 0.55, -0.7, 0)
        _FillDirMix ("Mistura: olhar (0) / direcao fixa (1)", Range(0, 1)) = 0.6
        _RockColor ("Luz nas rochas (nao neve)", Color) = (0.16, 0.22, 0.5, 1)
        _RockContrast ("Contraste entre faces", Range(1, 4)) = 2

        [Header(Degrade de altura)]
        _LowTint ("Cor embaixo", Color) = (0.55, 0.62, 0.95, 1)
        _GradMinY ("Altura de baixo (m)", Float) = -2
        _GradMaxY ("Altura de cima (m)", Float) = 45

        [Header(Borda e reflexo do ceu)]
        _RimColor ("Cor da borda", Color) = (0.55, 0.7, 1.0, 1)
        _RimIntensity ("Intensidade da borda", Range(0, 3)) = 0.6
        _RimPower ("Fineza da borda", Range(0.5, 8)) = 3
        _SkyReflect ("Reflexo do ceu (probe)", Range(0, 3)) = 0.8

        [Header(Brilho da lua na neve)]
        _SnowLumMin ("Neve: luminancia minima", Range(0, 1)) = 0.55
        _SnowLumMax ("Neve: luminancia cheia", Range(0, 1)) = 0.8
        _SheenDir ("Direcao da lua (xyz)", Vector) = (0, 0.41, 0.91, 0)
        _SheenColor ("Cor do brilho", Color) = (0.75, 0.85, 1.0, 1)
        _SheenIntensity ("Intensidade do brilho", Range(0, 3)) = 0.7
        _SheenPower ("Fineza do brilho", Range(1, 128)) = 12
        _SnowLift ("Clareia a neve", Range(0, 1)) = 0.25

        [Header(Relevo da neve por textura)]
        [NoScaleOffset] _ReliefTex ("Textura de relevo (RG normal, A altura)", 2D) = "bump" {}
        _ReliefScale ("Tamanho das dunas (m)", Float) = 36
        _ReliefRippleScale ("Tamanho das ondulacoes (m)", Float) = 7
        _ReliefRippleMix ("Peso das ondulacoes", Range(0, 1)) = 0.45
        _ReliefStrength ("Forca do relevo", Range(0, 3)) = 1.2
        _ReliefShade ("Sombreamento pela lua", Range(0, 3)) = 1.1
        _ReliefCavity ("Escurece os vales", Range(0, 1)) = 0.3
        _ReliefMinUp ("So em superficies para cima (min N.y)", Range(0, 1)) = 0.75

        // usados pelas passes do URP Lit
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        [HideInInspector] _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _BumpScale("Scale", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex LitPassVertex
            #pragma fragment NatalFragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #define REQUIRES_WORLD_SPACE_POS_INTERPOLATOR
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

            // fora do UnityPerMaterial (só um material usa este shader)
            half4 _FillColor, _LowTint, _RimColor, _SheenColor;
            half _FillIntensity, _FillWrap, _GradMinY, _GradMaxY, _RimIntensity, _RimPower, _SkyReflect;
            half _SnowLumMin, _SnowLumMax, _SheenIntensity, _SheenPower, _SnowLift;
            float4 _SheenDir, _FillDir;
            half _FillDirMix, _RockContrast;
            half4 _RockColor;
            TEXTURE2D(_ReliefTex); SAMPLER(sampler_ReliefTex);
            float _ReliefScale, _ReliefRippleScale;
            half _ReliefRippleMix, _ReliefStrength, _ReliefShade, _ReliefCavity, _ReliefMinUp;

            half4 NatalFragment(Varyings input) : SV_Target0
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, surfaceData);
            #ifdef LOD_FADE_CROSSFADE
                LODFadeCrossFade(input.positionCS);
            #endif
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);
                InitializeBakedGIData(input, inputData);

                half3 albedo = surfaceData.albedo;
                half lum = dot(albedo, half3(0.3, 0.59, 0.11));
                half snow = smoothstep(_SnowLumMin, _SnowLumMax, lum);
                // folhagem (verde) não recebe a luz azul das rochas
                half green = saturate((albedo.g - max(albedo.r, albedo.b)) * 10.0);

                // relevo: dunas + ondulações de vento em espaço de mundo (XZ), só na neve voltada para cima
                half3 N0 = inputData.normalWS;
                half reliefMask = snow * smoothstep(_ReliefMinUp, 1.0, N0.y);
                half relH = 1;
                {
                    float2 wp = inputData.positionWS.xz;
                    half4 r1 = SAMPLE_TEXTURE2D(_ReliefTex, sampler_ReliefTex, wp / _ReliefScale);
                    // segunda escala girada para não repetir em grade
                    float2 wr = float2(wp.x * 0.8 - wp.y * 0.6, wp.x * 0.6 + wp.y * 0.8);
                    half4 r2 = SAMPLE_TEXTURE2D(_ReliefTex, sampler_ReliefTex, wr / _ReliefRippleScale + 0.37);
                    half2 n1 = r1.rg * 2 - 1;
                    half2 n2 = r2.rg * 2 - 1;
                    n2 = half2(n2.x * 0.8 + n2.y * 0.6, -n2.x * 0.6 + n2.y * 0.8); // desfaz a rotação
                    half2 slope = (n1 + n2 * _ReliefRippleMix) * _ReliefStrength * reliefMask;
                    inputData.normalWS = normalize(N0 + half3(slope.x, 0, slope.y));
                    relH = lerp(1, lerp(r1.a, r2.a, _ReliefRippleMix * 0.5), reliefMask);
                }

                half4 color = UniversalFragmentPBR(inputData, surfaceData);

                half3 N = inputData.normalWS;
                // sombreamento do relevo pela direção da lua (funciona mesmo com lightmap)
                {
                    half3 Lm = normalize(_SheenDir.xyz);
                    half shade = 1.0 + (dot(N, Lm) - dot(N0, Lm)) * _ReliefShade;
                    shade *= lerp(1.0 - _ReliefCavity, 1.0, relH);
                    color.rgb *= max(shade, 0.2);
                }
                half3 V = inputData.viewDirectionWS;
                half NdV = saturate(dot(N, V));
                half h = saturate((inputData.positionWS.y - _GradMinY) / max(_GradMaxY - _GradMinY, 0.01));
                half3 grad = lerp(_LowTint.rgb, half3(1, 1, 1), h);

                // luz suave do lado de quem olha: rochas ganham volume em vez de ficarem chapadas
                half fillView = saturate(NdV * (1.0 - _FillWrap) + _FillWrap);
                half fd = saturate(dot(N, normalize(_FillDir.xyz)) * 0.5 + 0.5);
                half fill = lerp(fillView, fd * fd, _FillDirMix);
                half3 fillCol = lerp(_FillColor.rgb, half3(0.85, 0.95, 0.9), green);
                color.rgb += albedo * fillCol * _FillIntensity * fill * grad * (1.0 + green);
                // rocha escura: luz própria azulada (sem multiplicar pelo albedo) para mostrar as faces
                color.rgb += _RockColor.rgb * pow(fd, _RockContrast) * grad * (1.0 - snow) * (1.0 - green);

                // neve um pouco mais clara (como na referência)
                color.rgb += albedo * snow * _SnowLift * saturate(N.y * 0.7 + 0.3);

                // borda: céu refletido nos ângulos rasantes
                half fres = pow(1.0 - NdV, _RimPower);
                half3 env = GlossyEnvironmentReflection(reflect(-V, N), inputData.positionWS, 0.45, 1.0, inputData.normalizedScreenSpaceUV);
                // chão plano não recebe borda (senão o campo de neve inteiro fica estourado)
                half vertical = 1.0 - saturate(N.y) * 0.85;
                color.rgb += (_RimColor.rgb * _RimIntensity + env * _SkyReflect) * fres * vertical * (0.4 + 0.6 * snow);

                // brilho da lua sobre a neve
                half3 L = normalize(_SheenDir.xyz);
                half3 H = normalize(L + V);
                half sheen = pow(saturate(dot(N, H)), _SheenPower);
                color.rgb += _SheenColor.rgb * sheen * snow * _SheenIntensity;

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                color.a = 1;
                return color;
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/SHADOWCASTER"
        UsePass "Universal Render Pipeline/Lit/DEPTHONLY"
        UsePass "Universal Render Pipeline/Lit/DEPTHNORMALS"
        UsePass "Universal Render Pipeline/Lit/META"
    }
    Fallback "Universal Render Pipeline/Lit"
}
