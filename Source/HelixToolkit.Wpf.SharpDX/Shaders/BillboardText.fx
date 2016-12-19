
Texture2D billboardTexture; // billboard text image
Texture2D billboardAlphaTexture;
bool   bHasAlphaTexture = false;
bool   bHasTexture = false;
//--------------------------------------------------------------------------------------
// VERTEX AND PIXEL SHADER INPUTS
//--------------------------------------------------------------------------------------
struct VSInputBT
{
	float4 p	: POSITION;
	float4 c	: COLOR;
	float4 t	: TEXCOORD0; // t.xy = texture coords, t.zw = offset in pixels.
};

struct PSInputBT
{
	float4 p	: SV_POSITION;
	float4 c	: COLOR;
	float2 t	: TEXCOORD;
};

//--------------------------------------------------------------------------------------
// GLOBAL FUNCTIONS
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// From window pixel pos to normalized device coordinates.
//--------------------------------------------------------------------------------------
float2 windowToNdc(in float2 pos)
{
    return float2((pos.x / vViewport.x) * 2.0, (pos.y / vViewport.y) * 2.0);
}

//--------------------------------------------------------------------------------------
// BILLBOARD TEXT SHADER
//--------------------------------------------------------------------------------------

PSInputBT VShaderBillboardText( VSInputBT input )
{
	PSInputBT output = (PSInputBT)0;
    float4 ndcPosition = float4( input.p.xyz, 1.0 );

	// Translate position into clip space
	ndcPosition = mul( ndcPosition, mWorld );
	ndcPosition = mul( ndcPosition, mView );
	ndcPosition = mul( ndcPosition, mProjection );
    float4 ndcTranslated = ndcPosition / ndcPosition.w;

    // Translate offset into normalized device coordinates.
    float2 offset = windowToNdc( input.t.zw );	
	output.p = float4( ndcTranslated.xy + offset, ndcTranslated.z, 1.0 );

    output.c = input.c;
    output.t = input.t.xy;
	return output;
}

float4 PShaderBillboardText( PSInputBT input ) : SV_Target
{
    // Take the color off the texture, and use its red component as alpha.
    float4 pixelColor = billboardTexture.Sample(NormalSampler, input.t);
    float4 intermediateColor = float4(1.0, 1.0, 1.0, pixelColor.x);
    return intermediateColor * input.c;
}

float4 PShaderBillboardBackground(PSInputBT input) : SV_Target
{
	return input.c;
}

float4 PShaderBillboardImage(PSInputBT input) : SV_Target
{
	// Take the color off the texture using mask color
	float4 pixelColor = 1;
	if (bHasTexture)
	{
		pixelColor *= billboardTexture.Sample(PointSampler, input.t);
	}

	if (bHasAlphaTexture) 
	{
		pixelColor *= billboardAlphaTexture.Sample(PointSampler, input.t);
	}

	if(input.c.w != 0 && length(pixelColor - input.c) < 0.00001)
	{
		return float4(0.0, 0.0, 0.0, 0.0);
	}
	else
	{
		return pixelColor;	
	}
}

//--------------------------------------------------------------------------------------
// Techniques
//-------------------------------------------------------------------------------------

technique11 RenderBillboard
{
    pass P0
    {	        
		//SetDepthStencilState( DSSDepthLess, 0 );
		SetDepthStencilState( DSSDepthLessEqual, 0 );
        SetRasterizerState	( RSSolid );
        SetBlendState		( BSBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        SetVertexShader		( CompileShader( vs_4_0, VShaderBillboardText() ) );
		SetHullShader		( NULL );
        SetDomainShader		( NULL );        
        SetGeometryShader	( NULL );
        SetPixelShader		( CompileShader( ps_4_0, PShaderBillboardText() ) );
    }    
	pass P1
	{
		//SetDepthStencilState( DSSDepthLess, 0 );
		SetDepthStencilState(DSSDepthLessEqual, 0);
		SetRasterizerState(RSSolid);
		SetBlendState(BSBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetVertexShader(CompileShader(vs_4_0, VShaderBillboardText()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, PShaderBillboardBackground()));
	}
	pass P2
	{
		//SetDepthStencilState( DSSDepthLess, 0 );
		SetDepthStencilState(DSSDepthLessEqual, 0);
		SetRasterizerState(RSSolid);
		SetBlendState(BSBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetVertexShader(CompileShader(vs_4_0, VShaderBillboardText()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, PShaderBillboardImage()));
	}
}
