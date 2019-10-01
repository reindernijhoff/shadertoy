// [SH17C] Raymarching tutorial. Created by Reinder Nijhoff 2017
// @reindernijhoff
// 
// https://www.shadertoy.com/view/4dSfRc
//
// In this tutorial you will learn how to render a 3d-scene in Shadertoy
// using distance fields.
//
// The tutorial itself is created in Shadertoy, and is rendered
// using ray marching a distance field.
//
// The shader studied in the tutorial can be found here: 
//     https://www.shadertoy.com/view/4dSBz3
//
// Created for the Shadertoy Competition 2017 
//
// Most of the render code is taken from: 'Raymarching - Primitives' by Inigo Quilez.
//
// You can find this shader here:
//     https://www.shadertoy.com/view/Xds3zN
//

// RENDER SCENE


// Load & store functions

#define SLIDE_FADE_STEPS 60

int SLIDE = 0;
int SLIDE_STEPS_VISIBLE = 0;
int SCENE_MODE = 0;
int DIST_MODE = 0;
int MAX_MARCH_STEPS;

vec3 intersections[7];
vec3 intersectionNormal;

float aspect;
vec3 USER_INTERSECT;

ivec4 LoadVec4( in ivec2 vAddr ) {
    return ivec4( texelFetch( iChannel0, vAddr, 0 ) );
}

vec4 LoadFVec4( in ivec2 vAddr ) {
    return texelFetch( iChannel0, vAddr, 0 );
}

bool AtAddress( ivec2 p, ivec2 c ) { return all( equal( floor(vec2(p)), vec2(c) ) ); }

void StoreVec4( in ivec2 vAddr, in ivec4 vValue, inout vec4 fragColor, in ivec2 fragCoord ) {
    fragColor = AtAddress( fragCoord, vAddr ) ? vec4(vValue) : fragColor;
}

void loadData() {
    ivec4 slideData = LoadVec4( ivec2(0,0) );
    SLIDE = slideData.x;
    SLIDE_STEPS_VISIBLE = slideData.y;
    SCENE_MODE = slideData.z;
	DIST_MODE = slideData.w;
}


// tutorial Scene
float tut_map(vec3 p) {
    float d = distance(p, vec3(-1, 0, -5)) - 1.;
    d = min(d, distance(p, vec3(2, 0, -3)) - 1.);
    d = min(d, distance(p, vec3(-2, 0, -2)) - 1.);
    d = min(d, p.y + 1.);
    return d;
}

vec3 tut_calcNormal(in vec3 pos) {
    vec2 e = vec2(1.0, -1.0) * 0.0005;
    return normalize(
        e.xyy * tut_map(pos + e.xyy) +
        e.yyx * tut_map(pos + e.yyx) +
        e.yxy * tut_map(pos + e.yxy) +
        e.xxx * tut_map(pos + e.xxx));
}

vec4 tut_render(in vec2 uv, const int steps) {
    vec3 ro = vec3(0, 0, 1);
    vec3 rd = normalize(vec3(uv, 0.) - ro);

    float h, t = 1.;
    for (int i = 0; i < steps; i++) {
        h = tut_map((ro + rd * t));
        t += h;
        if (h < 0.01) break;
    }

    if (h < 0.01) {
        vec3 p = ro + rd * t;
        vec3 normal = tut_calcNormal(p);
        vec3 light = vec3(0, 2, 0);

        float dif = clamp(dot(normal, normalize(light - p)), 0., 1.);
        dif *= 5. / dot(light - p, light - p);
        return vec4(pow(vec3(dif), vec3(1. / 2.2)), 1);
    } else {
        return vec4(0, 0, 0, 1);
    }
}

//
// render full scene
//
// Most of this is taken from: 'Raymarching - Primitives' by Inigo Quilez.
//
// You can find this shader here:
//     https://www.shadertoy.com/view/Xds3zN
//

//------------------------------------------------------------------

float sdPlane( vec3 p, float d ) {
	return p.y - d;
}

float sdSphere( vec3 p, float s ) {
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

//------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 ) {
	return (d1.x<d2.x) ? d1 : d2;
}

//------------------------------------------------------------------

vec2 map_0( in vec3 pos ) { // basic scene
    vec2 res = opU( vec2( sdPlane(     pos, -1.), 1.0 ),
	                vec2( sdSphere(    pos-vec3(-1,0,-5),1.), 50. ) );
    res = opU( res, vec2( sdSphere(    pos-vec3(2,0,-3),1.), 65. ) );
    res = opU( res, vec2( sdSphere(    pos-vec3(-2,0,-2),1.),41. ) );
        
    return res;
}

