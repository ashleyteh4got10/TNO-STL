Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
	"/intros/saf/burn.fxh"
}

PixelShader =
{
	Samplers =
	{
		MapTexture =
		{
			Index = 0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
			MipMapLodBias = -0.8
		}
		MaskTexture =
		{
			Index = 1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture =
		{
			Index = 2
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		MaskTexture2 =
		{
			Index = 3
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture2 =
		{
			Index = 4
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		#This masking texture is the ACTUAL masking texture. The others are for animation
		MaskingTexture =
		{
			Index = 5
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}




	}
}


VertexStruct VS_OUTPUT
{
	float4  vPosition : PDX_POSITION;
	float2  vTexCoord : TEXCOORD0;
@ifdef ANIMATED
	float4  vAnimatedTexCoord : TEXCOORD1;
@endif
@ifdef MASKING
	float2  vMaskingTexCoord : TEXCOORD2;
@endif
};


VertexShader =
{
	MainCode VertexShader
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
		    VS_OUTPUT Out;
		    Out.vPosition  = mul( WorldViewProjectionMatrix, float4( v.vPosition.xyz, 1 ) );
		
		    Out.vTexCoord = v.vTexCoord;
		
		    return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderUp
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float value = floor(Offset.x)+ 1.f;
			if(value == 2)
			{
				return float4(0,0,0,0);
			}
			
			float vTime = Time - AnimationTime;
			if(vTime < 2.f){
				OutColor = float4(0,0,0,1);
				OutColor.a = vTime*0.5f;
			}
			else if(vTime > 110.5f && vTime < 120.5f)
			{
				float4 colour = float4(0,0,0,1);
				float2 BurnCenter = float2(0.f, 1.f);
				float Aspect = 1.0f;
				float cTime = vTime - 110.5f;
				float Radius0 = 0.0f;
				float Speed = 0.133f;
				float JagAmp = 0.01f;
				float Freq = 4.f;
				float Flow = 0.8f;
				float EdgeWidth = 0.01f;
				float RimWidth = 0.001f;
				float RimSigma = 0.005f;
				float HeatAmp = 0.003f;
				float3 EmberColor = float3(0.8, 0.6, 0.4);
				float EmberBoost = 0.05f;
				
				float4 burn = ApplyBurnColour(v.vTexCoord, colour, BurnCenter, Aspect, cTime, Radius0, Speed, JagAmp, Freq, Flow, EdgeWidth, RimWidth, RimSigma, HeatAmp, EmberColor, EmberBoost);
				return burn;
			}
			else if(vTime > 120.5f)
			{
				return float4(0,0,0,0);
			}
			return OutColor;
		}
	]]

	MainCode PixelShaderDown
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
					
		#ifdef ANIMATED
			OutColor = Animate(OutColor, v.vTexCoord, v.vAnimatedTexCoord, MaskTexture, AnimatedTexture, MaskTexture2, AnimatedTexture2);
		#endif

		#ifdef MASKING
			float4 MaskColor = tex2D( MaskingTexture, v.vTexCoord );
			OutColor.a *= MaskColor.a;
		#endif
			
			OutColor *= Color;

			float vTime = 0.9 - saturate( (Time - AnimationTime) * 16 );
			vTime *= vTime;
			vTime = 0.9*0.9 - vTime;
		    float4 MixColor = float4( 0.15, 0.15, 0.15, 0 ) * vTime;
		    OutColor.rgb -= ( 0.5 + OutColor.rgb ) * MixColor.rgb;

			return OutColor;
		}
	]]

	MainCode PixelShaderDisable
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float value = floor(Offset.x)+ 1.f;
			if(value == 2)
			{
				return float4(0,0,0,0);
			}
			
			float vTime = Time - AnimationTime;
			if(vTime < 2.f){
				OutColor = float4(0,0,0,1);
				OutColor.a = vTime*0.5f;
			}
			else if(vTime > 110.5f && vTime < 120.5f)
			{
				float4 colour = float4(0,0,0,1);
				float2 BurnCenter = float2(1.f, 1.f);
				float Aspect = 1.0f;
				float cTime = vTime - 110.5f;
				float Radius0 = 0.0f;
				float Speed = 0.133f;
				float JagAmp = 0.01f;
				float Freq = 4.f;
				float Flow = 0.8f;
				float EdgeWidth = 0.01f;
				float RimWidth = 0.001f;
				float RimSigma = 0.005f;
				float HeatAmp = 0.003f;
				float3 EmberColor = float3(0.8, 0.6, 0.4);
				float EmberBoost = 0.05f;
				
				float4 burn = ApplyBurnColour(v.vTexCoord, colour, BurnCenter, Aspect, cTime, Radius0, Speed, JagAmp, Freq, Flow, EdgeWidth, RimWidth, RimSigma, HeatAmp, EmberColor, EmberBoost);
				return burn;
			}
			else if(vTime > 120.5f)
			{
				return float4(0,0,0,0);
			}
			return OutColor;
		}	
	]]

	MainCode PixelShaderOver
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
				
		#ifdef ANIMATED
			OutColor = Animate(OutColor, v.vTexCoord, v.vAnimatedTexCoord, MaskTexture, AnimatedTexture, MaskTexture2, AnimatedTexture2);
		#endif

		#ifdef MASKING
			float4 MaskColor = tex2D( MaskingTexture, v.vTexCoord );
			OutColor.a *= MaskColor.a;
		#endif

			OutColor *= Color;
			
			float vTime = 0.9 - saturate( (Time - AnimationTime) * 4 );
			vTime *= vTime;
			vTime = 0.9*0.9 - vTime;
		    float4 MixColor = float4( 0.15, 0.15, 0.15, 0 ) * vTime;
		    OutColor.rgb += ( 0.5 + OutColor.rgb ) * MixColor.rgb;
			
			return OutColor;
		}
	]]
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
}


Effect Up
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderUp"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDown"
}

Effect Disable
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDisable"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderOver"
}

