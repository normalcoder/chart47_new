#include <metal_stdlib>
#include <metal_texture>
#include <simd/simd.h>
#import "ShaderTypes.h"

using namespace metal;

struct VertexOut {
    float4 pos[[position]];
    float4 color;
};

float3x3 translate(float2 c) {
    return {{1, 0, 0}, {0, 1, 0}, {c.x, c.y, 1}};
}

float3x3 rot(float phi) {
    return {{cos(phi), sin(phi), 0}, {-sin(phi), cos(phi), 0}, {0, 0, 1}};
}

float3x3 scale(float s) {
    return {{s, 0, 0}, {0, s, 0}, {0, 0, 1}};
}

float3 conv2to3(float2 p) {
    return (float3){p.x, p.y, 1};
}

float2 conv3to2(float3 p) {
    return (float2){p.x, p.y};
}

//float2 rotateAndScalePoint(float2 p, float2 c, float d, float phi) {
//    return conv3to2(translate(c) * scale(d / distance(c,p)) * rot(phi) * translate(-c) * conv2to3(p));
//}

float2 circlePoint(float2 c, float d, float phi) {
    return (float2){c.x + d*cos(phi), c.y + d*sin(phi)};
}

float2 rotateAndScalePoint(float2 p, float2 c, float d, float phi) {
    float a = atan2(p.y - c.y, p.x - c.x);
    float b = phi + a;
//    return circlePoint(c, d, a + phi);
    return (float2){c.x + d*cos(b), c.y + d*sin(b)};
}


float2 circlePointI(float2 c, float d, float a, float alpha, float humpSign, float i) {
    return circlePoint(c, d, a + humpSign*(M_PI_2_F - i*alpha/3));
}

//float2 instersect(float2 a, float2 b, float2 c, float2 d) {
//
//}

