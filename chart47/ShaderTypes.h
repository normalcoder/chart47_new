#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef struct {
    vector_float2 p1;
    vector_float2 p2;
    vector_float2 p3;
    vector_float4 color;
} Piece;

typedef struct {
    int elementsPerInstance;
    matrix_float3x3 modelView;
    matrix_float3x3 viewScale;
    matrix_float3x3 frame;
    matrix_float3x3 verticalFrame;
    float lineWidth;
} GlobalParameters;

#endif /* ShaderTypes_h */
