// [SH18] Human Document. Created by Reinder Nijhoff 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/XtcyW4
//
//   * Created for the Shadertoy Competition 2018 *
//
// 07/29/2018 I have made some optimizations and bugfixes, so I could enable AA. 
// 
//            !! Please change AA (line 47) to 1 if your framerate is below 60 
//               (or if you're running the shader fullscreen).
//
// This shader uses motion capture data to animate a humanoid. The animation data is
// compressed by storing only a fraction of the coeffecients of the Fourier transform
// of the positions of the bones (Buffer A). An inverse Fourier transform is used to 
// reconstruct the data needed.
// 
// Image Based Lighting (IBL) is used to render the scene. Have a look at my shader 
// "Old watch (IBL)" (https://www.shadertoy.com/view/lscBW4) for a clean implementation
// of IBL.
// 
// Buffer A: I have preprocessed a (motion captured) animation by taking the Fourier 
//           transform of the position of all bones (14 bones, 760 frames). Only a fraction 
//           of all calculated coefficients are stored in this shader: the first 
//           coefficients with 16 bit precision, later coefficients with 8 bit. The positions
//           of the bones are reconstructed each frame by taking the inverse Fourier
//           transform of this data.
//
//           I have used (part of) an animation from the Carnegie Mellon University Motion 
//           Capture Database. The animations of this database are free to use:
//
//           - http://mocap.cs.cmu.edu/
// 
//           Íñigo Quílez has created some excellent shaders that show the properties of 
//           Fourier transforms, for example: 
//
//           - https://www.shadertoy.com/view/4lGSDw
//           - https://www.shadertoy.com/view/ltKSWD
//
// Buffer B: The BRDF integration map used for the IBL and the drawing of the humanoid 
//           are precalculated.
//
// Buffer C: Additional custom animation of the bones is calculated for the start
//           and end of the loop.
//

#define MAX_LOD 8.
#define DIFFUSE_LOD 6.75
#define AA 2              // Please change to 1 if your framerate is below 60
#define MARCH_STEPS 40

vec3 getSpherePosition(int i) {
    return texelFetch(iChannel2, ivec2(0,i), 0 ).xyz;
}