vec2 map_1( in vec3 pos ) { // scene + ro
    vec2 res = map_0(pos);
    res = opU( res, vec2( sdSphere(    pos-vec3(0,0,1),.1),2. ) );
    return res;
}

vec2 map_2( in vec3 pos ) { // scene + ro + screen
    vec2 res = map_0(pos);
            
    res = opU( res, vec2( sdSphere(    pos-vec3(0,0,1),.1),3. ) );
    res = opU( res, vec2( sdBox( pos,  vec3(.5*aspect, .5,.025)), 4.));
    return res;
}

vec2 map_3( in vec3 pos ) { // scene + ro + rd + intersection
    vec2 res = map_2(pos);
    
    res = opU( res, vec2( sdSphere(     pos-USER_INTERSECT,.1),2. ) );
    res = opU( res, vec2( sdCapsule(    pos, vec3(0,0,1.), USER_INTERSECT,.025),2. ) );
    
    return res;
}

vec2 map_4( in vec3 pos ) { // scene + ro + one sphere
    vec2 res = opU( vec2( sdPlane(     pos, -1.), 1.0 ),
	                vec2( sdSphere(    pos-vec3(-1,0,-5),1.), 50. ) );
    
    res = opU( res, vec2( sdSphere(    pos-vec3(0,0,1),.1),3. ) );
    res = opU( res, vec2( sdBox( pos,  vec3(.5*aspect, .5,.025)), 4.));
    
    return res;
}

vec2 map_5( in vec3 pos ) { // scene + ro + screen + march steps
    vec2 res = map_2(pos);
    
    res = opU( res, vec2( sdCapsule(    pos, vec3(0,0,1.), USER_INTERSECT,.025),3. ) );
    for( int i=0; i<intersections.length(); i++ ){
        if (i <= MAX_MARCH_STEPS) {
	    	res = opU( res, vec2( sdSphere( pos-intersections[i],.1), (i==MAX_MARCH_STEPS)?2.:3. ) );
        }
    }
    
    return res;
}

vec2 map_6( in vec3 pos ) { // scene + ro + rd + intersection + normal
    vec2 res = map_2(pos);
    
    res = opU( res, vec2( sdSphere(     pos-USER_INTERSECT,.1),3. ) );
    res = opU( res, vec2( sdCapsule(    pos, USER_INTERSECT + intersectionNormal, USER_INTERSECT,.025),2. ) );
    
    res = opU( res, vec2( sdCapsule(    pos, vec3(0,0,1.), USER_INTERSECT,.025),3. ) );
    return res;
}