vertex VertexOut piece_vertex(constant Piece *allParams[[buffer(0)]],
                               constant GlobalParameters &globalParams[[buffer(1)]],
                               uint vertexId [[vertex_id]], // 0 ..< elementsPerInstance
                               uint instanceId [[instance_id]])
{
    VertexOut vo;
    Piece params = allParams[instanceId];
    float3x3 modelView = globalParams.modelView;
    float3x3 viewScale = globalParams.viewScale;
    float3x3 frame = globalParams.frame;
    float3x3 verticalFrame = globalParams.verticalFrame;
    float lineWidth = globalParams.lineWidth;
    float w = lineWidth/2;
//    float2 p1 = params.p1;
//    float2 p2 = params.p2;
//    float2 p3 = params.p3;
    float2 p1 = conv3to2(verticalFrame * frame * viewScale * conv2to3(params.p1));
    float2 p2 = conv3to2(verticalFrame * frame * viewScale * conv2to3(params.p2));
    float2 p3 = conv3to2(verticalFrame * frame * viewScale * conv2to3(params.p3));


    
    float2 p12 = (p1 + p2)/2;
    float2 p23 = (p2 + p3)/2;

    float tanA = (p2.y - p1.y)/(p2.x - p1.x);
    float tanB = (p3.y - p2.y)/(p3.x - p2.x);
    float a = atan2(p2.y - p1.y, p2.x - p1.x);
    float b = atan2(p3.y - p2.y, p3.x - p2.x);

    float humpSign = normalize((float2){tanA - tanB, 0}).x;

    float beta = M_PI_F + humpSign*(b - a);
    float alpha = M_PI_F - beta;
    
    float2 c = circlePoint(p2, w/sin(beta/2), a + humpSign*(M_PI_F + beta/2));
//    if (humpSign > 0) {
//        c.y = max(max(c.y, p12.y), p23.y);
//    } else {
//        c.y = min(min(c.y, p12.y), p23.y);
//    }

    float2 q1 = rotateAndScalePoint(p2, p12, w, -humpSign*M_PI_2_F);
    float2 q2 = rotateAndScalePoint(p2, p12, w, humpSign*M_PI_2_F);
    float2 q3 = rotateAndScalePoint(p2, p23, w, humpSign*M_PI_2_F);
    float2 q4 = rotateAndScalePoint(p2, p23, w, -humpSign*M_PI_2_F);
    
    float2 s0 = circlePointI(p2, w, a, alpha, humpSign, 0);
    float2 s1 = circlePointI(p2, w, a, alpha, humpSign, 1);
    float2 s2 = circlePointI(p2, w, a, alpha, humpSign, 2);
    float2 s3 = circlePointI(p2, w, a, alpha, humpSign, 3);
    
//    float2 s0_1 = (float2){p2.x - w/cos(beta), p2.y};
//    float2 s3_1 = (float2){p2.x + w/cos(beta), p2.y};

//    float2 r;
//    if (humpSign > 0) {
//        if (c.y < p12.y || c.y < p23.y) {
//            if (p12.y < p23.y) {
//                c.y = max(max(c.y, p12.y), p23.y);
//            } else {
//                c.y = max(max(c.y, p12.y), p23.y);
//            }
//        }
//    } else {
//        if (c.y > p12.y || c.y > p23.y) {
//            if (p12.y > p23.y) {
//                c.y = min(min(c.y, p12.y), p23.y);
//            } else {
////                c.y = min(min(c.y, p12.y), p23.y);
//                c.y = q1.y;
//            }
//        }
//    }
//    if (humpSign > 0) {
//        c.y = max(max(c.y, p12.y), p23.y);
//    } else {
//        c.y = min(min(c.y, p12.y), p23.y);
//    }

//    if (humpSign > 0) {
//        if (c.y < p12.y || c.y < p23.y) {
//            if (p12.y < p23.y) {
//                c = s3_1;
//
////                r = instersect(c, q4, q1, q3);
//
//            } else {
//                c = s0_1;
//            }
//        }
//    } else {
//        if (c.y > p12.y || c.y > p23.y) {
//            if (p12.y > p23.y) {
//                c = s3_1;
//            } else {
//                c = s0_1;
//            }
//        }
//    }

//    float2 vs[] = {q1, q2, c, s0, c, s1, c, s2, c, s3, q3, q4};
//    float2 vs[] = {q2, q1, s0, s3, s1, s2, q3, s3, s0, q4, q3};
    
//    if (humpSign > 0) {
//        if (c.y < p12.y || c.y < p23.y) {
//            if (p12.y < p23.y) {
//                float2 vs[] = {q2, q1, s0, s3, s1, s2, q3, s3, s0, q4, q3, q3};
//                vo.pos.xy = vs[vertexId];
////                c.y = max(max(c.y, p12.y), p23.y);
//            } else {
//                float2 vs[] = {q2, q1, s0, s3, s1, s2, q3, s3, s0, q4, q3, q3};
//                vo.pos.xy = vs[vertexId];
////                c.y = max(max(c.y, p12.y), p23.y);
//            }
//        } else {
//            float2 vs[] = {q1, q2, c, s0, c, s1, c, s2, c, s3, q3, q4};
//            vo.pos.xy = vs[vertexId];
//
//        }
//    } else {
//        if (c.y > p12.y || c.y > p23.y) {
//            if (p12.y > p23.y) {
//                float2 vs[] = {q2, q1, s0, s3, s1, s2, q3, s3, s0, q4, q3, q3};
//                vo.pos.xy = vs[vertexId];
////                c.y = min(min(c.y, p12.y), p23.y);
//            } else {
//                float2 vs[] = {q2, q1, s0, s3, s1, s2, q3, s3, s0, q4, q3, q3};
//                vo.pos.xy = vs[vertexId];
//                //                c.y = min(min(c.y, p12.y), p23.y);
////                c.y = q1.y;
//            }
//        } else {
//            float2 vs[] = {q1, q2, c, s0, c, s1, c, s2, c, s3, q3, q4};
//            vo.pos.xy = vs[vertexId];
//
//        }
//    }
    
    if (beta < M_PI_4_F) {
        float2 vs[] = {q2, q1, s0, s3, s1, s2, q3, s3, s0, q4, q3, q3};
        vo.pos.xy = vs[vertexId];
    } else {
        float2 vs[] = {q1, q2, c, s0, c, s1, c, s2, c, s3, q3, q4};
        vo.pos.xy = vs[vertexId];
    }



//    if (tanB < tanA) { // hump
//        float beta = M_PI_F + humpSign*(b - a);
//        float alpha = M_PI_F - beta;
//
//        float2 c = circlePoint(p2, w/sin(beta/2), a + humpSign*(M_PI_F + beta/2));
//
//        if (vertexId == 0) { // q1
//            vo.pos.xy = rotateAndScalePoint(p2, p12, w, -humpSign*M_PI_2_F);
//        } else if (vertexId == 1) { // q2
//            vo.pos.xy = rotateAndScalePoint(p2, p12, w, humpSign*M_PI_2_F);
//        } else if (vertexId == 2) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 3) { // s1
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 0);
//        } else if (vertexId == 4) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 5) { // s2
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 1);
//        } else if (vertexId == 6) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 7) { // s3
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 2);
//        } else if (vertexId == 8) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 9) { // s4
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 3);
//        } else if (vertexId == 10) { // q3
//            vo.pos.xy = rotateAndScalePoint(p2, p23, w, humpSign*M_PI_2_F);
//        } else { // vertexId == 11 // q4
//            vo.pos.xy = rotateAndScalePoint(p2, p23, w, -humpSign*M_PI_2_F);
//        }
//    } else {
//        float beta = M_PI_F + humpSign*(b - a);
//        float alpha = M_PI_F - beta;
//
//        float2 c = circlePoint(p2, w/sin(beta/2), a + humpSign*(M_PI_F + beta/2));
//
//        if (vertexId == 0) { // q1
//            vo.pos.xy = rotateAndScalePoint(p2, p12, w, -humpSign*M_PI_2_F);
//        } else if (vertexId == 1) { // q2
//            vo.pos.xy = rotateAndScalePoint(p2, p12, w, humpSign*M_PI_2_F);
//        } else if (vertexId == 2) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 3) { // s1
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 0);
//        } else if (vertexId == 4) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 5) { // s2
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 1);
//        } else if (vertexId == 6) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 7) { // s3
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 2);
//        } else if (vertexId == 8) { // c
//            vo.pos.xy = c;
//        } else if (vertexId == 9) { // s4
//            vo.pos.xy = circlePointI(p2, w, a, alpha, humpSign, 3);
//        } else if (vertexId == 10) { // q3
//            vo.pos.xy = rotateAndScalePoint(p2, p23, w, humpSign*M_PI_2_F);
//        } else { // vertexId == 11 // q4
//            vo.pos.xy = rotateAndScalePoint(p2, p23, w, -humpSign*M_PI_2_F);
//        }
//    }
    
    
//    // TO DO: Is there no way to ask Metal to give us vertexes per instances?
//    float t = (float) vertexId / globalParams.elementsPerInstance;
//
////    Piece params = allParams[instanceId];
//
//    // This is a little trick to avoid conditional code. We need to determine which side of the
//    // triangle we are processing, so as to calculate the correct "side" of the curve, so we just
//    // check for odd vs. even vertexId values to determine that:
//    float lineWidth = (1 - (((float) (vertexId % 2)) * 2.0)) * params.lineThickness;
//
////    float2 a = params.a;
////    float2 b = params.b;
//
//    // We premultiply several values though I doubt it actually does anything performance-wise:
//    float2 p1 = params.p1 * 3.0;
//    float2 p2 = params.p2 * 3.0;
//
//    float nt = 1.0f - t;
//
//    float nt_2 = nt * nt;
//    float nt_3 = nt_2 * nt;
//
//    float t_2 = t * t;
//    float t_3 = t_2 * t;
//
//    // Calculate a single point in this Bezier curve:
//    float2 point = a * nt_3 + p1 * nt_2 * t + p2 * nt * t_2 + b * t_3;
//
//    // Calculate the tangent so we can produce a triangle (to achieve a line width greater than 1):
//    float2 tangent = -3.0 * a * nt_2 + p1 * (1.0 - 4.0 * t + 3.0 * t_2) + p2 * (2.0 * t - 3.0 * t_2) + 3 * b * t_2;
//
//    tangent = normalize(float2(-tangent.y, tangent.x));
//
//
//    // Combine the point with the tangent and lineWidth to achieve a properly oriented
//    // triangle for this point in the curve:
//    vo.pos.xy = point + (tangent * (lineWidth / 2.0f));
//
////    1000.0f /params.size.x
////    1000/params.size.y
////    vo.pos.xy = float2(vo.pos.xy.x * 1, vo.pos.xy.y * 0.2);
    
//    if (vertexId == 0) { // q1
//        vo.pos.xy = p1;
//    } else if (vertexId == 1) { // q2
//        vo.pos.xy = p2;
//    } else { // c
//        vo.pos.xy = p3;
//    }
    
//    vo.pos.xy = conv3to2(modelView * viewScale * conv2to3(vo.pos.xy));
    vo.pos.xy = conv3to2(modelView * conv2to3(vo.pos.xy));
    vo.pos.zw = float2(0, 1);
    vo.color = params.color;
    
    return vo;
}

//fragment half4 piece_fragment(VertexOut params[[stage_in]])
//{
//    return half4(params.color);
//}


fragment float4 piece_fragment(VertexOut inVertex [[stage_in]])
{
    return inVertex.color;
}
