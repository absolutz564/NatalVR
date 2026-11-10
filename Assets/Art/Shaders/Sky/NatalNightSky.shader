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

        [Header(Lua)]
        _MoonColor ("Cor da lua", Color) = (0.86, 0.93, 1.0, 1)
        _MoonIntensity ("Brilho da lua", Range(0, 4)) = 1.6
        _MoonRadius ("Raio da lua (rad)", Range(0.01, 0.3)) = 0.085
        _MoonSoftness ("Suavidade da borda", Range(0.001, 0.2)) = 0.02
        _MoonCraters ("Crateras e manchas", Range(0, 1)) = 0.35
        [NoScaleOffset] _MoonTex ("Textura da lua", 2D) = "white" {}
        _MoonTexBlend ("Usar textura (0 = procedural)", Range(0, 1)) = 1
        _MoonTexIntensity ("Brilho da textura", Range(0, 4)) = 1.2
        _MoonTexLod ("Nitidez (mip, 0 = maxima)", Range(0, 4)) = 1.5
        _MoonGlowWide ("Halo largo (rad)", Range(0.02, 1)) = 0.28
        _MoonGlowWideIntensity ("Intensidade do halo largo", Range(0, 3)) = 0.55

        [Header(Estrelas cadentes)]
        _ShootColor ("Cor", Color) = (0.9, 0.95, 1.0, 1)
        _ShootIntensity ("Intensidade", Range(0, 6)) = 2.5
        _ShootInterval ("Intervalo medio (s)", Range(1, 30)) = 7
        _ShootDuration ("Duracao (s)", Range(0.2, 3)) = 0.9
        _ShootLength ("Comprimento do rastro (rad)", Range(0.02, 0.6)) = 0.22
        _ShootWidth ("Espessura (rad)", Range(0.0005, 0.01)) = 0.0018
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
            half4 _MoonColor;
            half _MoonIntensity, _MoonRadius, _MoonSoftness, _MoonCraters, _MoonGlowWide, _MoonGlowWideIntensity;
            sampler2D _MoonTex;
            half _MoonTexBlend, _MoonTexIntensity, _MoonTexLod;
            half4 _ShootColor;
            half _ShootIntensity, _ShootInterval, _ShootDuration, _ShootLength, _ShootWidth;

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

            float vnoise(float2 p)
            {
                float2 i = floor(p), f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = hash13(float3(i, 1.3)), b = hash13(float3(i + float2(1, 0), 1.3));
                float c = hash13(float3(i + float2(0, 1), 1.3)), d = hash13(float3(i + float2(1, 1), 1.3));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            // Disco da lua: retorna cor (rgb) e cobertura (a)
            half4 moonDisc(float3 d, float3 md)
            {
                float cz = dot(d, md);
                if (cz <= 0.0) return 0;
                float3 right = normalize(cross(float3(0, 1, 0), md));
                float3 up = cross(md, right);
                float2 p = float2(dot(d, right), dot(d, up)) / cz / tan(_MoonRadius);
                float r = length(p);
                half cover = 1.0 - smoothstep(1.0 - _MoonSoftness * 10.0, 1.0, r);
                if (cover <= 0.0) return 0;
                // escurecimento na borda (esfera)
                half limb = 0.72 + 0.28 * sqrt(saturate(1.0 - r * r));
                // manchas (mares) e crateras
                float maria = vnoise(p * 2.2 + 3.7) * 0.6 + vnoise(p * 4.5 + 1.1) * 0.4;
                maria = smoothstep(0.45, 0.8, maria);
                float2 cp = p * 5.0;
                float2 cell = floor(cp);
                float crater = 0.0;
                [unroll] for (int y = -1; y <= 1; y++)
                [unroll] for (int x = -1; x <= 1; x++)
                {
                    float2 g = cell + float2(x, y);
                    float h = hash13(float3(g, 7.1));
                    if (h > 0.55) continue;
                    float2 c = g + float2(hash13(float3(g, 2.2)), hash13(float3(g, 5.5)));
                    float rad = 0.15 + 0.25 * hash13(float3(g, 9.9));
                    float dd = length(cp - c) / rad;
                    crater += (1.0 - smoothstep(0.7, 1.0, dd)) * 0.6 - (smoothstep(0.85, 1.0, dd) * (1.0 - smoothstep(1.0, 1.15, dd))) * 0.4;
                }
                half shade = limb * (1.0 - _MoonCraters * (maria * 0.45 + saturate(crater) * 0.35));
                half3 proc = _MoonColor.rgb * shade * _MoonIntensity;
                half3 texCol = tex2Dlod(_MoonTex, float4(p * 0.5 + 0.5, 0, _MoonTexLod)).rgb * _MoonTexIntensity;
                return half4(lerp(proc, texCol, _MoonTexBlend), cover);
            }

            // Uma estrela cadente por "canal": a cada intervalo aparece num ponto aleatório do céu
            // e risca um arco curto descendo.
            half shootingStar(float3 d, float channel)
            {
                float period = _ShootInterval * (0.8 + channel * 0.55);
                float t = _Time.y + channel * 13.7;
                float idx = floor(t / period);
                float local = t - idx * period;
                if (local > _ShootDuration) return 0;
                float prog = local / _ShootDuration;

                float h1 = hash13(float3(idx, channel, 1.7));
                float h2 = hash13(float3(idx, channel, 4.3));
                float h3 = hash13(float3(idx, channel, 8.9));
                float az = h1 * 6.2831;
                float el = 0.45 + h2 * 0.6;
                float3 start = normalize(float3(cos(az) * cos(el), sin(el), sin(az) * cos(el)));
                // direção do movimento: tangente descendo, com inclinação aleatória
                float3 east = normalize(cross(float3(0, 1, 0), start) + 1e-4);
                float3 down = normalize(cross(start, east));
                float tilt = (h3 - 0.5) * 1.4;
                float3 dir = normalize(down * -0.8 + east * tilt);

                float travel = _ShootLength * 2.2;
                float3 head = normalize(start + dir * travel * prog);
                float3 tail = normalize(start + dir * travel * max(prog - 0.35, 0.0));
                // distância angular de d ao segmento tail-head (no plano tangente da cabeça)
                float3 ax = normalize(head - tail + 1e-5);
                float3 rel = d - tail;
                float along = dot(rel, ax);
                float segLen = length(head - tail);
                float3 closest = tail + ax * clamp(along, 0.0, segLen);
                float dist = length(d - closest);
                if (dot(d, head) < 0.5) return 0;
                half core = exp(-dist / _ShootWidth);
                half fadeTail = saturate(along / max(segLen, 1e-4));
                half life = sin(prog * 3.14159);
                return core * fadeTail * fadeTail * life;
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

                float3 md = normalize(_MoonDirection.xyz);
                half4 moon = moonDisc(d, md);
                half starFade = saturate(d.y * 5.0) * (1.0 - moon.a);
                sky += stars(d) * starFade;
                sky = lerp(sky, moon.rgb, moon.a);
                // halo largo em volta da lua
                float ang = acos(saturate(dot(d, md)));
                sky += _MoonGlowColor.rgb * exp(-max(ang - _MoonRadius, 0.0) / _MoonGlowWide) * _MoonGlowWideIntensity * (1.0 - moon.a);
                sky += aurora(d);
                half shoot = shootingStar(d, 0.0) + shootingStar(d, 1.0);
                sky += _ShootColor.rgb * shoot * _ShootIntensity * starFade;

                half moonDot = saturate(dot(d, md));
                sky += _MoonGlowColor.rgb * pow(moonDot, _MoonGlowSize) * _MoonGlowIntensity * (1.0 - moon.a);

                return half4(sky, 1);
            }
            ENDCG
        }
    }
    Fallback Off
}
