// Old watch (RT). Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/MlyyzW
//
// A simple path tracer is used to render an old watch. The old watch scene is
// (almost) the same scene as rendered using image based lighting in my shader "Old
// watch (IBL)":
// 
// https://www.shadertoy.com/view/lscBW4
//
// I'm no expert in ray- or path-tracing so there are probably a lot of errors in this code.
//

#define PATH_LENGTH 5

vec3 getBGColor( vec3 N ) {
    if (N.y <= 0.) {
        return vec3(0.); 
    } else {
	    return (.25 + pow(textureLod(iChannel0, N, 0.).rgb, vec3(6.5)) * 8.5) * (N.y) * .3;
    }
}

float FresnelSchlickRoughness(float cosTheta, float F0, float roughness) {
    return F0 + (max((1. - roughness), F0) - F0) * pow(abs(1. - cosTheta), 5.0);
}

vec3 cosWeightedRandomHemisphereDirection( const vec3 n, inout float seed ) {
  	vec2 r = hash2(seed);
    
	vec3  uu = normalize(cross(n, abs(n.y) > .5 ? vec3(1.,0.,0.) : vec3(0.,1.,0.)));
	vec3  vv = cross(uu, n);
	
	float ra = sqrt(r.y);
	float rx = ra*cos(6.2831*r.x); 
	float ry = ra*sin(6.2831*r.x);
	float rz = sqrt( abs(1.0-r.y) );
	vec3  rr = vec3( rx*uu + ry*vv + rz*n );
    
    return normalize(rr);
}

vec3 modifyDirectionWithRoughness( const vec3 n, const float roughness, inout float seed ) {
  	vec2 r = hash2(seed);
    
	vec3  uu = normalize(cross(n, abs(n.y) > .5 ? vec3(1.,0.,0.) : vec3(0.,1.,0.)));
	vec3  vv = cross(uu, n);
	
    float a = roughness*roughness;
    a *= a; a *= a; // I want to have a really shiny watch.
	float rz = sqrt(abs((1.0-r.y) / clamp(1.+(a - 1.)*r.y,.00001,1.)));
	float ra = sqrt(abs(1.-rz*rz));
	float rx = ra*cos(6.2831*r.x); 
	float ry = ra*sin(6.2831*r.x);
	vec3  rr = vec3( rx*uu + ry*vv + rz*n );
    
    return normalize(rr);
}

vec2 randomInUnitDisk(inout float seed) {
    vec2 h = hash2(seed) * vec2(1.,6.28318530718);
    float phi = h.y;
    float r = sqrt(h.x);
	return r*vec2(sin(phi),cos(phi));
}

//
// main 
//

vec3 render( in vec3 ro, in vec3 rd, inout float seed ) {
    vec3 col = vec3(1.); 
    vec3 firstPos = vec3(100.);
    bool firstHit = false;
    
    for (int i=0; i<PATH_LENGTH; ++i) {    
    	vec2 res = castRay( ro, rd );
		float gd = castRayGlass( ro, rd );
        
		vec3 gpos = ro + rd * gd;
		vec3 gN = calcNormalGlass(gpos);
        
        if (gd > 0. && (res.x < 0. || gd < res.x) && dot(gN, rd) < 0.) {
            // Glass material. 
            // Not correct: I only handle rays that enter the glass and the glass
            // is modelled as one solid piece, instead as a thin layer. By using a
            // non-physically plausible refraction index of 1.25, it still looks
            // good (I think).
            float F = FresnelSchlickRoughness(max(0., dot(-gN, rd)), (0.08), 0.);
            if (F < hash1(seed)) {
                rd = refract(rd, gN, 1./1.25);
            } else {
                rd = reflect(rd, gN);
            }
            ro = gpos;
        }
        else if (res.x > 0.) {
			vec3 pos = ro + rd * res.x;
			vec3 N, albedo;
            float roughness, metallic;

			getMaterialProperties(pos, res.y, N, albedo, roughness, metallic, iChannel1, iChannel2, iChannel3);

            float F = FresnelSchlickRoughness(max(0., -dot(N, rd)), 0.04, roughness);
            
            ro = pos;
            if (F > hash1(seed) - metallic) { // Reflections and metals.
                if (metallic > .5) {
                    col *= albedo; 
                }
				rd = modifyDirectionWithRoughness(reflect(rd,N), roughness, seed);            
                if (dot(rd, N) <= 0.) {
                    rd = cosWeightedRandomHemisphereDirection(N, seed);
                }
            } else { // Diffuse
				col *= albedo;
				rd = cosWeightedRandomHemisphereDirection(N, seed);
            }
        } else {
            col *= getBGColor(rd);
			col *= max(0.0, min(1.1, 10./dot(firstPos,firstPos)) - .15);
			return col;
        }            
        if (!firstHit) {
            firstHit = true;
            firstPos = ro;
        }
    }  
    return vec3(0.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    bool reset = iFrame == 0;
    ivec2 f = ivec2(fragCoord);
    vec4 data1 = texelFetch(iChannel3, ivec2(0), 0);
    vec4 data2 = texelFetch(iChannel2, ivec2(0), 0);
    
    vec2 uv = fragCoord/iResolution.xy;
    vec2 mo = abs(iMouse.xy)/iResolution.xy - .5;
    if (iMouse.xy == vec2(0)) mo = vec2(.05,.1);
    
    if (floor(mo*iResolution.xy*10.) != data1.yz) {
        reset = true;
    }
    if (data2.xy != iResolution.xy) {
        reset = true;
    }
    
    TIME = data2.w;
    
    float a = 5.05;
    vec3 ro = vec3( .25+ 2.*cos(6.0*mo.x+a), 2. + 2. * mo.y, 2.0*sin(6.0*mo.x+a) );
    vec3 ta = vec3( .25, .5, 0.0 );
    mat3 ca = setCamera( ro, ta );

    float fpd = data1.x;
    if(all(equal(f, ivec2(0)))) {
        // Calculate focus plane and store distance.
        float nfpd = castRay(ro, normalize(vec3(0.,.2,0.)-ro)).x;
		fragColor = vec4(nfpd, floor(mo*iResolution.xy*10.), iResolution.x);
        return;
    }
    
    vec2 p = (-iResolution.xy + 2.0*fragCoord - 1.)/iResolution.y;
    float seed = float(baseHash(floatBitsToUint(p)))/float(0xffffffffU) + iTime;

    // AA
	p += 2.*hash2(seed)/iResolution.y;
    vec3 rd = ca * normalize( vec3(p.xy,1.6) );  
    
    // DOF
    vec3 fp = ro + rd * fpd;
    ro = ro + ca * vec3(randomInUnitDisk(seed), 0.)*.02;
    rd = normalize(fp - ro);
    
    vec3 col = render(ro, rd, seed);           
  
    if (reset) {
       fragColor = vec4(col, 1.0);
    } else {
       fragColor = vec4(col, 1.0) + texelFetch(iChannel3, ivec2(fragCoord), 0);
    }
}
