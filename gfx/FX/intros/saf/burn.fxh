Code
[[


]]

PixelShader = 
{
	Code
	[[

		//==============================================================
		// Burn-from-center effect (HLSL, SM5/DX11)
		// - Expands a circular "burn" over time with jagged edge + rim glow
		// - Use in a full-screen pass or any material with UVs
		//==============================================================

		//-------------------------
		// helpers
		//-------------------------
		float smoothstep01(float e0, float e1, float x)
		{
			float t = saturate((x - e0) / max(1e-6, (e1 - e0)));
			return t * t * (3.0 - 2.0 * t);
		}

		// Hash -> value noise (cheap, tile-safe enough for SFX)
		float2 hash22(float2 p)
		{
			// Large primes-ish
			float3 p3 = frac(float3(p.x, p.y, p.x) * float3(0.1031, 0.11369, 0.13787));
			p3 += dot(p3, p3.yzx + 19.19);
			return frac((p3.xx + p3.yz) * p3.zy);
		}

		float noise2D(float2 p)
		{
			float2 i = floor(p);
			float2 f = frac(p);

			// Quintic curve for smooth interpolation
			float2 u = f * f * f * (f * (f * 6 - 15) + 10);

			float2 a = hash22(i + float2(0,0));
			float2 b = hash22(i + float2(1,0));
			float2 c = hash22(i + float2(0,1));
			float2 d = hash22(i + float2(1,1));

			float va = dot(a, f - float2(0,0));
			float vb = dot(b, f - float2(1,0));
			float vc = dot(c, f - float2(0,1));
			float vd = dot(d, f - float2(1,1));

			float v1 = lerp(va, vb, u.x);
			float v2 = lerp(vc, vd, u.x);
			float v  = lerp(v1, v2, u.y);     // ~[-1,1]
			return v;
		}

		// 3-octave fBm, returns ~[-1,1]
		float fbm(float2 p)
		{
			float a = 0.0;
			float w = 0.5;
			float2 pp = p;

			[unroll] for (int i = 0; i < 3; ++i)
			{
				a += w * noise2D(pp);
				pp = pp * 2.02;
				w *= 0.5;
			}
			// re-range from roughly [-0.75,0.75] to [-1,1]
			return saturate((a + 0.9) / 1.8) * 2.0 - 1.0;
		}

		//-------------------------
		// main burn function
		//-------------------------
		float4 ApplyBurn(float2 uv,
                 in sampler2D BaseTex,
                 float2 BurnCenter, float Aspect, float cTime,
                 float Radius0, float Speed, float JagAmp, float Freq, float Flow,
                 float EdgeWidth, float RimWidth, float RimSigma, float HeatAmp,
                 float3 EmberColor, float EmberBoost)
		{
			// aspect-corrected radial distance from center
			float2 p = uv - BurnCenter;
			p.x *= Aspect;
			float d = length(p);

			// expanding radius
			float r = Radius0 + Speed * cTime;

			// edge jaggedness (flowing noise)
			float n  = fbm(p * Freq + Flow * cTime);
			float dJ = d - JagAmp * n;

			// AA-aware edge width
			float fw = max(EdgeWidth, 2.0 * length(float2(ddx(dJ), ddy(dJ))));

			// 1=inside burned area, 0=outside; soft falloff
			float burnMask = 1.0 - smoothstep01(r - fw, r + fw, dJ);

			// --- Rim glow (orangey) ---
			// Gaussian ring centered on the front:
			float rim = exp(-pow((dJ - r) / max(1e-5, RimSigma), 2.0));
			float flicker = 0.5 + 0.5 * sin(10.0 * cTime + 8.0 * n);

			// Sample base and convert to B&W so only the rim supplies color
			float3 baseRGB = tex2D(BaseTex, uv).rgb;
			float  grey    = dot(baseRGB, float3(0.299, 0.587, 0.114));
			float3 baseBW  = grey.xxx;

			// Char the interior (darker BW)
			float3 charred = lerp(float3(0.07, 0.06, 0.05), baseBW * 0.25, 0.6);

			// Composite: outside stays BW base, inside chars
			float3 color = lerp(baseBW, charred, burnMask);

			// Orangey glow on the rim (additive)
			float3 ember = EmberColor * rim * flicker * EmberBoost;
			color += ember;

			// Optional heat shimmer at the rim
			if (HeatAmp > 0.0)
			{
				float2 dir = (d > 1e-6) ? (p / d) : float2(0, 0);
				float2 distort  = dir * HeatAmp * rim * (0.5 + 0.5 * n);
				float2 sampleUV = uv + float2(distort.x / max(1e-6, Aspect), distort.y);
				float3 shimmer  = tex2D(BaseTex, sampleUV).rgb; // <- use sampleUV
				float  shGrey   = dot(shimmer, float3(0.299, 0.587, 0.114));
				color = lerp(color, shGrey.xxx, 0.25 * rim);
			}

			// --- A) Make burnt areas disappear ---
			// Visibility is the inverse of the burn mask
			// (soft edges thanks to the same AA width).
			float visibility = 1.0 - burnMask;

			// If you want the glow to be visible even as it cuts out, you can keep alpha as `visibility`.
			// Engines often multiply color by alpha at blend time, so the glow fades naturally at the edge.
			return float4(color, visibility);
		}
		
		float4 ApplyBurnColour(float2 uv,
                 float4 colour,
                 float2 BurnCenter, float Aspect, float cTime,
                 float Radius0, float Speed, float JagAmp, float Freq, float Flow,
                 float EdgeWidth, float RimWidth, float RimSigma, float HeatAmp,
                 float3 EmberColor, float EmberBoost)
		{
			// aspect-corrected radial distance from center
			float2 p = uv - BurnCenter;
			p.x *= Aspect;
			float d = length(p);

			// expanding radius
			float r = Radius0 + Speed * cTime;

			// edge jaggedness (flowing noise)
			float n  = fbm(p * Freq + Flow * cTime);
			float dJ = d - JagAmp * n;

			// AA-aware edge width
			float fw = max(EdgeWidth, 2.0 * length(float2(ddx(dJ), ddy(dJ))));

			// 1=inside burned area, 0=outside; soft falloff
			float burnMask = 1.0 - smoothstep01(r - fw, r + fw, dJ);

			// Rim glow
			float rim = exp(-pow((dJ - r) / max(1e-5, RimSigma), 2.0));
			float flicker = 0.5 + 0.5 * sin(10.0 * cTime + 8.0 * n);

			// Sample base color *and alpha*
			float4 baseSample = colour;
			float3 baseRGB = baseSample.rgb;
			float  baseAlpha = baseSample.a; // preserve source transparency

			// Convert to greyscale (for your BW look)
			float grey = dot(baseRGB, float3(0.299, 0.587, 0.114));
			float3 baseBW = grey.xxx;

			// Charred darker interior
			float3 charred = lerp(float3(0.07, 0.06, 0.05), baseBW * 0.25, 0.6);

			// Mix unburnt and burnt
			float3 color = lerp(baseBW, charred, burnMask);

			// Add orangey rim glow
			float3 ember = EmberColor * rim * flicker * EmberBoost;
			color += ember;

			// Optional heat shimmer
			if (HeatAmp > 0.0)
			{
				float2 dir = (d > 1e-6) ? (p / d) : float2(0, 0);
				float2 distort = dir * HeatAmp * rim * (0.5 + 0.5 * n);
				float2 sampleUV = uv + float2(distort.x / max(1e-6, Aspect), distort.y);
				float4 shimmer = colour;
				float shGrey = dot(shimmer.rgb, float3(0.299, 0.587, 0.114));
				color = lerp(color, shGrey.xxx, 0.25 * rim);
			}

			// Preserve original alpha but fade with burn
			float finalAlpha = baseAlpha * (1.0 - burnMask);

			return float4(color, finalAlpha);
		}
		//-------------------------
		// rotation function
		//-------------------------
		float2 RotateUV(float2 uv, float2 pivot, float angle)
		{
			// Translate so pivot is origin
			float2 p = uv - pivot;

			// Rotation matrix (cos/sin)
			float s = sin(angle);
			float c = cos(angle);

			float2 rotated;
			rotated.x = c * p.x - s * p.y;
			rotated.y = s * p.x + c * p.y;

			// Translate back
			return rotated + pivot;
		}

	]]

}