vec2 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = .5;
    float tmax = 20.0;
       
    float t = tmin;
    float m = -1.0;

    if( SCENE_MODE == 0 ) {
        for( int i=0; i<64; i++ )
        {
            float precis = 0.00005*t;
            vec2 res = map_0( ro+rd*t );
            if( res.x<precis || t>tmax ) break;
            t += res.x;
            m = res.y;
        }
    } else if( SCENE_MODE == 1 ) {
        for( int i=0; i<64; i++ )
        {
            float precis = 0.00005*t;
            vec2 res = map_1( ro+rd*t );
            if( res.x<precis || t>tmax ) break;
            t += res.x;
            m = res.y;
        }
    } else if( SCENE_MODE == 2 ) {
        for( int i=0; i<64; i++ )
        {
            float precis = 0.00005*t;
            vec2 res = map_2( ro+rd*t );
            if( res.x<precis || t>tmax ) break;
            t += res.x;
            m = res.y;
        }
    } else if( SCENE_MODE == 3 ) {
        for( int i=0; i<64; i++ )
        {
            float precis = 0.00005*t;
            vec2 res = map_3( ro+rd*t );
            if( res.x<precis || t>tmax ) break;
            t += res.x;
            m = res.y;
        }
    } else if( SCENE_MODE == 4 ) {
        for( int i=0; i<64; i++ )
        {
            float precis = 0.00005*t;
            vec2 res = map_4( ro+rd*t );
            if( res.x<precis || t>tmax ) break;
            t += res.x;
            m = res.y;
        }
    } else if( SCENE_MODE == 5 ) {
        for( int i=0; i<64; i++ )
        {
            float precis = 0.00005*t;
            vec2 res = map_5( ro+rd*t );
            if( res.x<precis || t>tmax ) break;
            t += res.x;
            m = res.y;
        }
    }  else if( SCENE_MODE == 6 ) {
        for( int i=0; i<64; i++ )
        {
            float precis = 0.00005*t;
            vec2 res = map_6( ro+rd*t );
            if( res.x<precis || t>tmax ) break;
            t += res.x;
            m = res.y;
        }
    } 

    if( t>tmax ) m=-1.0;
    return vec2( t, m );
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
	float res = 1.0;
    float t = mint, h;
    for( int i=0; i<16; i++ )
    {
        
	    if( SCENE_MODE == 0 ) {
			h = map_0( ro + rd*t ).x;
    	} else if( SCENE_MODE == 1 ) {
			h = map_1( ro + rd*t ).x;
    	} else if( SCENE_MODE == 2 ) {
			h = map_2( ro + rd*t ).x;
   		} else if( SCENE_MODE == 3 ) {
			h = map_3( ro + rd*t ).x;
   		} else if( SCENE_MODE == 4 ) {
			h = map_4( ro + rd*t ).x;
   		} else if( SCENE_MODE == 5 ) {
			h = map_5( ro + rd*t ).x;
   		} else if( SCENE_MODE == 6 ) {
			h = map_6( ro + rd*t ).x;
   		}
        
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    
    if( SCENE_MODE == 0 ) {
 	   return normalize( e.xyy*map_0( pos + e.xyy ).x + 
					  e.yyx*map_0( pos + e.yyx ).x + 
					  e.yxy*map_0( pos + e.yxy ).x + 
					  e.xxx*map_0( pos + e.xxx ).x );
    } else if( SCENE_MODE == 1 ) {
            return normalize( e.xyy*map_1( pos + e.xyy ).x + 
					  e.yyx*map_1( pos + e.yyx ).x + 
					  e.yxy*map_1( pos + e.yxy ).x + 
					  e.xxx*map_1( pos + e.xxx ).x );
    } else if( SCENE_MODE == 2 ) {
            return normalize( e.xyy*map_2( pos + e.xyy ).x + 
					  e.yyx*map_2( pos + e.yyx ).x + 
					  e.yxy*map_2( pos + e.yxy ).x + 
					  e.xxx*map_2( pos + e.xxx ).x );
    } else if( SCENE_MODE == 3 ) {
            return normalize( e.xyy*map_3( pos + e.xyy ).x + 
					  e.yyx*map_3( pos + e.yyx ).x + 
					  e.yxy*map_3( pos + e.yxy ).x + 
					  e.xxx*map_3( pos + e.xxx ).x );
    } else if( SCENE_MODE == 4 ) {
            return normalize( e.xyy*map_4( pos + e.xyy ).x + 
					  e.yyx*map_4( pos + e.yyx ).x + 
					  e.yxy*map_4( pos + e.yxy ).x + 
					  e.xxx*map_4( pos + e.xxx ).x );
    } else if( SCENE_MODE == 5 ) {
            return normalize( e.xyy*map_5( pos + e.xyy ).x + 
					  e.yyx*map_5( pos + e.yyx ).x + 
					  e.yxy*map_5( pos + e.yxy ).x + 
					  e.xxx*map_5( pos + e.xxx ).x );
    } else if( SCENE_MODE == 6 ) {
            return normalize( e.xyy*map_6( pos + e.xyy ).x + 
					  e.yyx*map_6( pos + e.yyx ).x + 
					  e.yxy*map_6( pos + e.yxy ).x + 
					  e.xxx*map_6( pos + e.xxx ).x );
    }
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0, dd;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
	    if( SCENE_MODE == 0 ) {
			dd = map_0( aopos ).x;
    	} else if( SCENE_MODE == 1 ) {
			dd = map_1( aopos ).x;
    	} else if( SCENE_MODE == 2 ) {
			dd = map_2( aopos ).x;
   		} else if( SCENE_MODE == 3 ) {
			dd = map_3( aopos ).x;
   		} else if( SCENE_MODE == 4 ) {
			dd = map_4( aopos ).x;
   		} else if( SCENE_MODE == 5 ) {
			dd = map_5( aopos ).x;
   		} else if( SCENE_MODE == 6 ) {
			dd = map_6( aopos ).x;
   		}
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.75,0.9,1.0) + max(rd.y*.8,0.);
    vec2 res = castRay(ro,rd);
    float t = res.x;
	float m = res.y;
    if( m>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
		col = 0.45 + 0.35*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        if( m<1.5 ) {            
            float f = mod( floor(1.0*pos.z) + floor(1.0*pos.x), 2.0);
            col = 0.35 + 0.05*f*vec3(1.0);
        } else if (m < 2.5 ) {
            col = vec3(.5 + .3*sin(iTime*6.28318530718 ),0,0);
        } else if (m < 3.5 ) {
            col = vec3(.8,0,0);
        } else if (m < 4.5 ) {
            col = tut_render(pos.xy, 64).rgb;
        }

        // lighitng        
        float occ = calcAO( pos, nor );
		vec3  lig = normalize( vec3(0.4, 0.7, 0.6) );
		float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
		float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);
        
        dif *= softshadow( pos, lig, 0.02, 2.5 );
        dom *= softshadow( pos, ref, 0.02, 2.5 );

		vec3 lin = vec3(0.0);
        lin += 1.30*dif*vec3(1.00,0.80,0.55);
		lin += 2.00*spe*vec3(1.00,0.90,0.70)*dif;
        lin += 0.40*amb*vec3(0.40,0.60,1.00)*occ;
        lin += 0.50*dom*vec3(0.40,0.60,1.00)*occ;
        lin += 0.50*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
		col = col*lin;

        
        if( DIST_MODE > 0 ) {
            // intersect with plane;
            float d = -(ro.y)/rd.y;
            vec3 dint = ro + d*rd;
            
            float m = sdSphere(dint-vec3(-1,0,-5),1.);
            
            if( DIST_MODE > 1 ) { 
                m = min( m, sdSphere(dint-vec3(2,0,-3),1.));
                m = min( m, sdSphere(dint-vec3(-2,0,-2),1.));
            }
            if( DIST_MODE > 2 ) { 
                m = min( m, dint.y + 1.);
            }
            vec3 dcol = vec3(abs(mod(m, 0.1)/0.1 - 0.5));
            dcol = mix( dcol, pal( m*.115+.6, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) ), .7);
            
            if( SCENE_MODE == 5) {
                for( int i=0; i<intersections.length(); i++ ){
                    if (i<MAX_MARCH_STEPS) {
                        float dti = distance(intersections[i], dint);
                        float mai = map_0(intersections[i]).x;
                        float outer = smoothstep( mai-0.15, mai, dti);
                        dcol = mix( dcol, vec3(1,0,0), .3*smoothstep( mai+0.01, mai, dti)*(outer+1.) );
                    }
                }            
            }
            if( d < t ) {
                col = mix(col, dcol, .6);
            }
        }
        
    	col = mix( col, vec3(0.75,0.9,1.0), .05+.95* smoothstep(10.,20.,t) );
    }

	return vec3( clamp(col,0.0,1.0) );
}

