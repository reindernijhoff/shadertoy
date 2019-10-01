// Old watch (IBL). Created by Reinder Nijhoff 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/lscBW4
//
// This shader uses Image Based Lighting (IBL) to render an old watch. The
// materials of the objects have physically-based properties.
//
// A material is defined by its albedo and roughness value and it can be a 
// metal or a non-metal.
//
// I have used the IBL technique as explained in the article 'Real Shading in
// Unreal Engine 4' by Brian Karis of Epic Games.[1] According to this article,
// the lighting of a material is the sum of two components:
// 
// 1. Diffuse: a look-up (using the normal vector) in a pre-computed environment map.
// 2. Specular: a look-up (based on the reflection vector and the roughness of the
//       material) in a pre-computed environment map, combined with a look-up in a
//       pre-calculated BRDF integration map (Buf B).  
// 
// Note that I do NOT (pre)compute the environment maps needed in this shader. Instead,
// I use (the lod levels of) a Shadertoy cubemap that I have remapped using a random 
// function to get something HDR-ish. This is not correct and not how it is described
// in the article, but I think that for this scene the result is good enough.
//
// I made a shader that renders this same scene using a simple path tracer. You can
// compare the result here:
//
// https://www.shadertoy.com/view/MlyyzW
//
// [1] http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
//

#define MAX_LOD 8.
#define DIFFUSE_LOD 6.75
#define AA 2
// #define P_MALIN_AO 

vec3 getSpecularLightColor( vec3 N, float roughness ) {
    // This is not correct. You need to do a look up in a correctly pre-computed HDR environment map.
    return pow(textureLod(iChannel0, N, roughness * MAX_LOD).rgb, vec3(4.5)) * 6.5;
}

vec3 getDiffuseLightColor( vec3 N ) {
    // This is not correct. You need to do a look up in a correctly pre-computed HDR environment map.
    return .25 +pow(textureLod(iChannel0, N, DIFFUSE_LOD).rgb, vec3(3.)) * 1.;
}

//
// Modified FrenelSchlick: https://seblagarde.wordpress.com/2011/08/17/hello-world/
//
vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

//
// Image based lighting
//

vec3 lighting(in vec3 ro, in vec3 pos, in vec3 N, in vec3 albedo, in float ao, in float roughness, in float metallic ) {
    vec3 V = normalize(ro - pos); 
    vec3 R = reflect(-V, N);
    float NdotV = max(0.0, dot(N, V));

    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, albedo, metallic);

    vec3 F = FresnelSchlickRoughness(NdotV, F0, roughness);

    vec3 kS = F;

    vec3 prefilteredColor = getSpecularLightColor(R, roughness);
    vec2 envBRDF = texture(iChannel3, vec2(NdotV, roughness)).rg;
    vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

    vec3 kD = vec3(1.0) - kS;

    kD *= 1.0 - metallic;

    vec3 irradiance = getDiffuseLightColor(N);

    vec3 diffuse  = albedo * irradiance;

#ifdef P_MALIN_AO
    vec3 color = kD * diffuse * ao + specular * calcAO(pos, R);
#else
    vec3 color = (kD * diffuse + specular) * ao;
#endif

    return color;
}

//
// main 
//

vec3 render( const in vec3 ro, const in vec3 rd ) {
    vec3 col = vec3(0); 
    vec2 res = castRay( ro, rd );

    if (res.x > 0.) {
        vec3 pos = ro + rd * res.x;
        vec3 N, albedo;
        float roughness, metallic, ao;

        getMaterialProperties(pos, res.y, N, albedo, ao, roughness, metallic, iChannel1, iChannel2, iChannel3);

        col = lighting(ro, pos, N, albedo, ao, roughness, metallic);
        col *= max(0.0, min(1.1, 10./dot(pos,pos)) - .15);
    }

    // Glass. 
    float glass = castRayGlass( ro, rd );
    if (glass > 0. && (glass < res.x || res.x < 0.)) {
        vec3 N = calcNormalGlass(ro+rd*glass);
        vec3 pos = ro + rd * glass;

        vec3 V = normalize(ro - pos); 
        vec3 R = reflect(-V, N);
        float NdotV = max(0.0, dot(N, V));

        float roughness = texture(iChannel2, pos.xz*.5 + .5).g;

        vec3 F = FresnelSchlickRoughness(NdotV, vec3(.08), roughness);
        vec3 prefilteredColor = getSpecularLightColor(R, roughness);
        vec2 envBRDF = texture(iChannel3, vec2(NdotV, roughness)).rg;
        vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

        col = col * (1.0 -  (F * envBRDF.x + envBRDF.y) ) + specular;
    } 

    // gamma correction
    col = max( vec3(0), col - 0.004);
    col = (col*(6.2*col + .5)) / (col*(6.2*col+1.7) + 0.06);
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    vec2 mo = iMouse.xy/iResolution.xy - .5;
    if(iMouse.w <= 0.) {
        mo = vec2(.2*sin(-iTime*.1+.3)+.045,.1-.2*sin(-iTime*.1+.3));
    }
    float a = 5.05;
    vec3 ro = vec3( .25 + 2.*cos(6.0*mo.x+a), 2. + 2. * mo.y, 2.0*sin(6.0*mo.x+a) );
    vec3 ta = vec3( .25, .5, .0 );
    mat3 ca = setCamera( ro, ta );

    vec3 colT = vec3(0);
    
    for (int x=0; x<AA; x++) {
        for(int y=0; y<AA; y++) {
		    vec2 p = (-iResolution.xy + 2.0*(fragCoord + vec2(x,y)/float(AA) - .5))/iResolution.y;
   			vec3 rd = ca * normalize( vec3(p.xy,1.6) );  
            colT += render( ro, rd);           
        }
    }
    
    colT /= float(AA*AA);
    
    fragColor = vec4(colT, 1.0);
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 ro, in vec3 rd ) {
	MAX_T = 1000.;
    fragColor = vec4(render(ro * 25. + vec3(0.5,4.,1.5), rd), 1.);
}