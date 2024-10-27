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
#define SC_DISABLE_FRUSTUM_CULLING

#define SC_ENABLE_INSTANCED_RENDERING
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


// Material Parameters ( Tweaks )

uniform NF_PRECISION float  lineWeight; // Title: Line Weight
uniform NF_PRECISION float4 lineColor; // Title: Line Color	


// Uniforms ( Ports )

#if defined( STUDIO )
uniform NF_PRECISION float Port_Input1_N016;
uniform NF_PRECISION float Port_Input1_N013;
uniform NF_PRECISION float Port_Input1_N017;
uniform NF_PRECISION float4 Port_Value1_N015;
uniform NF_PRECISION float Port_Input1_N024;
uniform NF_PRECISION float4 Port_Value1_N022;
#endif	



//-----------------------------------------------------------------------



//-----------------------------------------------------------------------

#ifdef VERTEX_SHADER

//----------

// Interpolators

varying float Interpolator_gInstanceID;	

//----------

// Globals

struct ssGlobals
{
	float gTimeElapsed;
	float gTimeDelta;
	float gTimeElapsedShifted;
	
	float3 SurfacePosition_ObjectSpace;
	float3 VertexNormal_WorldSpace;
	float3 VertexNormal_ObjectSpace;
	float  gInstanceID;
};

ssGlobals tempGlobals;
#define scCustomCodeUniform	

//----------

// Functions

#define Node8_Surface_Position( Position, Globals ) Position = Globals.SurfacePosition_ObjectSpace
void Node1_Float_Parameter( out float Output, ssGlobals Globals ) { Output = lineWeight; }
#define Node16_Is_Less( Input0, Input1, Output, Globals ) Output = ssSmaller( Input0, Input1 )
#define Node0_Surface_Normal( Normal, Globals ) Normal = Globals.VertexNormal_ObjectSpace
#define Node20_Negate( Input0, Output, Globals ) Output = -Input0
void Node19_If_else( in float Bool1, in float3 Value1, in float3 Default, out float3 Result, ssGlobals Globals )
{ 
	/* Input port: "Bool1"  */
	
	{
		float Output_N1 = 0.0; Node1_Float_Parameter( Output_N1, Globals );
		float Output_N16 = 0.0; Node16_Is_Less( Output_N1, NF_PORT_CONSTANT( float( 0.0 ), Port_Input1_N016 ), Output_N16, Globals );
		
		Bool1 = Output_N16;
	}
	if ( bool( Bool1 * 1.0 != 0.0 ) )
	{
		/* Input port: "Value1"  */
		
		{
			float3 Normal_N0 = float3(0.0); Node0_Surface_Normal( Normal_N0, Globals );
			float3 Output_N20 = float3(0.0); Node20_Negate( Normal_N0, Output_N20, Globals );
			
			Value1 = Output_N20;
		}
		Result = Value1;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float3 Normal_N0 = float3(0.0); Node0_Surface_Normal( Normal_N0, Globals );
			
			Default = Normal_N0;
		}
		Result = Default;
	}
}
void Node10_Normalize( in float3 Input0, out float3 Output, ssGlobals Globals )
{ 
	float lengthSquared = dot( Input0, Input0 );
	float l = ( lengthSquared > 0.0 ) ? 1.0 / sqrt( lengthSquared  ) : 0.0;
	Output = Input0 * l;
}
#define Node12_Instance_ID( InstanceID, Globals ) InstanceID = floor( float( sc_LocalInstanceID ) + 0.5 )
#define Node13_Is_Greater( Input0, Input1, Output, Globals ) Output = ssLarger( Input0, Input1 )
#define Node18_Abs( Input0, Output, Globals ) Output = abs( Input0 )
#define Node17_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
void Node14_If_else( in float Bool1, in float Value1, in float Default, out float Result, ssGlobals Globals )
{ 
	/* Input port: "Bool1"  */
	
	{
		float InstanceID_N12 = 0.0; Node12_Instance_ID( InstanceID_N12, Globals );
		float Output_N13 = 0.0; Node13_Is_Greater( InstanceID_N12, NF_PORT_CONSTANT( float( 0.0 ), Port_Input1_N013 ), Output_N13, Globals );
		
		Bool1 = Output_N13;
	}
	if ( bool( Bool1 * 1.0 != 0.0 ) )
	{
		/* Input port: "Value1"  */
		
		{
			float Output_N1 = 0.0; Node1_Float_Parameter( Output_N1, Globals );
			float Output_N18 = 0.0; Node18_Abs( Output_N1, Output_N18, Globals );
			float Output_N17 = 0.0; Node17_Multiply( Output_N18, NF_PORT_CONSTANT( float( 0.5 ), Port_Input1_N017 ), Output_N17, Globals );
			
			Value1 = Output_N17;
		}
		Result = Value1;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float Output_N1 = 0.0; Node1_Float_Parameter( Output_N1, Globals );
			float Output_N18 = 0.0; Node18_Abs( Output_N1, Output_N18, Globals );
			
			Default = Output_N18;
		}
		Result = Default;
	}
}
#define Node11_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * float3(Input1)
#define Node9_Add( Input0, Input1, Output, Globals ) Output = Input0 + Input1
#define Node2_Transform_Vector( VectorIn, VectorOut, Globals ) VectorOut = ( ngsModelMatrix * float4( VectorIn.xyz, 1.0 ) ).xyz

