Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
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
			float vTime = Time - AnimationTime;
			
			float value = floor(Offset.x)+ 1.f;
			if(value == 2)
			{
				return float4(0,0,0,0);
			}
			
			float fTime = vTime - 26.f;
			float2 newTexCoord = v.vTexCoord;
			float2 imgTexCoord = v.vTexCoord;
			float4 OutColor = tex2D( MapTexture, newTexCoord );
			if(vTime > 34.f)
			{
				return float4(0,0,0,0);
			}
			if(vTime < 26)
			{
				return float4(0,0,0,0);
			}
			if(fTime < 0.25f)
			{
				newTexCoord.x -= 0.5f;
				newTexCoord.x /= sin(fTime * 6.f);
				newTexCoord.x += 0.5f;
				if(v.vTexCoord.y < 0.835)
				{
					return float4(0,0,0,0);
				}
				OutColor = tex2D( MapTexture, newTexCoord );
				return OutColor;
			}
			else if(fTime >= 0.25 && fTime < 1)
			{
				imgTexCoord.y -= (0.89316 * sin((0.75f - (fTime - 0.25f)))*2.f);
			}
			OutColor = tex2D( MapTexture, newTexCoord );
			if(newTexCoord.y < 0.837)
			{
				OutColor = float4(0,0,0,0);
			}
			float4 imgColour = tex2D( MapTexture, imgTexCoord );
			if(imgTexCoord.y >= 0.835 || v.vTexCoord.y >= 0.89316)
			{
				imgColour = float4(0,0,0,0);
			}
			if(fTime >= 0.25 && fTime < 1)
			{
				float4 finalColour = float4(0,0,0,0);
				finalColour.a = 1.f - (1.f - OutColor.a) * (1.f - imgColour.a);
				finalColour.r = (imgColour.r * imgColour.a / finalColour.a) + (OutColor.r * OutColor.a * (1 - imgColour.a) / finalColour.a);
				finalColour.g = (imgColour.g * imgColour.a / finalColour.a) + (OutColor.g * OutColor.a * (1 - imgColour.a) / finalColour.a);
				finalColour.b = (imgColour.b * imgColour.a / finalColour.a) + (OutColor.b * OutColor.a * (1 - imgColour.a) / finalColour.a);
				return finalColour;
			}
			float4 normal = tex2D( MapTexture, v.vTexCoord );
			return normal;
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
			float vTime = Time - AnimationTime;

			float value = floor(Offset.x)+ 1.f;
			if(value == 2)
			{
				return float4(0,0,0,0);
			}

			float fTime = vTime - 26.5f;
			float2 newTexCoord = v.vTexCoord;
			float2 imgTexCoord = v.vTexCoord;
			float4 OutColor = tex2D( MapTexture, newTexCoord );
			if(vTime > 34.f)
			{
				return float4(0,0,0,0);
			}
			if(vTime < 26.5f)
			{
				return float4(0,0,0,0);
			}
			else if(fTime < 0.25f)
			{
				newTexCoord.x -= 0.5f;
				newTexCoord.x /= sin(fTime * 6.f);
				newTexCoord.x += 0.5f;
				if(v.vTexCoord.y < 0.801)
				{
					return float4(0,0,0,0);
				}
				OutColor = tex2D( MapTexture, newTexCoord );
				return OutColor;
			}
			else if(fTime >= 0.25 && fTime < 1.f)
			{
				imgTexCoord.y -= (0.858 * sin((0.75f - (fTime - 0.25f)))*2.f);
			}
			OutColor = tex2D( MapTexture, newTexCoord );
			if(newTexCoord.y < 0.801)
			{
				OutColor = float4(0,0,0,0);
			}
			float4 imgColour = tex2D( MapTexture, imgTexCoord );
			if(imgTexCoord.y >= 0.801 || v.vTexCoord.y >= 0.858)
			{
				imgColour = float4(0,0,0,0);
			}
			if(fTime >= 0.25f && fTime < 1.f)
			{
				float4 finalColour = float4(0,0,0,0);
				finalColour.a = 1.f - (1.f - OutColor.a) * (1.f - imgColour.a);
				finalColour.r = (imgColour.r * imgColour.a / finalColour.a) + (OutColor.r * OutColor.a * (1 - imgColour.a) / finalColour.a);
				finalColour.g = (imgColour.g * imgColour.a / finalColour.a) + (OutColor.g * OutColor.a * (1 - imgColour.a) / finalColour.a);
				finalColour.b = (imgColour.b * imgColour.a / finalColour.a) + (OutColor.b * OutColor.a * (1 - imgColour.a) / finalColour.a);
				return finalColour;
			}
			float4 normal = tex2D( MapTexture, v.vTexCoord );
			return normal;
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

