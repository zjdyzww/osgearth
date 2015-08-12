#version 330 compatibility

#pragma vp_name       "REX Engine - Morphing"
#pragma vp_entryPoint "oe_rexEngine_morph"
#pragma vp_location   "vertex_model"
#pragma vp_order      "0.5"
#pragma vp_define     "OE_REX_VERTEX_MORPHING"

// stage
vec3 vp_Normal; // up vector

vec4 oe_layer_texc;
vec4 oe_layer_tilec;

out float oe_rex_morphFactor;

uniform sampler2D oe_tile_elevationTex;
uniform mat4      oe_tile_elevationTexMatrix;
uniform vec4	  oe_tile_morph_constants;
uniform vec4	  oe_tile_grid_dimensions;
uniform vec4	  oe_tile_key;
uniform vec4	  oe_tile_extents;


// replaced at installation fine; see vp_define
#define OE_REX_VERTEX_MORPHING


// Morphs a vertex using a morphing factor.
void oe_rex_MorphVertex(inout vec3 vPositionMorphed, inout vec2 vUVMorphed, vec3 vPositionOriginal, vec2 vUVOriginal, float fMorphLerpK, vec2 vTileScale, vec3 vTangent, vec3 vBinormal)
{
   vec2 fFractionalPart = fract( vUVOriginal.xy * vec2(oe_tile_grid_dimensions.y, oe_tile_grid_dimensions.y) ) * vec2(oe_tile_grid_dimensions.z, oe_tile_grid_dimensions.z);
   vUVMorphed = vUVOriginal - (fFractionalPart * fMorphLerpK);

   vUVMorphed = clamp(vUVMorphed, 0, 1);

   vec2 dudv = vUVMorphed - vUVOriginal;

   vPositionMorphed.xyz = vPositionOriginal.xyz + normalize(vTangent)*dudv.x*vTileScale.x + normalize(vBinormal)*dudv.y*vTileScale.y;   
}


// Compute a morphing factor based on model-space inputs:
float oe_rex_ComputeMorphFactor(in vec4 position, in vec3 up, in vec3 tangent)
{
    // Find the "would be" position of the vertex (the position the vertex would
    // assume with no morphing)
	vec4 wouldBePosition = position;

	#ifdef OE_REX_VERTEX_MORPHING
	    vec4 elevc = oe_tile_elevationTexMatrix * oe_layer_tilec;
	    float elev = textureLod(oe_tile_elevationTex, elevc.st,0).r;
		wouldBePosition.xyz += up*elev;
	#endif

    vec4 wouldBePositionView = gl_ModelViewMatrix * wouldBePosition;

    float fDistanceToEye = length(wouldBePositionView.xyz); // or just -z.
	float fMorphLerpK  = 1.0f - clamp( oe_tile_morph_constants.z - fDistanceToEye * oe_tile_morph_constants.w, 0.0, 1.0 );
    return fMorphLerpK;
}


void oe_rexEngine_morph(inout vec4 vertexModel)
{
    vec3 tangent = gl_MultiTexCoord1.xyz;
    
    // compute the morphing factor to send down the pipe.
    oe_rex_morphFactor = oe_rex_ComputeMorphFactor(vertexModel, vp_Normal, tangent);
    
#ifdef OE_REX_VERTEX_MORPHING
    // We use tangent space morphing only on higher res grids.
	// The lod at and beyond which this tangent space morphing is
	// done is encoded in oe_tile_grid_dimensions.w
	if (oe_tile_key.z > oe_tile_grid_dimensions.w)
	{
		vec3 vPositionMorphed;
		vec2 vUVMorphed;

		oe_rex_MorphVertex(
                    vPositionMorphed
                  , vUVMorphed
				  , vertexModel.xyz
                  , oe_layer_tilec.xy
				  , oe_rex_morphFactor
				  , oe_tile_extents.xy
				  , tangent
                  , cross(vp_Normal, tangent) );

        vertexModel.xyz = vPositionMorphed.xyz;

        // apply the elevation:
        oe_layer_tilec.st = vUVMorphed;
	}
#endif
}

