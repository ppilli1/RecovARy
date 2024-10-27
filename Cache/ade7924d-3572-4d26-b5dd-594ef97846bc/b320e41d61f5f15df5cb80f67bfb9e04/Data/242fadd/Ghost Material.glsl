#version 310 es

//-----------------------------------------------------------------------
// Copyright (c) 2019 Snap Inc.
//-----------------------------------------------------------------------

// NGS_SHADER_FLAGS_BEGIN__
// NGS_SHADER_FLAGS_END__

#pragma paste_to_backend_at_the_top_begin
#if 0
NGS_BACKEND_SHADER_FLAGS_BEGIN__
NGS_BACKEND_SHADER_FLAGS_END__
#endif 
#pragma paste_to_backend_at_the_top_end


#define NODEFLEX 0 // Hack for now to know if a shader is running in Studio or on a released lens

//-----------------------------------------------------------------------

#define NF_PRECISION highp

//-----------------------------------------------------------------------

// 10-09-2019 - These defines were moved to PBR node but Some old graphs 
//              still have them in their material definition and some compilers
//              don't like them being redefined. Easiest fix for now is to undefine them.

#ifdef ENABLE_LIGHTING
#undef ENABLE_LIGHTING
#endif

#ifdef ENABLE_DIFFUSE_LIGHTING
#undef ENABLE_DIFFUSE_LIGHTING
#endif

#ifdef ENABLE_SPECULAR_LIGHTING
#undef ENABLE_SPECULAR_LIGHTING
#endif

#ifdef ENABLE_TONE_MAPPING
#undef ENABLE_TONE_MAPPING
#endif

//-----------------------------------------------------------------------

#define ENABLE_LIGHTING false
#define ENABLE_DIFFUSE_LIGHTING false
#define ENABLE_SPECULAR_LIGHTING false


//-----------------------------------------------------------------------



//-----------------------------------------------------------------------


//-----------------------------------------------------------------------
// Standard defines
//-----------------------------------------------------------------------


#pragma paste_to_backend_at_the_top_begin



#pragma paste_to_backend_at_the_top_end


//-----------------------------------------------------------------------
// Standard includes
//-----------------------------------------------------------------------

#include <std2.glsl>
#include <std2_vs.glsl>
#include <std2_texture.glsl>
#include <std2_fs.glsl>
#include <std2_ssao.glsl>
#include <std2_taa.glsl>

#if defined(SC_ENABLE_RT_CASTER) 
#include <std2_proxy.glsl>
#endif





//-------------------
// Global defines
//-------------------

#define SCENARIUM

#ifdef SC_BACKEND_LANGUAGE_MOBILE
#define MOBILE
#endif

#ifdef SC_BACKEND_LANGUAGE_GL
const bool DEVICE_IS_FAST = SC_DEVICE_CLASS >= SC_DEVICE_CLASS_C && bool(SC_GL_FRAGMENT_PRECISION_HIGH);
#else
const bool DEVICE_IS_FAST = SC_DEVICE_CLASS >= SC_DEVICE_CLASS_C;
#endif

const bool SC_ENABLE_SRGB_EMULATION_IN_SHADER = false;


//-----------------------------------------------------------------------
// Varyings
//-----------------------------------------------------------------------

varying vec4 varColor;

//-----------------------------------------------------------------------
// User includes
//-----------------------------------------------------------------------
#include "includes/utils.glsl"		


#include "includes/blend_modes.glsl"
#include "includes/oit.glsl" 

#include "includes/rgbhsl.glsl"
#include "includes/uniforms.glsl"

//-----------------------------------------------------------------------

// The next 60 or so lines of code are for debugging support, live tweaks, node previews, etc and will be included in a 
// shared glsl file.

//-----------------------------------------------------------------------

// Hack for now to know if a shader is running in Studio or on a released lens

#if !defined(MOBILE) && !NODEFLEX
#define STUDIO
#endif

//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
// Basic Macros
//-----------------------------------------------------------------------

// Time Overrides

uniform       int   overrideTimeEnabled;
uniform highp float overrideTimeElapsed;
uniform highp float overrideTimeDelta;

//-----------------------------------------------------------------------

#if defined( STUDIO )
#define ssConstOrUniformPrecision	uniform NF_PRECISION
#define ssConstOrUniform			uniform
#else
#define ssConstOrUniformPrecision   const
#define ssConstOrUniform    		const
#endif

//--------------------------------------------------------

// When compiling the shader for rendering in a node-based editor, we need any unconnected dynamic input port's value to
// be tweakable in real-time so we expose it to the engine as a uniform. If we're compiling the shader for a release build
// we use a literal or const value

#if defined( STUDIO )
#define NF_PORT_CONSTANT( xValue, xUniform )	xUniform
#else
#define NF_PORT_CONSTANT( xValue, xUniform )	xValue
#endif

//--------------------------------------------------------

#define float2   vec2
#define float3   vec3
#define float4   vec4
#define bool2    bvec2
#define bool3    bvec3
#define bool4    bvec4
#define float2x2 mat2
#define float3x3 mat3
#define float4x4 mat4

//--------------------------------------------------------

#define ssConditional( C, A, B ) ( ( C * 1.0 != 0.0 ) ? A : B )
#define ssEqual( A, B )          ( ( A == B ) ? 1.0 : 0.0 )
#define ssNotEqual( A, B )       ( ( A == B ) ? 0.0 : 1.0 )
#define ssLarger( A, B )         ( ( A > B ) ? 1.0 : 0.0 )
#define ssLargerOrEqual( A, B )  ( ( A >= B ) ? 1.0 : 0.0 )
#define ssSmaller( A,  B ) 		 ( ( A < B ) ? 1.0 : 0.0 )
#define ssSmallerOrEqual( A, B ) ( ( A <= B ) ? 1.0 : 0.0 )
#define ssNot( A ) 		         ( ( A * 1.0 != 0.0 ) ? 0.0 : 1.0 )

int ssIntMod( int x, int y ) { return x - y * ( x / y ); }

#define ssPRECISION_LIMITER( Value ) Value = floor( Value * 10000.0 ) * 0.0001;
#define ssPRECISION_LIMITER2( Value ) Value = floor( Value * 2000.0 + 0.5 ) * 0.0005;

#define ssDELTA_TIME_MIN 0.00

//--------------------------------------------------------

float ssSRGB_to_Linear( float value ) { return ( DEVICE_IS_FAST ) ? pow( value, 2.2 ) : value * value; }
vec2  ssSRGB_to_Linear( vec2  value ) { return ( DEVICE_IS_FAST ) ? vec2( pow( value.x, 2.2 ), pow( value.y, 2.2 ) ) : value * value; }
vec3  ssSRGB_to_Linear( vec3  value ) { return ( DEVICE_IS_FAST ) ? vec3( pow( value.x, 2.2 ), pow( value.y, 2.2 ), pow( value.z, 2.2 ) ) : value * value; }
vec4  ssSRGB_to_Linear( vec4  value ) { return ( DEVICE_IS_FAST ) ? vec4( pow( value.x, 2.2 ), pow( value.y, 2.2 ), pow( value.z, 2.2 ), pow( value.w, 2.2 ) ) : value * value; }

float ssLinear_to_SRGB( float value ) { return ( DEVICE_IS_FAST ) ? pow( value, 0.45454545 ) : sqrt( value ); }
vec2  ssLinear_to_SRGB( vec2  value ) { return ( DEVICE_IS_FAST ) ? vec2( pow( value.x, 0.45454545 ), pow( value.y, 0.45454545 ) ) : sqrt( value ); }
vec3  ssLinear_to_SRGB( vec3  value ) { return ( DEVICE_IS_FAST ) ? vec3( pow( value.x, 0.45454545 ), pow( value.y, 0.45454545 ), pow( value.z, 0.45454545 ) ) : sqrt( value ); }
vec4  ssLinear_to_SRGB( vec4  value ) { return ( DEVICE_IS_FAST ) ? vec4( pow( value.x, 0.45454545 ), pow( value.y, 0.45454545 ), pow( value.z, 0.45454545 ), pow( value.w, 0.45454545 ) ) : sqrt( value ); }

