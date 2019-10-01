// [SH18] Human Document. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XtcyW4
//
//   * Created for the Shadertoy Competition 2018 *
//
// Buffer B: The BRDF integration map used for the IBL and the drawing of the humanoid 
//           are precalculated.
//

const float PI = 3.14159265359;

// see: http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
float PartialGeometryGGX(float NdotV, float a) {
    float k = a / 2.0;

    float nominator   = NdotV;
    float denominator = NdotV * (1.0 - k) + k;

    return nominator / denominator;
}

float GeometryGGX_Smith(float NdotV, float NdotL, float roughness) {
    float a = roughness*roughness;
    float G1 = PartialGeometryGGX(NdotV, a);
    float G2 = PartialGeometryGGX(NdotL, a);
    return G1 * G2;
}

float RadicalInverse_VdC(uint bits) {
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}

vec2 Hammersley(int i, int N) {
    return vec2(float(i)/float(N), RadicalInverse_VdC(uint(i)));
} 

vec3 ImportanceSampleGGX(vec2 Xi, float roughness) {
    float a = roughness*roughness;
    float phi      = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

    vec3 HTangent;
    HTangent.x = sinTheta*cos(phi);
    HTangent.y = sinTheta*sin(phi);
    HTangent.z = cosTheta;

    return HTangent;
}

vec2 IntegrateBRDF(float roughness, float NdotV) {
    vec3 V;
    V.x = sqrt(1.0 - NdotV*NdotV);
    V.y = 0.0;
    V.z = NdotV;

    float A = 0.0;
    float B = 0.0;

    const int SAMPLE_COUNT = 128;

    vec3 N = vec3(0.0, 0.0, 1.0);
    vec3 UpVector = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 TangentX = normalize(cross(UpVector, N));
    vec3 TangentY = cross(N, TangentX);

    for(int i = 0; i < SAMPLE_COUNT; ++i)  {
        vec2 Xi = Hammersley(i, SAMPLE_COUNT);
        vec3 HTangent = ImportanceSampleGGX(Xi, roughness);
        
        vec3 H = normalize(HTangent.x * TangentX + HTangent.y * TangentY + HTangent.z * N);
        vec3 L = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(L.z, 0.0);
        float NdotH = max(H.z, 0.0);
        float VdotH = max(dot(V, H), 0.0);

        if(NdotL > 0.0) {
            float G = GeometryGGX_Smith(NdotV, NdotL, roughness);
            float G_Vis = (G * VdotH) / (NdotH * NdotV);
            float Fc = pow(1.0 - VdotH, 5.0);

            A += (1.0 - Fc) * G_Vis;
            B += Fc * G_Vis;
        }
    }
    A /= float(SAMPLE_COUNT);
    B /= float(SAMPLE_COUNT);
    return vec2(A, B);
}

//
// draw paper
//


vec3 getSpherePosition(int i) {
    if (i==LEFT_LEG_1) return vec3(-.15, 0, -1.6);
    if (i==RIGHT_LEG_1) return vec3(.5, 0, -1.6);
    
    if (i==LEFT_LEG_2) return vec3(-.3, 0, -.75);
    if (i==RIGHT_LEG_2) return vec3(.3, 0, -.75);
    
    if (i==LEFT_LEG_3) return vec3(-.12, 0, .15);
    if (i==RIGHT_LEG_3) return vec3(.1, 0, .15);
        
    if (i==HEAD) return vec3(0., 0, 1.65);
    if (i==SPINE) return vec3(0., 0, 1.1);
    
    if (i==LEFT_ARM_3) return vec3(-.3, 0, 1.15);
    if (i==RIGHT_ARM_3) return vec3(.3, 0, 1.15);
    
    if (i==LEFT_ARM_2) return vec3(-.55, 0, .7);
    if (i==RIGHT_ARM_2) return vec3(.55, 0, .7);
    
    if (i==LEFT_ARM_1) return vec3(-.75, 0, 0.2);
    if (i==RIGHT_ARM_1) return vec3(.95,0,  0.4);
    
    return vec3(0);
}

float mapBody( in vec3 pos ) {
    float r = .15;
    float s = 80.1;

    vec3 p1 = getSpherePosition(LEFT_LEG_1);
    vec3 p2 = getSpherePosition(LEFT_LEG_2);
    float d = sdCapsule(pos, p1, p2, r, r*.5);
    vec2 res = vec2(d, MAT_PAPER);

    p1 = getSpherePosition(LEFT_LEG_3);
    d = sdCapsule(pos, p1, p2, r, r*.5);
    res.x = smin(res.x, d, s);

    p1 = getSpherePosition(RIGHT_LEG_1);
    p2 = getSpherePosition(RIGHT_LEG_2);
    d = sdCapsule(pos, p1, p2, r, r*.5);
    res.x = smin(res.x, d, s);

    p1 = getSpherePosition(RIGHT_LEG_3);
    d = sdCapsule(pos, p1, p2, r, r*.5);
    res.x = smin(res.x, d, s);

    p1 = getSpherePosition(RIGHT_LEG_3);
    p2 = getSpherePosition(SPINE);
    d = sdCapsule(pos, p1, p2, r, r);
    res.x = smin(res.x, d, s);

    p1 = getSpherePosition(LEFT_LEG_3);
    d = sdCapsule(pos, p1, p2, r, r);
    res.x = smin(res.x, d, s);

    p1 = getSpherePosition(RIGHT_ARM_1);
    p2 = getSpherePosition(RIGHT_ARM_2);
    d = sdCapsule(pos, p1, p2, r*.5, r*.25);
    res.x = smin(res.x, d, s);

    p1 = getSpherePosition(RIGHT_ARM_3);
    d = sdCapsule(pos, p1, p2, r*.5, r*.25);
    res.x = smin(res.x, d, s);

    p1 = getSpherePosition(LEFT_ARM_1);
    p2 = getSpherePosition(LEFT_ARM_2);
    d = sdCapsule(pos, p1, p2, r*.5, r*.25);
    res.x = smin(res.x, d, s); 

    p1 = getSpherePosition(LEFT_ARM_3);
    d = sdCapsule(pos, p1, p2, r*.5, r*.25);
    res.x = smin(res.x, d, s);    

    return res.x;
}

vec2 drawPaper(vec2 uv) {
    float structure = 1.-texture(iChannel1, uv.yx).x;
    vec3 muv = vec3(uv.y-.5, 0., uv.x-.5)*4.;
    muv.x *= PAPER_SIZE.x / PAPER_SIZE.y;
    muv *= 2.75;
    muv.xz += vec2(.5,2.6) + .05*(texture(iChannel1, uv.yx*2.).xz-.5);
    muv.y = 0.;
    float drawing = smoothstep(.04,.03,abs(mapBody(muv))) * (.25+.75*structure);
    
    return vec2(structure, 1.-drawing);
}

bool resolutionChanged() {
    return iFrame == 0 
        || floor(texelFetch(iChannel0, ivec2(0), 0).r) != floor(iResolution.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    if(resolutionChanged() && iChannelResolution[1].x > 0.) {
        vec2 uv = fragCoord / iResolution.xy;
        vec2 integratedBRDF = IntegrateBRDF(uv.y, uv.x);
        vec2 paper = drawPaper(uv);
        fragColor = vec4(integratedBRDF, paper);
        
        if (fragCoord.x < 1.5 && fragCoord.y < 1.5) {
            fragColor.xy = floor(iResolution.xy);
        }
    } else {
        fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    }
}