//-----------------------------------------------------------------------

void main() 
{
	
	
	NF_SETUP_PREVIEW_VERTEX()
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	sc_Vertex_t v;
	ngsVertexShaderBegin( v );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssGlobals Globals;	
	Globals.gTimeElapsed = ( overrideTimeEnabled == 1 ) ? overrideTimeElapsed : sc_TimeElapsed;
	Globals.gTimeDelta   = ( overrideTimeEnabled == 1 ) ? overrideTimeDelta : sc_TimeDelta;
	Globals.SurfacePosition_ObjectSpace = ( ngsModelMatrixInverse * float4( varPos, 1.0 ) ).xyz;
	Globals.VertexNormal_WorldSpace     = varNormal;
	Globals.VertexNormal_ObjectSpace    = normalize( ( ngsModelMatrixInverse * float4( Globals.VertexNormal_WorldSpace, 0.0 ) ).xyz );
	Globals.gInstanceID                 = float( sc_LocalInstanceID );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	float4 ScreenPosition = vec4( 0.0 );
	float3 WorldPosition  = varPos;
	float3 WorldNormal    = varNormal;
	float3 WorldTangent   = varTangent.xyz;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	/* Input port: 'WorldPosition'  */
	
	{
		float3 Position_N8 = float3(0.0); Node8_Surface_Position( Position_N8, Globals );
		float3 Result_N19 = float3(0.0); Node19_If_else( float( 0.0 ), float3( 0.0, 0.0, 0.0 ), float3( 0.0, 0.0, 0.0 ), Result_N19, Globals );
		float3 Output_N10 = float3(0.0); Node10_Normalize( Result_N19, Output_N10, Globals );
		float Result_N14 = 0.0; Node14_If_else( float( 0.0 ), float( 0.0 ), float( 0.0 ), Result_N14, Globals );
		float3 Output_N11 = float3(0.0); Node11_Multiply( Output_N10, Result_N14, Output_N11, Globals );
		float3 Output_N9 = float3(0.0); Node9_Add( Position_N8, Output_N11, Output_N9, Globals );
		float3 VectorOut_N2 = float3(0.0); Node2_Transform_Vector( Output_N9, VectorOut_N2, Globals );
		
		WorldPosition = VectorOut_N2;
	}
	/* Input port: 'WorldNormal'  */
	
	{
		float3 Result_N19 = float3(0.0); Node19_If_else( float( 0.0 ), float3( 0.0, 0.0, 0.0 ), float3( 0.0, 0.0, 0.0 ), Result_N19, Globals );
		
		WorldNormal = Result_N19;
	}
	
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
	
	Interpolator_gInstanceID = Globals.gInstanceID;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	NF_PREVIEW_OUTPUT_VERTEX()
}

//-----------------------------------------------------------------------

#endif // #ifdef VERTEX_SHADER

//-----------------------------------------------------------------------

#ifdef FRAGMENT_SHADER

//-----------------------------------------------------------------------------

//----------

// Interpolators

varying float Interpolator_gInstanceID;	

//----------

// Globals

struct ssGlobals
{
	float gTimeElapsed;
	float gTimeDelta;
	float gTimeElapsedShifted;
	
	float gInstanceID;
	float gFrontFacing;
};

ssGlobals tempGlobals;
#define scCustomCodeUniform	

//----------

// Functions