//--------------------------------------------------------

float3 ssWorldToNDC( float3 posWS, mat4 ViewProjectionMatrix )
{
	float4 ScreenVector = ViewProjectionMatrix * float4( posWS, 1.0 );
	return ScreenVector.xyz / ScreenVector.w;
}

//-------------------

float  Dummy1;
float2 Dummy2;
float3 Dummy3;
float4 Dummy4;


// When calling matrices in NGS, please use the global functions defined in the Matrix node
// This ensures their respective flags are set correctly for VFX, eg. ngsViewMatrix --> ssGetGlobal_Matrix_View()
#define ngsLocalAabbMin						sc_LocalAabbMin
#define ngsWorldAabbMin						sc_WorldAabbMin
#define ngsLocalAabbMax						sc_LocalAabbMax
#define ngsWorldAabbMax						sc_WorldAabbMax
#define ngsCameraAspect 					sc_Camera.aspect;
#define ngsCameraNear                       sc_Camera.clipPlanes.x
#define ngsCameraFar                        sc_Camera.clipPlanes.y
#define ngsCameraPosition                   sc_Camera.position
#define ngsModelMatrix                      sc_ModelMatrix							//ssGetGlobal_Matrix_World()
#define ngsModelMatrixInverse               sc_ModelMatrixInverse					//ssGetGlobal_Matrix_World_Inverse()
#define ngsModelViewMatrix                  sc_ModelViewMatrix						//ssGetGlobal_Matrix_World_View()
#define ngsModelViewMatrixInverse           sc_ModelViewMatrixInverse				//ssGetGlobal_Matrix_World_View_Inverse()
#define ngsProjectionMatrix                 sc_ProjectionMatrix						//ssGetGlobal_Matrix_World_View_Projection()
#define ngsProjectionMatrixInverse          sc_ProjectionMatrixInverse				//ssGetGlobal_Matrix_World_View_Projection_Inverse()
#define ngsModelViewProjectionMatrix        sc_ModelViewProjectionMatrix			//ssGetGlobal_Matrix_Projection()
#define ngsModelViewProjectionMatrixInverse sc_ModelViewProjectionMatrixInverse		//ssGetGlobal_Matrix_Projection_Inverse()
#define ngsViewMatrix                       sc_ViewMatrix							//ssGetGlobal_Matrix_View()
#define ngsViewMatrixInverse                sc_ViewMatrixInverse					//ssGetGlobal_Matrix_View_Inverse()
#define ngsViewProjectionMatrix             sc_ViewProjectionMatrix					//ssGetGlobal_Matrix_View_Projection()
#define ngsViewProjectionMatrixInverse      sc_ViewProjectionMatrixInverse			//ssGetGlobal_Matrix_View_Projection_Inverse()
#define ngsCameraUp 					    sc_ViewMatrixInverse[1].xyz
#define ngsCameraForward                    -sc_ViewMatrixInverse[2].xyz
#define ngsCameraRight                      sc_ViewMatrixInverse[0].xyz
#define ngsFrame 		                    0

//--------------------------------------------------------


#if defined( STUDIO )

struct ssPreviewInfo
{
	float4 Color;
	bool   Saved;
};

ssPreviewInfo PreviewInfo;

uniform NF_PRECISION int PreviewEnabled; // PreviewEnabled is set to 1 by the renderer when Lens Studio is rendering node previews
uniform NF_PRECISION int PreviewNodeID;  // PreviewNodeID is set to the node's ID that a preview is being rendered for

varying float4 PreviewVertexColor;
varying float  PreviewVertexSaved;

#define NF_DISABLE_VERTEX_CHANGES()					( PreviewEnabled == 1 )			
#define NF_SETUP_PREVIEW_VERTEX()					PreviewInfo.Color = PreviewVertexColor = float4( 0.5 ); PreviewInfo.Saved = false; PreviewVertexSaved = 0.0;
#define NF_SETUP_PREVIEW_PIXEL()					PreviewInfo.Color = PreviewVertexColor; PreviewInfo.Saved = ( PreviewVertexSaved * 1.0 != 0.0 ) ? true : false;
#define NF_PREVIEW_SAVE( xCode, xNodeID, xAlpha ) 	if ( PreviewEnabled == 1 && !PreviewInfo.Saved && xNodeID == PreviewNodeID ) { PreviewInfo.Saved = true; { PreviewInfo.Color = xCode; if ( !xAlpha ) PreviewInfo.Color.a = 1.0; } }
#define NF_PREVIEW_FORCE_SAVE( xCode ) 				if ( PreviewEnabled == 0 ) { PreviewInfo.Saved = true; { PreviewInfo.Color = xCode; } }
#define NF_PREVIEW_OUTPUT_VERTEX()					if ( PreviewInfo.Saved ) { PreviewVertexColor = float4( PreviewInfo.Color.rgb, 1.0 ); PreviewVertexSaved = 1.0; }
#define NF_PREVIEW_OUTPUT_PIXEL()					if ( PreviewEnabled == 1 ) { if ( PreviewInfo.Saved ) { FinalColor = float4( PreviewInfo.Color ); } else { FinalColor = vec4( 0.0, 0.0, 0.0, 0.0 ); /*FinalColor.a = 1.0;*/ /* this will be an option later */ }  }

#else

#define NF_DISABLE_VERTEX_CHANGES()					false			
#define NF_SETUP_PREVIEW_VERTEX()
#define NF_SETUP_PREVIEW_PIXEL()
#define NF_PREVIEW_SAVE( xCode, xNodeID, xAlpha )
#define NF_PREVIEW_FORCE_SAVE( xCode )
#define NF_PREVIEW_OUTPUT_VERTEX()
#define NF_PREVIEW_OUTPUT_PIXEL()

#endif


//--------------------------------------------------------



//--------------------------------------------------------

#ifdef VERTEX_SHADER

//--------------------------------------------------------

in vec4 color;

//--------------------------------------------------------

void ngsVertexShaderBegin( out sc_Vertex_t v )
{
	v = sc_LoadVertexAttributes();
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	sc_BlendVertex(v);
	sc_SkinVertex(v);
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( sc_RenderingSpace == SC_RENDERING_SPACE_SCREEN )
	{
		varPos         = vec3( 0.0 );
		varNormal      = v.normal;
		varTangent.xyz = v.tangent;
	}
	else if ( sc_RenderingSpace == SC_RENDERING_SPACE_SCREEN_MV )
	{
		varPos         = vec3( 0.0 );
		varNormal      = v.normal;
		varTangent.xyz = v.tangent;
	}
	else if ( sc_RenderingSpace == SC_RENDERING_SPACE_WORLD )
	{				
		varPos         = v.position.xyz;
		varNormal      = v.normal;
		varTangent.xyz = v.tangent;
	}
	else if ( sc_RenderingSpace == SC_RENDERING_SPACE_OBJECT )
	{
		varPos         = (sc_ModelMatrix * v.position).xyz;
		varNormal      = sc_NormalMatrix * v.normal;
		varTangent.xyz = sc_NormalMatrix * v.tangent;
	}
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	#if !defined(MOBILE)
	if ( PreviewEnabled == 1 )
	v.texture0.x = 1.0 - v.texture0.x; // fix to flip the preview quad UVs horizontally
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	varColor = color;
}

//--------------------------------------------------------

#ifndef SC_PROCESS_AA
#define SC_PROCESS_AA
#endif

//--------------------------------------------------------