vec3 calcNormal_0( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    
    return normalize( e.xyy*map_0( pos + e.xyy ).x + 
					  e.yyx*map_0( pos + e.yyx ).x + 
					  e.yxy*map_0( pos + e.yxy ).x + 
					  e.xxx*map_0( pos + e.xxx ).x );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


vec3 renderScene( vec2 p, vec3 ro, vec3 ta ) {
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    // ray direction
    vec3 rd = ca * normalize( vec3(p.xy,1.0) );
    // render	
    vec3 col = render( ro, rd );
    
    return col;
}


void initIntersecions( in vec3 ro, in vec3 rd ) {
    float t = 1.;
    
    for( int i=0; i<intersections.length(); i++ ){
        vec2 res = map_0( ro+rd*t );
        t += res.x;
        intersections[i] = ro + rd*t;
    }
}

//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 q = (fragCoord.xy - .5 * iResolution.xy ) / iResolution.y;
    
    aspect = iResolution.x/iResolution.y;
    
    loadData();
    
    if(SCENE_MODE == -1) {
        fragColor = tut_render(q, 96);
    } else {
        vec3 ro = LoadFVec4( ivec2(0,3) ).xyz;
        vec3 ta = LoadFVec4( ivec2(0,4) ).xyz;
        USER_INTERSECT = LoadFVec4( ivec2(0,5) ).xyz;
        
        if( SCENE_MODE == 5 ) {
            MAX_MARCH_STEPS = min(max(int( SLIDE_STEPS_VISIBLE/40-1),0), intersections.length()-1);
            
            initIntersecions(vec3(0,0,1), normalize(USER_INTERSECT - vec3(0,0,1)) );
            for (int i=0; i<intersections.length(); i++) {
                if (i<MAX_MARCH_STEPS+1) {
            		USER_INTERSECT = intersections[i];
                }
            }
        }
        if( SCENE_MODE == 6 ) {
            intersectionNormal = calcNormal_0(USER_INTERSECT) * .5;
        }
        
        fragColor = vec4(renderScene(q, ro, ta),1);
    }
}