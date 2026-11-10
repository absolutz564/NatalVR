// Céu noturno estilizado para Quest: degradê, estrelas procedurais e aurora animada.
// Tudo calculado por pixel com poucas instruções (sem texturas), compatível com multiview.
Shader "Natal/NightSky"
{
    Properties
    {
        [Header(Degrade)]
        _TopColor ("Topo", Color) = (0.05, 0.04, 0.20, 1)
        _MidColor ("Meio", Color) = (0.16, 0.14, 0.45, 1)
        _HorizonColor ("Horizonte", Color) = (0.35, 0.42, 0.85, 1)
        _BottomColor ("Abaixo do horizonte", Color) = (0.12, 0.14, 0.35, 1)
        _HorizonSharpness ("Nitidez do horizonte", Range(0.5, 8)) = 2.5

        [Header(Estrelas)]
        _StarDensity ("Densidade", Range(20, 400)) = 160
        _StarAmount ("Quantidade", Range(0, 1)) = 0.12
        _StarSize ("Tamanho", Range(0.05, 0.5)) = 0.22
        _StarBrightness ("Brilho", Range(0, 4)) = 1.6
        _TwinkleSpeed ("Velocidade do pisca", Range(0, 5)) = 1.5

        [Header(Aurora)]
        _AuroraColorA ("Cor da borda (baixo)", Color) = (0.10, 1.00, 0.62, 1)
        _AuroraColorB ("Cor do topo", Color) = (0.50, 0.22, 1.00, 1)
        _AuroraIntensity ("Intensidade", Range(0, 3)) = 1.3
        _AuroraInner ("Inicio ao lado da lua (rad)", Range(0, 1.5)) = 0.42
        _AuroraOuter ("Fim no horizonte (rad)", Range(0.5, 3)) = 1.75
        _AuroraTopElev ("Altura perto da lua (0-1)", Range(0, 1)) = 0.78
        _AuroraLowElev ("Altura no fim (0-1)", Range(-0.2, 0.6)) = 0.02
        _AuroraCurtain ("Altura da cortina", Range(0.02, 0.6)) = 0.22
        _AuroraRays ("Frequencia dos raios", Range(5, 120)) = 38
        _AuroraSpeed ("Velocidade", Range(0, 2)) = 0.12

        [Header(Aurora 2 roxa)]
        _Aurora2ColorA ("Cor da borda (baixo)", Color) = (0.75, 0.30, 1.00, 1)
        _Aurora2ColorB ("Cor do topo", Color) = (0.30, 0.15, 0.85, 1)
        _Aurora2Intensity ("Intensidade", Range(0, 3)) = 0.8
        _Aurora2ElevOffset ("Deslocamento de altura", Range(-0.4, 0.4)) = 0.12
        _Aurora2AzOffset ("Deslocamento lateral (rad)", Range(-1, 1)) = 0.25
        _Aurora2Curtain ("Altura da cortina", Range(0.02, 0.6)) = 0.22
        _Aurora2Rays ("Frequencia dos raios", Range(5, 120)) = 15
        _Aurora2Speed ("Velocidade", Range(0, 2)) = 0.07
        _Aurora2Wave ("Amplitude da ondulacao", Range(0, 0.2)) = 0.06

        [Header(Brilho da lua)]
        _MoonDirection ("Direcao da lua (xyz)", Vector) = (0, 0.35, 1, 0)
        _MoonGlowColor ("Cor do halo", Color) = (0.55, 0.65, 1.0, 1)
        _MoonGlowSize ("Tamanho do halo", Range(1, 200)) = 18
        _MoonGlowIntensity ("Intensidade do halo", Range(0, 3)) = 0.8
    }

    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            half4 _TopColor, _MidColor, _HorizonColor, _BottomColor;
            half _HorizonSharpness;
            half _StarDensity, _StarAmount, _StarSize, _StarBrightness, _TwinkleSpeed;
            half4 _AuroraColorA, _AuroraColorB;
            half _AuroraIntensity, _AuroraInner, _AuroraOuter, _AuroraTopElev, _AuroraLowElev, _AuroraCurtain, _AuroraRays, _AuroraSpeed;
            half4 _Aurora2ColorA, _Aurora2ColorB;
            half _Aurora2Intensity, _Aurora2ElevOffset, _Aurora2AzOffset, _Aurora2Curtain, _Aurora2Rays, _Aurora2Speed, _Aurora2Wave;
            float4 _MoonDirection;
            half4 _MoonGlowColor;
            half _MoonGlowSize, _MoonGlowIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 dir : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.dir = v.vertex.xyz;
                return o;
            }

            float hash13(float3 p)
            {
                p = frac(p * 0.1031);
                p += dot(p, p.zyx + 31.32);
                return frac((p.x + p.y) * p.z);
            }

            half3 stars(float3 d)
            {
                float3 cell = floor(d * _StarDensity);
                float3 local = frac(d * _StarDensity) - 0.5;
                float h = hash13(cell);
                if (h > _StarAmount) return 0;
                // posição do ponto dentro da célula
                float3 jitter = float3(hash13(cell + 1.7), hash13(cell + 4.3), hash13(cell + 9.1)) - 0.5;
                float dist = length(local - jitter * 0.6);
                float star = saturate(1.0 - dist / _StarSize);
                star *= star;
                float twinkle = 0.65 + 0.35 * sin(_Time.y * _TwinkleSpeed * (1.0 + h * 8.0) + h * 40.0);
                half3 tint = lerp(half3(0.75, 0.85, 1.0), half3(1.0, 0.95, 0.85), hash13(cell + 2.9));
                return tint * star * twinkle * _StarBrightness;
            }

            // Cortinas de aurora, uma de cada lado da lua: começam altas perto da lua
            // e descem até o horizonte. Borda de baixo brilhante, raios verticais subindo para a cor do topo.
            half3 auroraLayer(float3 d, half inner, half outer, half topE, half lowE, half curtain, half raysF,
                              half speed, half wave, half phase, half3 colA, half3 colB)
            {
                if (d.y <= -0.02) return 0;
                float3 m = normalize(float3(_MoonDirection.x, 0, _MoonDirection.z) + float3(0, 0, 1e-4));
                float3 h = normalize(float3(d.x, 0, d.z) + float3(0, 0, 1e-4));
                float az = atan2(m.z * h.x - m.x * h.z, dot(m, h));
                float aa = abs(az);
                float side = az >= 0 ? 1.0 : -1.0;
                float t01 = (aa - inner) / max(outer - inner, 0.01);
                if (t01 < -0.1 || t01 > 1.15) return 0;
                float time = _Time.y * speed + phase;

                float e = asin(saturate(d.y)) / 1.5708;
                float tc = saturate(t01);
                float baseE = lerp(topE, lowE, tc * (2.0 - tc) * 0.55 + tc * 0.45);
                baseE += wave * (sin(aa * 6.0 + time * 3.0 + side * 1.7 + phase) + 0.45 * sin(aa * 15.0 - time * 5.0 + phase * 2.0));

                float above = e - baseE;
                half edge = smoothstep(-0.018, 0.004, above);
                half fadeUp = exp(-max(above, 0.0) / curtain);
                float rx = aa * raysF + side * 3.1 + phase * 5.0;
                half rays = saturate(0.45 + 0.35 * sin(rx + time * 2.0) + 0.2 * sin(rx * 2.7 - time * 3.3 + sin(rx * 0.3)));
                half rim = exp(-abs(above) / 0.012) * 0.9;
                half ends = smoothstep(-0.1, 0.12, t01) * (1.0 - smoothstep(0.82, 1.15, t01));
                half k = saturate(above / (curtain * 1.4));
                half3 col = lerp(colA, colB, k);
                return col * (edge * fadeUp * rays + rim) * ends;
            }

            half3 aurora(float3 d)
            {
                half3 green = auroraLayer(d, _AuroraInner, _AuroraOuter, _AuroraTopElev, _AuroraLowElev, _AuroraCurtain,
                                          _AuroraRays, _AuroraSpeed, 0.035, 0.0, _AuroraColorA.rgb, _AuroraColorB.rgb) * _AuroraIntensity;
                half3 purple = auroraLayer(d, _AuroraInner + _Aurora2AzOffset, _AuroraOuter + _Aurora2AzOffset,
                                           _AuroraTopElev + _Aurora2ElevOffset, _AuroraLowElev + _Aurora2ElevOffset, _Aurora2Curtain,
                                           _Aurora2Rays, _Aurora2Speed, _Aurora2Wave, 2.7, _Aurora2ColorA.rgb, _Aurora2ColorB.rgb) * _Aurora2Intensity;
                return green + purple;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float3 d = normalize(i.dir);

                half up = saturate(d.y);
                half3 sky = lerp(_HorizonColor.rgb, _MidColor.rgb, saturate(pow(up, 1.0 / _HorizonSharpness) * 1.4));
                sky = lerp(sky, _TopColor.rgb, saturate((up - 0.35) * 1.6));
                half below = saturate(-d.y * 6.0);
                sky = lerp(sky, _BottomColor.rgb, below);

                half starFade = saturate(d.y * 5.0);
                sky += stars(d) * starFade;
                sky += aurora(d);

                float3 moonDir = normalize(_MoonDirection.xyz);
                half moon = saturate(dot(d, moonDir));
                sky += _MoonGlowColor.rgb * pow(moon, _MoonGlowSize) * _MoonGlowIntensity;

                return half4(sky, 1);
            }
            ENDCG
        }
    }
    Fallback Off
}