void ngsVertexShaderEnd( inout sc_Vertex_t v, vec3 WorldPosition, vec3 WorldNormal, vec3 WorldTangent, vec4 ScreenPosition )
{
	varPos          = WorldPosition; 
	varNormal       = normalize( WorldNormal );
	varTangent.xyz  = normalize( WorldTangent );
	varTangent.w    = tangent.w;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( bool( UseViewSpaceDepthVariant ) && ( bool( sc_OITDepthGatherPass ) || bool( sc_OITCompositingPass ) || bool( sc_OITDepthBoundsPass ) ) )
	{
		varViewSpaceDepth = -sc_ObjectToView( v.position ).z;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	float4 screenPosition = float4( 0.0 );
	
	if ( sc_RenderingSpace == SC_RENDERING_SPACE_SCREEN )
	{
		screenPosition = ScreenPosition; 
	}
	else if ( sc_RenderingSpace == SC_RENDERING_SPACE_SCREEN_MV )
	{
		screenPosition = ( ngsModelViewMatrix * v.position ) * vec4( 1.0 / sc_Camera.aspect, 1.0, 1.0, 1.0 );
	}
	else if ( sc_RenderingSpace == SC_RENDERING_SPACE_WORLD )
	{
		screenPosition = ngsViewProjectionMatrix * float4( varPos.xyz, 1.0 );
	}
	else if ( sc_RenderingSpace == SC_RENDERING_SPACE_OBJECT )
	{
		screenPosition = ngsViewProjectionMatrix * float4( varPos.xyz, 1.0 );
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	varTex01 = vec4( v.texture0, v.texture1 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( bool( sc_ProjectiveShadowsReceiver ) )
	{
		varShadowTex = getProjectedTexCoords(v.position);
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	screenPosition = applyDepthAlgorithm(screenPosition); 
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	vec4 finalPosition = SC_PROCESS_AA( screenPosition );
	sc_SetClipPosition( finalPosition );
}

//--------------------------------------------------------

#endif //VERTEX_SHADER

//--------------------------------------------------------

float3 ssGetScreenPositionNDC( float4 vertexPosition, float3 positionWS, mat4 viewProjectionMatrix )
{
	float3 screenPosition = vec3( 0.0 );
	
	#ifdef VERTEX_SHADER
	
	if ( sc_RenderingSpace == SC_RENDERING_SPACE_SCREEN )
	{
		screenPosition = vertexPosition.xyz;
	}
	else
	{
		screenPosition = ssWorldToNDC( positionWS, viewProjectionMatrix );
	}
	
	#endif
	
	return screenPosition;
}

//--------------------------------------------------------

uniform NF_PRECISION float alphaTestThreshold;

#ifdef FRAGMENT_SHADER

void ngsAlphaTest( float opacity )
{
	if ( sc_BlendMode_AlphaTest )
	{
		if ( opacity < alphaTestThreshold )
		{
			discard;
		}
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( ENABLE_STIPPLE_PATTERN_TEST )
	{
		vec2  localCoord = floor(mod(sc_GetGlFragCoord().xy, vec2(4.0)));
		float threshold  = (mod(dot(localCoord, vec2(4.0, 1.0)) * 9.0, 16.0) + 1.0) / 17.0;
		
		if ( opacity < threshold )
		{
			discard;
		}
	}
}

#endif // #ifdef FRAGMENT_SHADER

#ifdef FRAGMENT_SHADER

vec4 ngsPixelShader( vec4 result ) 
{	
	if ( sc_ProjectiveShadowsCaster )
	{
		result = evaluateShadowCasterColor( result );
	}
	else if ( sc_RenderAlphaToColor )
	{
		result = vec4(result.a);
	}
	else if ( sc_BlendMode_Custom )
	{
		result = applyCustomBlend(result);
	}
	else
	{
		result = sc_ApplyBlendModeModifications(result);
	}
	
	return result;
}

#endif


//-----------------------------------------------------------------------


// Spec Consts

SPEC_CONST(bool) ENABLE_BASE_TEX = false;
SPEC_CONST(int) NODE_27_DROPLIST_ITEM = 0;
SPEC_CONST(bool) uv2EnableAnimation = false;
SPEC_CONST(int) NODE_13_DROPLIST_ITEM = 0;
SPEC_CONST(bool) Tweak_N67 = false;
SPEC_CONST(bool) uv3EnableAnimation = false;
SPEC_CONST(int) NODE_49_DROPLIST_ITEM = 0;
SPEC_CONST(bool) Tweak_N11 = false;
SPEC_CONST(bool) ENABLE_OPACITY_TEX = false;
SPEC_CONST(int) NODE_69_DROPLIST_ITEM = 0;


// Material Parameters ( Tweaks )

uniform NF_PRECISION               float4 baseColor; // Title: Base Color
SC_DECLARE_TEXTURE(baseTex); //    Title: Texture
uniform NF_PRECISION               float2 uv2Scale; // Title: Scale
uniform NF_PRECISION               float2 uv2Offset; // Title: Offset
uniform NF_PRECISION               float2 uv3Scale; // Title: Scale
uniform NF_PRECISION               float2 uv3Offset; // Title: Offset
SC_DECLARE_TEXTURE(opacityTex); // Title: Texture
uniform NF_PRECISION               float  blur; // Title: Blur
uniform NF_PRECISION               float2 boxSize; // Title: BoxSize
uniform NF_PRECISION               float  cornerRadius; // Title: Corner Radius	


// Uniforms ( Ports )

#if defined( STUDIO )
uniform NF_PRECISION float4 Port_Import_N384;
uniform NF_PRECISION float Port_Import_N307;
uniform NF_PRECISION float Port_Import_N201;
uniform NF_PRECISION float Port_Import_N010;
uniform NF_PRECISION float Port_Import_N007;
uniform NF_PRECISION float2 Port_Import_N008;
uniform NF_PRECISION float2 Port_Import_N009;
uniform NF_PRECISION float Port_Speed_N022;
uniform NF_PRECISION float Port_Import_N012;
uniform NF_PRECISION float2 Port_Import_N254;
uniform NF_PRECISION float Port_Import_N055;
uniform NF_PRECISION float Port_Import_N056;
uniform NF_PRECISION float2 Port_Import_N000;
uniform NF_PRECISION float2 Port_Import_N060;
uniform NF_PRECISION float2 Port_Import_N061;
uniform NF_PRECISION float Port_Speed_N063;
uniform NF_PRECISION float Port_Import_N065;
uniform NF_PRECISION float2 Port_Import_N255;
uniform NF_PRECISION float4 Port_Default_N369;
uniform NF_PRECISION float4 Port_Import_N166;
uniform NF_PRECISION float Port_Import_N206;
uniform NF_PRECISION float Port_Import_N043;
uniform NF_PRECISION float2 Port_Import_N151;
uniform NF_PRECISION float2 Port_Import_N155;
uniform NF_PRECISION float Port_Default_N204;
uniform NF_PRECISION float Port_Input1_N098;
uniform NF_PRECISION float2 Port_Input1_N085;
uniform NF_PRECISION float2 Port_Input1_N089;
uniform NF_PRECISION float Port_Input1_N094;
uniform NF_PRECISION float3 Port_Input0_N073;
uniform NF_PRECISION float3 Port_Input1_N073;
uniform NF_PRECISION float2 Port_Input0_N042;
uniform NF_PRECISION float2 Port_Input1_N046;
uniform NF_PRECISION float Port_Input1_N047;
uniform NF_PRECISION float Port_Multiplier_N054;
uniform NF_PRECISION float Port_Input1_N078;
uniform NF_PRECISION float Port_Input1_N080;
uniform NF_PRECISION float Port_Input1_N079;
uniform NF_PRECISION float Port_Input1_N057;
uniform NF_PRECISION float Port_Input1_N070;
uniform NF_PRECISION float2 Port_Scale_N081;
uniform NF_PRECISION float Port_Input2_N082;
uniform NF_PRECISION float Port_Input2_N045;
uniform NF_PRECISION float Port_Input1_N099;
#endif	



//-----------------------------------------------------------------------


#if defined(SC_ENABLE_RT_CASTER)
uniform highp float depthRef;
#endif


//-----------------------------------------------------------------------

#ifdef VERTEX_SHADER

//----------

// Globals

struct ssGlobals
{
	float gTimeElapsed;
	float gTimeDelta;
	float gTimeElapsedShifted;
	
	
};

ssGlobals tempGlobals;
#define scCustomCodeUniform

//-----------------------------------------------------------------------

void main() 
{
	
	#if defined(SC_ENABLE_RT_CASTER) 
	if (bool(sc_ProxyMode)) {
		sc_SetClipPosition(vec4(position.xy, depthRef + 1e-10 * position.z, 1.0 + 1e-10 * position.w)); // GPU_BUG_028
		return;
	}
	#endif
	
	
	NF_SETUP_PREVIEW_VERTEX()
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	sc_Vertex_t v;
	ngsVertexShaderBegin( v );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssGlobals Globals;	
	Globals.gTimeElapsed = ( overrideTimeEnabled == 1 ) ? overrideTimeElapsed : sc_TimeElapsed;
	Globals.gTimeDelta   = ( overrideTimeEnabled == 1 ) ? overrideTimeDelta : sc_TimeDelta;
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	float4 ScreenPosition = vec4( 0.0 );
	float3 WorldPosition  = varPos;
	float3 WorldNormal    = varNormal;
	float3 WorldTangent   = varTangent.xyz;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// no vertex transformation needed
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( NF_DISABLE_VERTEX_CHANGES() )
	{
		WorldPosition  = varPos;
		WorldNormal    = varNormal;
		WorldTangent   = varTangent.xyz;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ngsVertexShaderEnd( v, WorldPosition, WorldNormal, WorldTangent, v.position );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	NF_PREVIEW_OUTPUT_VERTEX()
}

//-----------------------------------------------------------------------

#endif // #ifdef VERTEX_SHADER

//-----------------------------------------------------------------------

#ifdef FRAGMENT_SHADER

//-----------------------------------------------------------------------------

//----------

// Globals

struct ssGlobals
{
	float gTimeElapsed;
	float gTimeDelta;
	float gTimeElapsedShifted;
	
	float2 Surface_UVCoord0;
	float2 Surface_UVCoord1;
	float2 gScreenCoord;
};

ssGlobals tempGlobals;
#define scCustomCodeUniform	

//----------

// Functions

void Node5_Color_Parameter( out float4 Output, ssGlobals Globals ) { Output = baseColor; }
#define Node384_Float_Import( Import, Value, Globals ) Value = Import
void Node121_Bool_Parameter( out float Output, ssGlobals Globals )
{ 
	if ( ENABLE_BASE_TEX )
	{
		Output = 1.001;
	}
	else
	{
		Output = 0.001;
	}
	
	Output -= 0.001; // LOOK-62828
}
#define Node307_Float_Import( Import, Value, Globals ) Value = Import
#define Node28_Texture_2D_Object_Parameter( Globals ) /*nothing*/
#define Node199_Texture_Object_2D_Import( Globals ) /*nothing*/
#define Node27_DropList_Parameter( Output, Globals ) Output = float( NODE_27_DROPLIST_ITEM )
#define Node201_Float_Import( Import, Value, Globals ) Value = Import
#define Node3_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
#define Node24_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord1
#define Node32_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
void Node16_Bool_Parameter( out float Output, ssGlobals Globals )
{ 
	if ( uv2EnableAnimation )
	{
		Output = 1.001;
	}
	else
	{
		Output = 0.001;
	}
	
	Output -= 0.001; // LOOK-62828
}
#define Node10_Float_Import( Import, Value, Globals ) Value = Import
#define Node13_DropList_Parameter( Output, Globals ) Output = float( NODE_13_DROPLIST_ITEM )
#define Node7_Float_Import( Import, Value, Globals ) Value = Import
#define Node33_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord1
#define Node20_Screen_UV_Coord( ScreenCoord, Globals ) ScreenCoord = Globals.gScreenCoord
void Node17_Switch( in float Switch, in float2 Value0, in float2 Value1, in float2 Value2, in float2 Default, out float2 Result, ssGlobals Globals )
{ 
	if ( int( NODE_13_DROPLIST_ITEM ) == 0 )
	{
		/* Input port: "Value0"  */
		
		{
			float2 UVCoord_N32 = float2(0.0); Node32_Surface_UV_Coord( UVCoord_N32, Globals );
			
			Value0 = UVCoord_N32;
		}
		Result = Value0;
	}
	else if ( int( NODE_13_DROPLIST_ITEM ) == 1 )
	{
		/* Input port: "Value1"  */
		
		{
			float2 UVCoord_N33 = float2(0.0); Node33_Surface_UV_Coord( UVCoord_N33, Globals );
			
			Value1 = UVCoord_N33;
		}
		Result = Value1;
	}
	else if ( int( NODE_13_DROPLIST_ITEM ) == 2 )
	{
		/* Input port: "Value2"  */
		
		{
			float2 ScreenCoord_N20 = float2(0.0); Node20_Screen_UV_Coord( ScreenCoord_N20, Globals );
			
			Value2 = ScreenCoord_N20;
		}
		Result = Value2;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float2 UVCoord_N32 = float2(0.0); Node32_Surface_UV_Coord( UVCoord_N32, Globals );
			
			Default = UVCoord_N32;
		}
		Result = Default;
	}
}
void Node14_Float_Parameter( out float2 Output, ssGlobals Globals ) { Output = uv2Scale; }
#define Node8_Float_Import( Import, Value, Globals ) Value = Import
void Node15_Float_Parameter( out float2 Output, ssGlobals Globals ) { Output = uv2Offset; }
#define Node9_Float_Import( Import, Value, Globals ) Value = Import
#define Node21_Scale_and_Offset( Input0, Input1, Input2, Output, Globals ) Output = Input0 * Input1 + Input2
#define Node22_Scroll_Coords( CoordsIn, Direction, Speed, CoordsOut, Globals ) CoordsOut = CoordsIn + ( Globals.gTimeElapsed * Speed * Direction )
void Node122_If_else( in float Bool1, in float2 Value1, in float2 Default, out float2 Result, ssGlobals Globals )
{ 
	if ( bool( uv2EnableAnimation ) )
	{
		/* Input port: "Value1"  */
		
		{
			float2 Result_N17 = float2(0.0); Node17_Switch( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N17, Globals );
			float2 Output_N14 = float2(0.0); Node14_Float_Parameter( Output_N14, Globals );
			float2 Value_N8 = float2(0.0); Node8_Float_Import( Output_N14, Value_N8, Globals );
			float2 Output_N15 = float2(0.0); Node15_Float_Parameter( Output_N15, Globals );
			float2 Value_N9 = float2(0.0); Node9_Float_Import( Output_N15, Value_N9, Globals );
			float2 Output_N21 = float2(0.0); Node21_Scale_and_Offset( Result_N17, Value_N8, Value_N9, Output_N21, Globals );
			float2 CoordsOut_N22 = float2(0.0); Node22_Scroll_Coords( Output_N21, Value_N9, NF_PORT_CONSTANT( float( 1.0 ), Port_Speed_N022 ), CoordsOut_N22, Globals );
			
			Value1 = CoordsOut_N22;
		}
		Result = Value1;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float2 Result_N17 = float2(0.0); Node17_Switch( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N17, Globals );
			float2 Output_N14 = float2(0.0); Node14_Float_Parameter( Output_N14, Globals );
			float2 Value_N8 = float2(0.0); Node8_Float_Import( Output_N14, Value_N8, Globals );
			float2 Output_N15 = float2(0.0); Node15_Float_Parameter( Output_N15, Globals );
			float2 Value_N9 = float2(0.0); Node9_Float_Import( Output_N15, Value_N9, Globals );
			float2 Output_N21 = float2(0.0); Node21_Scale_and_Offset( Result_N17, Value_N8, Value_N9, Output_N21, Globals );
			
			Default = Output_N21;
		}
		Result = Default;
	}
}
void Node67_Bool_Parameter( out float Output, ssGlobals Globals )
{ 
	if ( Tweak_N67 )
	{
		Output = 1.001;
	}
	else
	{
		Output = 0.001;
	}
	
	Output -= 0.001; // LOOK-62828
}
#define Node12_Float_Import( Import, Value, Globals ) Value = Import
#define Node35_Mix( Input0, Input1, Input2, Output, Globals ) Output = mix( Input0, Input1, float2(Input2) )
#define Node23_Float_Export( Value, Export, Globals ) Export = Value
#define Node254_Float_Import( Import, Value, Globals ) Value = Import
#define Node18_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
void Node52_Bool_Parameter( out float Output, ssGlobals Globals )
{ 
	if ( uv3EnableAnimation )
	{
		Output = 1.001;
	}
	else
	{
		Output = 0.001;
	}
	
	Output -= 0.001; // LOOK-62828
}
#define Node55_Float_Import( Import, Value, Globals ) Value = Import
#define Node49_DropList_Parameter( Output, Globals ) Output = float( NODE_49_DROPLIST_ITEM )
#define Node56_Float_Import( Import, Value, Globals ) Value = Import
#define Node19_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord1
#define Node58_Screen_UV_Coord( ScreenCoord, Globals ) ScreenCoord = Globals.gScreenCoord
#define Node0_Float_Import( Import, Value, Globals ) Value = Import
void Node59_Switch( in float Switch, in float2 Value0, in float2 Value1, in float2 Value2, in float2 Value3, in float2 Default, out float2 Result, ssGlobals Globals )
{ 
	if ( int( NODE_49_DROPLIST_ITEM ) == 0 )
	{
		/* Input port: "Value0"  */
		
		{
			float2 UVCoord_N18 = float2(0.0); Node18_Surface_UV_Coord( UVCoord_N18, Globals );
			
			Value0 = UVCoord_N18;
		}
		Result = Value0;
	}
	else if ( int( NODE_49_DROPLIST_ITEM ) == 1 )
	{
		/* Input port: "Value1"  */
		
		{
			float2 UVCoord_N19 = float2(0.0); Node19_Surface_UV_Coord( UVCoord_N19, Globals );
			
			Value1 = UVCoord_N19;
		}
		Result = Value1;
	}
	else if ( int( NODE_49_DROPLIST_ITEM ) == 2 )
	{
		/* Input port: "Value2"  */
		
		{
			float2 ScreenCoord_N58 = float2(0.0); Node58_Screen_UV_Coord( ScreenCoord_N58, Globals );
			
			Value2 = ScreenCoord_N58;
		}
		Result = Value2;
	}
	else if ( int( NODE_49_DROPLIST_ITEM ) == 3 )
	{
		/* Input port: "Value3"  */
		
		{
			float2 UVCoord_N32 = float2(0.0); Node32_Surface_UV_Coord( UVCoord_N32, Globals );
			float2 Result_N122 = float2(0.0); Node122_If_else( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N122, Globals );
			float Output_N67 = 0.0; Node67_Bool_Parameter( Output_N67, Globals );
			float Value_N12 = 0.0; Node12_Float_Import( Output_N67, Value_N12, Globals );
			float2 Output_N35 = float2(0.0); Node35_Mix( UVCoord_N32, Result_N122, Value_N12, Output_N35, Globals );
			float2 Export_N23 = float2(0.0); Node23_Float_Export( Output_N35, Export_N23, Globals );
			float2 Value_N0 = float2(0.0); Node0_Float_Import( Export_N23, Value_N0, Globals );
			
			Value3 = Value_N0;
		}
		Result = Value3;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float2 UVCoord_N18 = float2(0.0); Node18_Surface_UV_Coord( UVCoord_N18, Globals );
			
			Default = UVCoord_N18;
		}
		Result = Default;
	}
}
void Node50_Float_Parameter( out float2 Output, ssGlobals Globals ) { Output = uv3Scale; }
#define Node60_Float_Import( Import, Value, Globals ) Value = Import
void Node51_Float_Parameter( out float2 Output, ssGlobals Globals ) { Output = uv3Offset; }
#define Node61_Float_Import( Import, Value, Globals ) Value = Import
#define Node62_Scale_and_Offset( Input0, Input1, Input2, Output, Globals ) Output = Input0 * Input1 + Input2
#define Node63_Scroll_Coords( CoordsIn, Direction, Speed, CoordsOut, Globals ) CoordsOut = CoordsIn + ( Globals.gTimeElapsed * Speed * Direction )
void Node64_If_else( in float Bool1, in float2 Value1, in float2 Default, out float2 Result, ssGlobals Globals )
{ 
	if ( bool( uv3EnableAnimation ) )
	{
		/* Input port: "Value1"  */
		
		{
			float2 Result_N59 = float2(0.0); Node59_Switch( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N59, Globals );
			float2 Output_N50 = float2(0.0); Node50_Float_Parameter( Output_N50, Globals );
			float2 Value_N60 = float2(0.0); Node60_Float_Import( Output_N50, Value_N60, Globals );
			float2 Output_N51 = float2(0.0); Node51_Float_Parameter( Output_N51, Globals );
			float2 Value_N61 = float2(0.0); Node61_Float_Import( Output_N51, Value_N61, Globals );
			float2 Output_N62 = float2(0.0); Node62_Scale_and_Offset( Result_N59, Value_N60, Value_N61, Output_N62, Globals );
			float2 CoordsOut_N63 = float2(0.0); Node63_Scroll_Coords( Output_N62, Value_N61, NF_PORT_CONSTANT( float( 1.0 ), Port_Speed_N063 ), CoordsOut_N63, Globals );
			
			Value1 = CoordsOut_N63;
		}
		Result = Value1;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float2 Result_N59 = float2(0.0); Node59_Switch( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N59, Globals );
			float2 Output_N50 = float2(0.0); Node50_Float_Parameter( Output_N50, Globals );
			float2 Value_N60 = float2(0.0); Node60_Float_Import( Output_N50, Value_N60, Globals );
			float2 Output_N51 = float2(0.0); Node51_Float_Parameter( Output_N51, Globals );
			float2 Value_N61 = float2(0.0); Node61_Float_Import( Output_N51, Value_N61, Globals );
			float2 Output_N62 = float2(0.0); Node62_Scale_and_Offset( Result_N59, Value_N60, Value_N61, Output_N62, Globals );
			
			Default = Output_N62;
		}
		Result = Default;
	}
}
void Node11_Bool_Parameter( out float Output, ssGlobals Globals )
{ 
	if ( Tweak_N11 )
	{
		Output = 1.001;
	}
	else
	{
		Output = 0.001;
	}
	
	Output -= 0.001; // LOOK-62828
}
#define Node65_Float_Import( Import, Value, Globals ) Value = Import
#define Node66_Mix( Input0, Input1, Input2, Output, Globals ) Output = mix( Input0, Input1, float2(Input2) )
#define Node125_Float_Export( Value, Export, Globals ) Export = Value
#define Node255_Float_Import( Import, Value, Globals ) Value = Import
void Node388_Switch( in float Switch, in float2 Value0, in float2 Value1, in float2 Value2, in float2 Value3, in float2 Default, out float2 Result, ssGlobals Globals )
{ 
	if ( int( NODE_27_DROPLIST_ITEM ) == 0 )
	{
		/* Input port: "Value0"  */
		
		{
			float2 UVCoord_N3 = float2(0.0); Node3_Surface_UV_Coord( UVCoord_N3, Globals );
			
			Value0 = UVCoord_N3;
		}
		Result = Value0;
	}
	else if ( int( NODE_27_DROPLIST_ITEM ) == 1 )
	{
		/* Input port: "Value1"  */
		
		{
			float2 UVCoord_N24 = float2(0.0); Node24_Surface_UV_Coord( UVCoord_N24, Globals );
			
			Value1 = UVCoord_N24;
		}
		Result = Value1;
	}
	else if ( int( NODE_27_DROPLIST_ITEM ) == 2 )
	{
		/* Input port: "Value2"  */
		
		{
			float2 UVCoord_N32 = float2(0.0); Node32_Surface_UV_Coord( UVCoord_N32, Globals );
			float2 Result_N122 = float2(0.0); Node122_If_else( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N122, Globals );
			float Output_N67 = 0.0; Node67_Bool_Parameter( Output_N67, Globals );
			float Value_N12 = 0.0; Node12_Float_Import( Output_N67, Value_N12, Globals );
			float2 Output_N35 = float2(0.0); Node35_Mix( UVCoord_N32, Result_N122, Value_N12, Output_N35, Globals );
			float2 Export_N23 = float2(0.0); Node23_Float_Export( Output_N35, Export_N23, Globals );
			float2 Value_N254 = float2(0.0); Node254_Float_Import( Export_N23, Value_N254, Globals );
			
			Value2 = Value_N254;
		}
		Result = Value2;
	}
	else if ( int( NODE_27_DROPLIST_ITEM ) == 3 )
	{
		/* Input port: "Value3"  */
		
		{
			float2 UVCoord_N18 = float2(0.0); Node18_Surface_UV_Coord( UVCoord_N18, Globals );
			float2 Result_N64 = float2(0.0); Node64_If_else( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N64, Globals );
			float Output_N11 = 0.0; Node11_Bool_Parameter( Output_N11, Globals );
			float Value_N65 = 0.0; Node65_Float_Import( Output_N11, Value_N65, Globals );
			float2 Output_N66 = float2(0.0); Node66_Mix( UVCoord_N18, Result_N64, Value_N65, Output_N66, Globals );
			float2 Export_N125 = float2(0.0); Node125_Float_Export( Output_N66, Export_N125, Globals );
			float2 Value_N255 = float2(0.0); Node255_Float_Import( Export_N125, Value_N255, Globals );
			
			Value3 = Value_N255;
		}
		Result = Value3;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float2 UVCoord_N3 = float2(0.0); Node3_Surface_UV_Coord( UVCoord_N3, Globals );
			
			Default = UVCoord_N3;
		}
		Result = Default;
	}
}
#define Node389_Texture_2D_Sample( UVCoord, Color, Globals ) Color = SC_SAMPLE_TEX_R(baseTex, UVCoord, 0.0)
void Node369_If_else( in float Bool1, in float4 Value1, in float4 Default, out float4 Result, ssGlobals Globals )
{ 
	if ( bool( ENABLE_BASE_TEX ) )
	{
		/* Input port: "Value1"  */
		
		{
			Node28_Texture_2D_Object_Parameter( Globals );
			Node199_Texture_Object_2D_Import( Globals );
			float2 Result_N388 = float2(0.0); Node388_Switch( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N388, Globals );
			float4 Color_N389 = float4(0.0); Node389_Texture_2D_Sample( Result_N388, Color_N389, Globals );
			
			Value1 = Color_N389;
		}
		Result = Value1;
	}
	else
	{
		
		Result = Default;
	}
}
#define Node148_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node385_Float_Export( Value, Export, Globals ) Export = Value
#define Node166_Float_Import( Import, Value, Globals ) Value = Import
#define Node168_Swizzle( Input, Output, Globals ) Output = Input.a
void Node308_Bool_Parameter( out float Output, ssGlobals Globals )
{ 
	if ( ENABLE_OPACITY_TEX )
	{
		Output = 1.001;
	}
	else
	{
		Output = 0.001;
	}
	
	Output -= 0.001; // LOOK-62828
}
#define Node206_Float_Import( Import, Value, Globals ) Value = Import
#define Node68_Texture_2D_Object_Parameter( Globals ) /*nothing*/
#define Node40_Texture_Object_2D_Import( Globals ) /*nothing*/
#define Node69_DropList_Parameter( Output, Globals ) Output = float( NODE_69_DROPLIST_ITEM )
#define Node43_Float_Import( Import, Value, Globals ) Value = Import
#define Node26_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
#define Node29_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord1
#define Node151_Float_Import( Import, Value, Globals ) Value = Import
#define Node155_Float_Import( Import, Value, Globals ) Value = Import
void Node156_Switch( in float Switch, in float2 Value0, in float2 Value1, in float2 Value2, in float2 Value3, in float2 Default, out float2 Result, ssGlobals Globals )
{ 
	if ( int( NODE_69_DROPLIST_ITEM ) == 0 )
	{
		/* Input port: "Value0"  */
		
		{
			float2 UVCoord_N26 = float2(0.0); Node26_Surface_UV_Coord( UVCoord_N26, Globals );
			
			Value0 = UVCoord_N26;
		}
		Result = Value0;
	}
	else if ( int( NODE_69_DROPLIST_ITEM ) == 1 )
	{
		/* Input port: "Value1"  */
		
		{
			float2 UVCoord_N29 = float2(0.0); Node29_Surface_UV_Coord( UVCoord_N29, Globals );
			
			Value1 = UVCoord_N29;
		}
		Result = Value1;
	}
	else if ( int( NODE_69_DROPLIST_ITEM ) == 2 )
	{
		/* Input port: "Value2"  */
		
		{
			float2 UVCoord_N32 = float2(0.0); Node32_Surface_UV_Coord( UVCoord_N32, Globals );
			float2 Result_N122 = float2(0.0); Node122_If_else( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N122, Globals );
			float Output_N67 = 0.0; Node67_Bool_Parameter( Output_N67, Globals );
			float Value_N12 = 0.0; Node12_Float_Import( Output_N67, Value_N12, Globals );
			float2 Output_N35 = float2(0.0); Node35_Mix( UVCoord_N32, Result_N122, Value_N12, Output_N35, Globals );
			float2 Export_N23 = float2(0.0); Node23_Float_Export( Output_N35, Export_N23, Globals );
			float2 Value_N151 = float2(0.0); Node151_Float_Import( Export_N23, Value_N151, Globals );
			
			Value2 = Value_N151;
		}
		Result = Value2;
	}
	else if ( int( NODE_69_DROPLIST_ITEM ) == 3 )
	{
		/* Input port: "Value3"  */
		
		{
			float2 UVCoord_N18 = float2(0.0); Node18_Surface_UV_Coord( UVCoord_N18, Globals );
			float2 Result_N64 = float2(0.0); Node64_If_else( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N64, Globals );
			float Output_N11 = 0.0; Node11_Bool_Parameter( Output_N11, Globals );
			float Value_N65 = 0.0; Node65_Float_Import( Output_N11, Value_N65, Globals );
			float2 Output_N66 = float2(0.0); Node66_Mix( UVCoord_N18, Result_N64, Value_N65, Output_N66, Globals );
			float2 Export_N125 = float2(0.0); Node125_Float_Export( Output_N66, Export_N125, Globals );
			float2 Value_N155 = float2(0.0); Node155_Float_Import( Export_N125, Value_N155, Globals );
			
			Value3 = Value_N155;
		}
		Result = Value3;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float2 UVCoord_N26 = float2(0.0); Node26_Surface_UV_Coord( UVCoord_N26, Globals );
			
			Default = UVCoord_N26;
		}
		Result = Default;
	}
}
#define Node157_Texture_2D_Sample( UVCoord, Color, Globals ) Color = SC_SAMPLE_TEX_R(opacityTex, UVCoord, 0.0)
#define Node203_Swizzle( Input, Output, Globals ) Output = Input
void Node204_If_else( in float Bool1, in float Value1, in float Default, out float Result, ssGlobals Globals )
{ 
	if ( bool( ENABLE_OPACITY_TEX ) )
	{
		/* Input port: "Value1"  */
		
		{
			Node68_Texture_2D_Object_Parameter( Globals );
			Node40_Texture_Object_2D_Import( Globals );
			float2 Result_N156 = float2(0.0); Node156_Switch( float( 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), float2( 0.0, 0.0 ), Result_N156, Globals );
			float4 Color_N157 = float4(0.0); Node157_Texture_2D_Sample( Result_N156, Color_N157, Globals );
			float Output_N203 = 0.0; Node203_Swizzle( Color_N157.x, Output_N203, Globals );
			
			Value1 = Output_N203;
		}
		Result = Value1;
	}
	else
	{
		
		Result = Default;
	}
}
#define Node205_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node158_Float_Export( Value, Export, Globals ) Export = Value
void Node97_Float_Parameter( out float Output, ssGlobals Globals ) { Output = blur; }
#define Node98_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node84_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
#define Node85_Subtract( Input0, Input1, Output, Globals ) Output = Input0 - Input1
#define Node86_Abs( Input0, Output, Globals ) Output = abs( Input0 )
void Node83_Float_Parameter( out float2 Output, ssGlobals Globals ) { Output = boxSize; }
void Node88_Float_Parameter( out float Output, ssGlobals Globals ) { Output = cornerRadius; }
#define Node87_Subtract( Input0, Input1, Output, Globals ) Output = Input0 - float2(Input1)
#define Node90_Subtract( Input0, Input1, Output, Globals ) Output = Input0 - Input1
#define Node89_Max( Input0, Input1, Output, Globals ) Output = max( Input0, Input1 )
#define Node91_Length( Input0, Output, Globals ) Output = length( Input0 )
#define Node92_Subtract( Input0, Input1, Output, Globals ) Output = Input0 - Input1
#define Node93_Smoothstep( Input0, Input1, Input2, Output, Globals ) Output = smoothstep( Input0, Input1, Input2 )
#define Node94_Max( Input0, Input1, Output, Globals ) Output = max( Input0, Input1 )
#define Node95_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node1_Construct_Vector( Value1, Value2, Value, Globals ) Value.xyz = Value1; Value.w = Value2
#define Node41_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
#define Node46_Subtract( Input0, Input1, Output, Globals ) Output = Input0 - Input1
#define Node47_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * float2(Input1)
#define Node42_Distance( Input0, Input1, Output, Globals ) Output = distance( Input0, Input1 )
#define Node44_Construct_Vector( Value1, Value2, Value3, Value, Globals ) Value.r = Value1; Value.g = Value2; Value.b = Value3
#define Node73_Smoothstep( Input0, Input1, Input2, Output, Globals ) Output = smoothstep( Input0, Input1, Input2 )
#define Node54_Elapsed_Time( Multiplier, Time, Globals ) Time = Globals.gTimeElapsed * Multiplier
#define Node76_Sin( Input0, Output, Globals ) Output = sin( Input0 )
#define Node78_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node75_Sin( Input0, Output, Globals ) Output = sin( Input0 )
#define Node77_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node80_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node79_Max( Input0, Input1, Output, Globals ) Output = max( Input0, Input1 )
#define Node57_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node70_Add( Input0, Input1, Output, Globals ) Output = Input0 + Input1
#define Node48_Pow( Input0, Input1, Output, Globals ) Output = vec3( ( Input0.x <= 0.0 ) ? 0.0 : pow( Input0.x, Input1 ), ( Input0.y <= 0.0 ) ? 0.0 : pow( Input0.y, Input1 ), ( Input0.z <= 0.0 ) ? 0.0 : pow( Input0.z, Input1 ) )
#define Node72_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
void Node81_Random_Noise( in float2 Seed, in float2 Scale, out float Random, ssGlobals Globals )
{ 
	ssPRECISION_LIMITER( Seed )
	Random = dot( floor( Seed * Scale ), vec2( 0.98, 0.72 ) );
	ssPRECISION_LIMITER( Random ) 
	Random = sin( Random );
	Random = Random * 437.585;
	Random = fract( Random ); 
	ssPRECISION_LIMITER( Random )
}
#define Node82_Mix( Input0, Input1, Input2, Output, Globals ) Output = mix( Input0, float3(Input1), float3(Input2) )
#define Node74_Construct_Vector( Value1, Value2, Value, Globals ) Value.xyz = Value1; Value.w = Value2
#define Node45_Mix( Input0, Input1, Input2, Output, Globals ) Output = mix( Input0, Input1, float4(Input2) )
#define Node99_Step( Input0, Input1, Output, Globals ) Output = step( Input0, Input1 )
void Node96_Discard( in float4 Input0, in float Input1, out float4 Output, ssGlobals Globals )
{ 
	Output = Input0;
	
	#ifdef FRAGMENT_SHADER
	if ( Input1 * 1.0 != 0.0 )
	{
		discard;
	}	
	#endif
}
//-----------------------------------------------------------------------------