#define Node12_Instance_ID( InstanceID, Globals ) InstanceID = floor( Globals.gInstanceID + 0.5 )
#define Node13_Is_Greater( Input0, Input1, Output, Globals ) Output = ssLarger( Input0, Input1 )
void Node1_Float_Parameter( out float Output, ssGlobals Globals ) { Output = lineWeight; }
#define Node16_Is_Less( Input0, Input1, Output, Globals ) Output = ssSmaller( Input0, Input1 )
#define Node21_Is_Front_Facing( FrontFacing, Globals ) FrontFacing = Globals.gFrontFacing
#define Node24_Is_Equal( Input0, Input1, Output, Globals ) Output = ssEqual( Input0, Input1 )
void Node23_If_else( in float Bool1, in float4 Value1, in float4 Default, out float4 Result, ssGlobals Globals )
{ 
	/* Input port: "Bool1"  */
	
	{
		float Output_N1 = 0.0; Node1_Float_Parameter( Output_N1, Globals );
		float Output_N16 = 0.0; Node16_Is_Less( Output_N1, NF_PORT_CONSTANT( float( 0.0 ), Port_Input1_N016 ), Output_N16, Globals );
		
		Bool1 = Output_N16;
	}
	if ( bool( Bool1 * 1.0 != 0.0 ) )
	{
		/* Input port: "Value1"  */
		
		{
			float FrontFacing_N21 = 0.0; Node21_Is_Front_Facing( FrontFacing_N21, Globals );
			float Output_N24 = 0.0; Node24_Is_Equal( FrontFacing_N21, NF_PORT_CONSTANT( float( 0.0 ), Port_Input1_N024 ), Output_N24, Globals );
			
			Value1 = float4( Output_N24 );
		}
		Result = Value1;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float FrontFacing_N21 = 0.0; Node21_Is_Front_Facing( FrontFacing_N21, Globals );
			
			Default = float4( FrontFacing_N21 );
		}
		Result = Default;
	}
}
void Node5_Color_Parameter( out float4 Output, ssGlobals Globals ) { Output = lineColor; }
void Node22_If_else( in float Bool1, in float4 Value1, in float4 Default, out float4 Result, ssGlobals Globals )
{ 
	/* Input port: "Bool1"  */
	
	{
		float4 Result_N23 = float4(0.0); Node23_If_else( float( 0.0 ), float4( 0.0, 0.0, 0.0, 0.0 ), float4( 0.0, 0.0, 0.0, 0.0 ), Result_N23, Globals );
		
		Bool1 = Result_N23.x;
	}
	if ( bool( Bool1 * 1.0 != 0.0 ) )
	{
		
		Result = Value1;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float4 Output_N5 = float4(0.0); Node5_Color_Parameter( Output_N5, Globals );
			
			Default = Output_N5;
		}
		Result = Default;
	}
}
void Node15_If_else( in float Bool1, in float4 Value1, in float4 Default, out float4 Result, ssGlobals Globals )
{ 
	/* Input port: "Bool1"  */
	
	{
		float InstanceID_N12 = 0.0; Node12_Instance_ID( InstanceID_N12, Globals );
		float Output_N13 = 0.0; Node13_Is_Greater( InstanceID_N12, NF_PORT_CONSTANT( float( 0.0 ), Port_Input1_N013 ), Output_N13, Globals );
		
		Bool1 = Output_N13;
	}
	if ( bool( Bool1 * 1.0 != 0.0 ) )
	{
		
		Result = Value1;
	}
	else
	{
		/* Input port: "Default"  */
		
		{
			float4 Result_N22 = float4(0.0); Node22_If_else( float( 0.0 ), NF_PORT_CONSTANT( float4( 0.0, 0.0, 0.0, 0.0 ), Port_Value1_N022 ), float4( 0.0, 0.0, 0.0, 0.0 ), Result_N22, Globals );
			
			Default = Result_N22;
		}
		Result = Default;
	}
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
	
	
	{
		Globals.gInstanceID  = Interpolator_gInstanceID;
		
		#ifdef               FRAGMENT_SHADER
		Globals.gFrontFacing = ( sc_GetGlFrontFacing() ) ? 1.0 : 0.0;
		#else
		Globals.gFrontFacing = 0.0;
		#endif
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	/* Input port: 'FinalColor'  */
	
	{
		float4 Result_N15 = float4(0.0); Node15_If_else( float( 0.0 ), NF_PORT_CONSTANT( float4( 0.0, 0.0, 0.0, 1.0 ), Port_Value1_N015 ), float4( 1.0, 0.0, 0.0, 1.0 ), Result_N15, Globals );
		
		FinalColor = Result_N15;
	}
	ngsAlphaTest( FinalColor.a );
	
	
	
	
	
	
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
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
