#version $GLSL_VERSION_STR

#pragma vp_name       Phong Lighting Vertex Stage
#pragma vp_entryPoint oe_phong_vertex
#pragma vp_location   vertex_view


out vec3 oe_phong_vertexView3;

void oe_phong_vertex(inout vec4 VertexVIEW)
{
    oe_phong_vertexView3 = VertexVIEW.xyz / VertexVIEW.w;
}