void main() 
{
	if (bool(sc_DepthOnly)) {
		return;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	sc_DiscardStereoFragment();
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	NF_SETUP_PREVIEW_PIXEL()
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	float4 FinalColor = float4( 1.0, 1.0, 1.0, 1.0 );
	
	
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssGlobals Globals;	
	Globals.gTimeElapsed = ( overrideTimeEnabled == 1 ) ? overrideTimeElapsed : sc_TimeElapsed;
	Globals.gTimeDelta   = ( overrideTimeEnabled == 1 ) ? overrideTimeDelta : sc_TimeDelta;
	
	
	#if defined(SC_ENABLE_RT_CASTER) 
	if (bool(sc_ProxyMode)) {
		RayHitPayload rhp = GetRayTracingHitData();
		
		if (bool(sc_NoEarlyZ)) {
			if (rhp.id.x != uint(instance_id)) {
				return;
			}
		}
		
		Globals.Surface_UVCoord0 = rhp.uv0;
		Globals.Surface_UVCoord1 = rhp.uv1;
		
		float4                   emitterPositionCS = ngsViewProjectionMatrix * float4( rhp.positionWS , 1.0 );
		Globals.gScreenCoord     = (emitterPositionCS.xy / emitterPositionCS.w) * 0.5 + 0.5;
	} else
	#endif
	
	{
		Globals.Surface_UVCoord0 = varTex01.xy;
		Globals.Surface_UVCoord1 = varTex01.zw;
		
		#ifdef                   VERTEX_SHADER
		
		float4                   Result = ngsViewProjectionMatrix * float4( varPos, 1.0 );
		Result.xyz               /= Result.w; /* map from clip space to NDC space. keep w around so we can re-project back to world*/
		Globals.gScreenCoord     = Result.xy * 0.5 + 0.5;
		
		#else
		
		Globals.gScreenCoord     = getScreenUV().xy;
		
		#endif
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	/* Input port: 'FinalColor'  */
	
	{
		float4 Output_N5 = float4(0.0); Node5_Color_Parameter( Output_N5, Globals );
		float4 Value_N384 = float4(0.0); Node384_Float_Import( Output_N5, Value_N384, Globals );
		float4 Result_N369 = float4(0.0); Node369_If_else( float( 0.0 ), float4( 0.0, 0.0, 0.0, 0.0 ), NF_PORT_CONSTANT( float4( 1.0, 1.0, 1.0, 1.0 ), Port_Default_N369 ), Result_N369, Globals );
		float4 Output_N148 = float4(0.0); Node148_Multiply( Value_N384, Result_N369, Output_N148, Globals );
		float4 Export_N385 = float4(0.0); Node385_Float_Export( Output_N148, Export_N385, Globals );
		float4 Value_N166 = float4(0.0); Node166_Float_Import( Export_N385, Value_N166, Globals );
		float Output_N168 = 0.0; Node168_Swizzle( Value_N166, Output_N168, Globals );
		float Result_N204 = 0.0; Node204_If_else( float( 0.0 ), float( 0.0 ), NF_PORT_CONSTANT( float( 1.0 ), Port_Default_N204 ), Result_N204, Globals );
		float Output_N205 = 0.0; Node205_Multiply( Output_N168, Result_N204, Output_N205, Globals );
		float Export_N158 = 0.0; Node158_Float_Export( Output_N205, Export_N158, Globals );
		float Output_N97 = 0.0; Node97_Float_Parameter( Output_N97, Globals );
		float Output_N98 = 0.0; Node98_Multiply( Output_N97, NF_PORT_CONSTANT( float( -1.0 ), Port_Input1_N098 ), Output_N98, Globals );
		float2 UVCoord_N84 = float2(0.0); Node84_Surface_UV_Coord( UVCoord_N84, Globals );
		float2 Output_N85 = float2(0.0); Node85_Subtract( UVCoord_N84, NF_PORT_CONSTANT( float2( 0.5, 0.5 ), Port_Input1_N085 ), Output_N85, Globals );
		float2 Output_N86 = float2(0.0); Node86_Abs( Output_N85, Output_N86, Globals );
		float2 Output_N83 = float2(0.0); Node83_Float_Parameter( Output_N83, Globals );
		float Output_N88 = 0.0; Node88_Float_Parameter( Output_N88, Globals );
		float2 Output_N87 = float2(0.0); Node87_Subtract( Output_N83, Output_N88, Output_N87, Globals );
		float2 Output_N90 = float2(0.0); Node90_Subtract( Output_N86, Output_N87, Output_N90, Globals );
		float2 Output_N89 = float2(0.0); Node89_Max( Output_N90, NF_PORT_CONSTANT( float2( 0.0, 0.0 ), Port_Input1_N089 ), Output_N89, Globals );
		float Output_N91 = 0.0; Node91_Length( Output_N89, Output_N91, Globals );
		float Output_N92 = 0.0; Node92_Subtract( Output_N91, Output_N88, Output_N92, Globals );
		float Output_N93 = 0.0; Node93_Smoothstep( Output_N97, Output_N98, Output_N92, Output_N93, Globals );
		float Output_N94 = 0.0; Node94_Max( Output_N93, NF_PORT_CONSTANT( float( 0.0 ), Port_Input1_N094 ), Output_N94, Globals );
		float Output_N95 = 0.0; Node95_Multiply( Export_N158, Output_N94, Output_N95, Globals );
		float4 Value_N1 = float4(0.0); Node1_Construct_Vector( Export_N385.xyz, Output_N95, Value_N1, Globals );
		float2 UVCoord_N41 = float2(0.0); Node41_Surface_UV_Coord( UVCoord_N41, Globals );
		float2 Output_N46 = float2(0.0); Node46_Subtract( UVCoord_N41, NF_PORT_CONSTANT( float2( 0.5, 0.5 ), Port_Input1_N046 ), Output_N46, Globals );
		float2 Output_N47 = float2(0.0); Node47_Multiply( Output_N46, NF_PORT_CONSTANT( float( 1.36 ), Port_Input1_N047 ), Output_N47, Globals );
		float Output_N42 = 0.0; Node42_Distance( NF_PORT_CONSTANT( float2( 0.0, 0.0 ), Port_Input0_N042 ), Output_N47, Output_N42, Globals );
		float3 Value_N44 = float3(0.0); Node44_Construct_Vector( Output_N42, Output_N42, Output_N42, Value_N44, Globals );
		float3 Output_N73 = float3(0.0); Node73_Smoothstep( NF_PORT_CONSTANT( float3( 0.0, 0.0, 0.0 ), Port_Input0_N073 ), NF_PORT_CONSTANT( float3( 0.870558, 0.870558, 0.870558 ), Port_Input1_N073 ), Value_N44, Output_N73, Globals );
		float Time_N54 = 0.0; Node54_Elapsed_Time( NF_PORT_CONSTANT( float( 2.8 ), Port_Multiplier_N054 ), Time_N54, Globals );
		float Output_N76 = 0.0; Node76_Sin( Time_N54, Output_N76, Globals );
		float Output_N78 = 0.0; Node78_Multiply( Output_N76, NF_PORT_CONSTANT( float( 2.0 ), Port_Input1_N078 ), Output_N78, Globals );
		float Output_N75 = 0.0; Node75_Sin( Time_N54, Output_N75, Globals );
		float Output_N77 = 0.0; Node77_Multiply( Output_N78, Output_N75, Output_N77, Globals );
		float Output_N80 = 0.0; Node80_Multiply( Output_N77, NF_PORT_CONSTANT( float( 2.0 ), Port_Input1_N080 ), Output_N80, Globals );
		float Output_N79 = 0.0; Node79_Max( Output_N80, NF_PORT_CONSTANT( float( 0.0 ), Port_Input1_N079 ), Output_N79, Globals );
		float Output_N57 = 0.0; Node57_Multiply( Output_N79, NF_PORT_CONSTANT( float( 0.5 ), Port_Input1_N057 ), Output_N57, Globals );
		float Output_N70 = 0.0; Node70_Add( Output_N57, NF_PORT_CONSTANT( float( 0.5 ), Port_Input1_N070 ), Output_N70, Globals );
		float3 Output_N48 = float3(0.0); Node48_Pow( Output_N73, Output_N70, Output_N48, Globals );
		float2 UVCoord_N72 = float2(0.0); Node72_Surface_UV_Coord( UVCoord_N72, Globals );
		float Random_N81 = 0.0; Node81_Random_Noise( UVCoord_N72, NF_PORT_CONSTANT( float2( 1024.0, 1024.0 ), Port_Scale_N081 ), Random_N81, Globals );
		float3 Output_N82 = float3(0.0); Node82_Mix( Output_N48, Random_N81, NF_PORT_CONSTANT( float( 0.15 ), Port_Input2_N082 ), Output_N82, Globals );
		float4 Value_N74 = float4(0.0); Node74_Construct_Vector( Output_N82, Output_N95, Value_N74, Globals );
		float4 Output_N45 = float4(0.0); Node45_Mix( Value_N1, Value_N74, NF_PORT_CONSTANT( float( 0.56 ), Port_Input2_N045 ), Output_N45, Globals );
		float Output_N99 = 0.0; Node99_Step( Output_N95, NF_PORT_CONSTANT( float( 0.0001 ), Port_Input1_N099 ), Output_N99, Globals );
		float4 Output_N96 = float4(0.0); Node96_Discard( Output_N45, Output_N99, Output_N96, Globals );
		
		FinalColor = Output_N96;
	}
	ngsAlphaTest( FinalColor.a );
	
	
	
	
	
	
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	#if defined(SC_ENABLE_RT_CASTER) 
	if (bool(sc_ProxyMode)) {
		sc_writeFragData0( encodeReflection( FinalColor ) );
		return;
	}
	#endif
	
	FinalColor = ngsPixelShader( FinalColor );
	
	NF_PREVIEW_OUTPUT_PIXEL()
	
	#ifdef STUDIO
	vec4 Cost = getPixelRenderingCost();
	if ( Cost.w > 0.0 )
	FinalColor = Cost;
	#endif
	
	FinalColor = max( FinalColor, 0.0 );
	FinalColor = outputMotionVectorsIfNeeded(varPos, FinalColor);
	processOIT( FinalColor );
	
	
}

#endif // #ifdef FRAGMENT_SHADER