float mapBody( in vec3 pos ) {
    float r = .1;
    float s = 80.;

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

vec2 map( in vec3 pos, bool spInt, bool pencilIntersect ) {
	// table
    vec2 res = vec2(pos.y + 0.01, MAT_TABLE);
    
    //--- paper
    float dP = pos.y;    
    if( spInt ) {   	 
        // smin with paper
        dP = smin(dP, mapBody(pos), 12.);
    }
    dP = opS(-sdBox(pos, vec3(PAPER_SIZE.x,10.,PAPER_SIZE.y)),dP);
    if (dP<res.x) { res = vec2(dP, MAT_PAPER); }
    
    // head
    float d = sdSphere(pos, vec4(getSpherePosition(HEAD),.1));
    if (d<res.x) { res = vec2(d, MAT_METAL_0); }
    
    //--- pencil
    if (pencilIntersect) {
        vec3 pen = pos;
        pen.xz = mat2(0.581683089463883,-0.813415504789374,
                      0.813415504789374, 0.581683089463883)*pen.xz;
        pen += PENCIL_POS;
        float dPencil0 = sdHexPrism(pen, vec2(.2, 2.));
        dPencil0 = opS(-sdCone(pen + (vec3(-2.05,0,0)), vec2(.95,0.3122)),dPencil0);
        dPencil0 = opS(sdSphere(pen + (vec3(-2.5,-0.82,2.86)), 3.), dPencil0);
        if (dPencil0 < res.x) res = vec2(dPencil0, MAT_PENCIL_0);

        float dPencil1 = sdCapsule(pen, - vec3(2.2,0.,0.), -vec3(2.55, 0., 0.), .21);
        if (dPencil1 < res.x) res = vec2(dPencil1, MAT_PENCIL_1);
        float ax = abs(-2.25 - pen.x );
        float r = .02*abs(2.*fract(30.*pen.x)-1.)*smoothstep(.08,.09,ax)*smoothstep(.21,.2,ax);

        float dPencil2 = sdCylinderZY(pen + vec3(2.25,-0.0125,0), vec2(.22 - r,.25));
        if (dPencil2 < res.x) res = vec2(dPencil2, MAT_PENCIL_2);
    }
 	return res;   
}

vec3 calcNormal( in vec3 pos ) {
    bool sphInt = distance(pos,getSpherePosition(LEFT_LEG_3)) <  1.25 ? true : false;
    vec3 ropen = pos;
    ropen.xz = rotate(ropen.xz, PENCIL_ROT);
    ropen += PENCIL_POS;
    bool pencilIntersect = sdBox(ropen, vec3(3.,.4,.4)) < 0.;
    
    const vec2 e = vec2(1.0,-1.0)*0.01;
    return normalize( e.xyy*map( pos + e.xyy, sphInt, pencilIntersect ).x + 
					  e.yyx*map( pos + e.yyx, sphInt, pencilIntersect ).x + 
					  e.yxy*map( pos + e.yxy, sphInt, pencilIntersect ).x + 
					  e.xxx*map( pos + e.xxx, sphInt, pencilIntersect ).x );
}

vec2 castRay( in vec3 ro, in vec3 rd ) {
    float tmax = 20.;
    
    vec3 rdpen = rd, ropen = ro;
    rdpen.xz = rotate(rdpen.xz, PENCIL_ROT);
    ropen.xz = rotate(ropen.xz, PENCIL_ROT);
    ropen += PENCIL_POS;
    
    vec2 sphDist = sphIntersect(ro-getSpherePosition(LEFT_LEG_3), rd, 1.25);
    vec2 pencilDist = boxIntersect(ropen, rdpen, vec3(3.,.24,.24));
    vec2 headDist = sphIntersect(ro-getSpherePosition(HEAD), rd, .11);
    
    bool pencilIntersect = pencilDist.x > 0.;
    bool sphInt = sphDist.y > 0.;
        
    float tmin = planeIntersect(ro,rd,.01);
    if (sphInt) {
        tmin = min(tmin, max(sphDist.x, 0.1));
    }
    if (pencilIntersect) {
        tmin = min(tmin, max(pencilDist.x, 0.11));
    }
    if (headDist.x > 0.) {
        tmin = min(tmin, headDist.x);
    }
    
    float t = tmin;
    float mat = -1.;
    
    for( int i=0; i<MARCH_STEPS; i++ ) {
	    float precis = 0.00025*t;
	    vec2 res = map( ro+rd*t, sphInt, pencilIntersect );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
        mat = res.y;
    }

    if( t>tmax ) t=-1.0;
    return vec2(t, mat);
}

float calcAO( in vec3 ro, in vec3 rd ) {
	float occ = 0.0;
    float sca = 1.0;
    
    bool sphInt = sphIntersect(ro-getSpherePosition(LEFT_LEG_3), rd, 1.25).y > 0. ? true : false;
    vec3 ropen = ro;
    ropen.xz = rotate(ropen.xz, PENCIL_ROT);
    ropen += PENCIL_POS;
    bool pencilIntersect = sdBox(ropen, vec3(3.,.45,.45)) < 0.;
    
    for( int i=0; i<5; i++ ) {
        float h = 0.001 + 0.25*float(i)/4.0;
        float d = map( ro+rd*h, sphInt, pencilIntersect ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 1.5*occ, 0.0, 1.0 );    
}

void getMaterialProperties(
    in vec3 pos, in float mat,
    inout vec3 normal, inout vec3 albedo, inout float ao, inout float roughness, inout float metallic) {
    
    normal = calcNormal( pos );
    ao = calcAO(pos, normal);
    metallic = 0.;
    
    vec4 noise = texNoise(iChannel1, pos * .5, normal);
    float metalnoise = 1.- noise.r;
    metalnoise*=metalnoise;

    mat -= .5;
    
    vec3 penpos = pos;
    penpos.xz = rotate(penpos.xz, PENCIL_ROT);
    penpos += PENCIL_POS;
    
    if (mat < MAT_TABLE) {
        albedo = 0.8*pow(texture(iChannel1, rotate(pos.xz * .4 + .25, -.3)).rgb, 2.2*vec3(0.45,0.5,0.5));
        roughness = 0.95 - albedo.r * .6;
    }
    else if( mat < MAT_PENCIL_0 ) {
        if (length(penpos.yz) < 0.055) {
        	albedo = vec3(0.02);
        	roughness = .9;
        } else if(sdHexPrism(penpos, vec2(.195, 3.)) < 0.) {
        	albedo = .8* texture(iChannel1, penpos.xz).rgb;
        	roughness = 0.99;
        } else {
        	albedo = .5*pow(vec3(1.,.8,.15), vec3(2.2));
        	roughness = .75 - noise.b * .4;
        }
        albedo *= noise.g * .75 + .7;
    }
    else if( mat < MAT_PENCIL_1 ) {
       	albedo = .4*pow(vec3(.85,.75,.55), vec3(2.2));
       	roughness = 1.;
    }
    else if( mat < MAT_PENCIL_2 ) {
        float ax = abs(-2.25 - penpos.x);
        float r = 1. - abs(2.*fract(30.*penpos.x)-1.)*smoothstep(.08,.09,ax)*smoothstep(.21,.2,ax);

        r -= 4. * metalnoise;  
        ao *= .5 + .5 * r;
	    albedo = mix(vec3(0.5, 0.3, 0.2),vec3(0.560, 0.570, 0.580), ao * ao); // Iron
   		roughness = 1.-.25*r;
   		metallic = 1.; 
    }
    else if( mat < MAT_PAPER ) {
        vec2 paperUV = (pos.xz-PAPER_SIZE)/(PAPER_SIZE*2.)+1.;
        vec2 tex = texture(iChannel3, paperUV.yx).zw;
    	float line = abs(paperUV.x-.5) > .45 ? 0. : smoothstep(0.1, 0.025, abs(sin(paperUV.y*75.)));

        albedo = mix(vec3(.955 - .05*tex.x), vec3(.55,.65,.9), line);    	
        float figure = 1.-tex.y;
        float time = mod(offsetTime(iTime), DURATION_TOTAL);
        float start = 1.-smoothstep(DURATION_START-DURATION_MORPH_STILL, DURATION_START+DURATION_MORPH_ANIM, time);
        float end = smoothstep(DURATION_TOTAL-DURATION_MORPH, DURATION_TOTAL, time);
        figure *= max(start, end);
        
        albedo *= 1.-figure*.8;
        
       	roughness = .65 + .3 *tex.x;
        metallic = 0.;
    }
    else if( mat < MAT_METAL_0 ) {
	    albedo = vec3(1.000, 0.766, 0.336); // Gold
   		roughness = .6;
   		metallic = 1.; 
    }   
    if (metallic > .5) {   
        albedo *= 1.-metalnoise;
        roughness += metalnoise*4.;
    }
    
    ao = clamp(.2+.8*ao, 0., 1.);
    roughness = clamp(roughness, 0., 1.);
}

//
// Image based lighting
// See: Old watch (IBL)
// https://www.shadertoy.com/view/lscBW4
//
vec3 getSpecularLightColor( vec3 N, float roughness ) {
    return pow(textureLod(iChannel0, N, roughness * MAX_LOD).rgb, vec3(4.5)) * 6.5;
}
vec3 getDiffuseLightColor( vec3 N ) {
    return .25 +pow(textureLod(iChannel0, N, DIFFUSE_LOD).rgb, vec3(3.)) * 1.;
}
vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}
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
    vec3 color = (kD * diffuse + specular) * ao;

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

        getMaterialProperties(pos, res.y, N, albedo, ao, roughness, metallic);

        col = lighting(ro, pos, N, albedo, ao, roughness, metallic);
        col *= max(0.0, min(1.1, 20./dot(pos,pos)) - .1);
    }
    col = max( vec3(0), col - 0.004);
    col = (col*(6.2*col + .5)) / (col*(6.2*col+1.7) + 0.06);
    
    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta ) {
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(0.0, 1.0,0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    vec2 mo = iMouse.xy/iResolution.xy - .5;
    if(iMouse.w <= 0.) {
        mo = vec2( 0.06+.1*sin(iTime*.035), 0. );
    }
    vec3 ro = vec3( 4.*sin(6.0*mo.x), 3. * mo.y + 3.5, -5.5*cos(6.0*mo.x) );
    vec3 ta = vec3( 0.0, 0.5, 0.0 );
    mat3 ca = setCamera( ro, ta );

    vec3 colT = vec3(0);
    for (int x=0; x<AA; x++) {
        for(int y=0; y<AA; y++) {
		    vec2 p = (-iResolution.xy + 2.0*(fragCoord + vec2(x,y)/float(AA) - .5))/iResolution.y;
   			vec3 rd = ca * normalize(vec3(p.xy,2.3));  
            colT += render( ro, rd);           
        }
    }
    colT /= float(AA*AA);
    
    colT *= smoothstep(.5, 1.5, iTime);
    fragColor = vec4(colT, 1.0);
}