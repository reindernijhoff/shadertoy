// [NV15] Space. Created by Reinder Nijhoff 2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/ltjGRz
//

#define SHOW_ASTEROIDS
//#define HIGH_QUALITY

const float PI = 3.14159265359;
const float DEG_TO_RAD = (PI / 180.0);
const float MAX = 10000.0;

const float EARTH_RADIUS = 1000.;
const float EARTH_ATMOSPHERE = 10.;
const float RING_INNER_RADIUS = 1500.;
const float RING_OUTER_RADIUS = 2300.;
const float RING_DETAIL_DISTANCE = 40.;
const float RING_HEIGHT = 2.;
const float RING_VOXEL_STEP_SIZE = .03;
const vec3  RING_COLOR_1 = vec3(0.42,0.3,0.2);
const vec3  RING_COLOR_2 = vec3(0.51,0.41,0.32) * 0.2;

const int   ASTEROID_NUM_STEPS = 10;
const float ASTEROID_TRESHOLD 	= 0.001;
const float ASTEROID_EPSILON 	= 1e-6;
const float ASTEROID_DISPLACEMENT = 0.1;

#ifdef HIGH_QUALITY
const int   RING_VOXEL_STEPS = 60;
const float ASTEROID_MAX_DISTANCE = 2.7; 
const float ASTEROID_RADIUS = 0.12;
#else
const int   RING_VOXEL_STEPS = 26;
const float ASTEROID_MAX_DISTANCE = 1.; // RING_VOXEL_STEPS * RING_VOXEL_STEP_SIZE
const float ASTEROID_RADIUS = 0.13;
#endif

const vec3  SUN_DIRECTION = vec3( .940721,  .28221626, .18814417 );
const vec3 SUN_COLOR = vec3(1.0, .7, .55)*.2;

//-----------------------------------------------------
// Noise functions
//-----------------------------------------------------

float hash( float n ) {
    return fract(sin(n)*43758.5453123);
}
float hash( vec2 p ) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}
float hash( vec3 p ) {
	float h = dot(p,vec3(127.1,311.7,758.5453123));	
    return fract(sin(h)*43758.5453123);
}
vec3 hash31(float p) {
	vec3 h = vec3(1275.231,4461.7,7182.423) * p;	
    return fract(sin(h)*43758.543123);
}
vec3 hash33( vec3 p) {
    return vec3( hash(p), hash(p.zyx), hash(p.yxz) );
}
float noise( in float p ) {    
    float i = floor( p );
    float f = fract( p );	
	float u = f*f*(3.0-2.0*f);
    return -1.0+2.0* mix( hash( i + 0. ), hash( i + 1. ), u);
}
float noise( in vec2 p ) {    
    vec2 i = floor( p );
    vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}
float noise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

const mat2 m2 = mat2( 0.80, -0.60, 0.60, 0.80 );

float fbm( vec2 p ) {
    float f = 0.0;
    f += 0.5000*noise( p ); p = m2*p*2.02;
    f += 0.2500*noise( p ); p = m2*p*2.03;
    f += 0.1250*noise( p ); p = m2*p*2.01;
    f += 0.0625*noise( p );
    
    return f/0.9375;
}

// fBm
float fbm3(vec3 p, float a, float f) {
    return noise(p);
}

float fbm3_high(vec3 p, float a, float f) {
    float ret = 0.0;    
    float amp = 1.0;
    float frq = 1.0;
    for(int i = 0; i < 4; i++) {
        float n = pow(noise(p * frq),2.0);
        ret += n * amp;
        frq *= f;
        amp *= a * (pow(n,0.2));
    }
    return ret;
}

//-----------------------------------------------------
// Lightning functions
//-----------------------------------------------------

float diffuse(vec3 n,vec3 l) { 
    return clamp(dot(n,l),0.,1.);
}

float specular(vec3 n,vec3 l,vec3 e,float s) {    
    float nrm = (s + 8.0) / (3.1415 * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

//-----------------------------------------------------
// Math functions
//-----------------------------------------------------

vec2 rotate(float angle, vec2 v) {
    return vec2(cos(angle) * v.x + sin(angle) * v.y, cos(angle) * v.y - sin(angle) * v.x);
}

float boolSub(float a,float b) { 
    return max(a,-b); 
}
float sphere(vec3 p,float r) {
	return length(p)-r;
}

//-----------------------------------------------------
// Intersection functions (by iq)
//-----------------------------------------------------

vec3 nSphere( in vec3 pos, in vec4 sph ) {
    return (pos-sph.xyz)/sph.w;
}

float iSphere( in vec3 ro, in vec3 rd, in vec4 sph ) {
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}

vec3 nPlane( in vec3 ro, in vec4 obj ) {
    return obj.xyz;
}

float iPlane( in vec3 ro, in vec3 rd, in vec4 pla ) {
    return (-pla.w - dot(pla.xyz,ro)) / dot( pla.xyz, rd );
}


//-----------------------------------------------------
// Wet stone by TDM
// 
// https://www.shadertoy.com/view/ldSSzV
//-----------------------------------------------------

float rock( const in vec3 p, const in vec3 id ) {  
    float d = sphere(p,ASTEROID_RADIUS);    
    for(int i = 0; i < 7; i++) {
        float ii = float(i)+id.x;
        float r = (ASTEROID_RADIUS*2.5) + ASTEROID_RADIUS*hash(ii);
        vec3 v = normalize(hash31(ii) * 2.0 - 1.0);
    	d = boolSub(d,sphere(p+v*r,r * 0.8));       
    }
    return d;
}

float map( const in vec3 p, const in vec3 id) {
    float d = rock(p, id) + fbm3(p*4.0,0.4,2.96) * ASTEROID_DISPLACEMENT;
    return d;
}

float map_detailed( const in vec3 p, const in vec3 id) {
    float d = rock(p, id) + fbm3_high(p*4.0,0.4,2.96) * ASTEROID_DISPLACEMENT;
    return d;
}

void asteroidTransForm(inout vec3 ro, const in vec3 id ) {
    float xyangle = (id.x-.5)*iTime*2.;
    ro.xy = rotate( xyangle, ro.xy );
    
    float yzangle = (id.y-.5)*iTime*2.;
    ro.yz = rotate( yzangle, ro.yz );
}
void asteroidUnTransForm(inout vec3 ro, const in vec3 id ) {
    float yzangle = (id.y-.5)*iTime*2.;
    ro.yz = rotate( -yzangle, ro.yz );

    float xyangle = (id.x-.5)*iTime*2.;
    ro.xy = rotate( -xyangle, ro.xy );  
}
// tracing
vec3 asteroidGetNormal(vec3 p, vec3 id) {
    asteroidTransForm( p, id );
    
    vec3 n;
    n.x = map_detailed(vec3(p.x+ASTEROID_EPSILON,p.y,p.z), id);
    n.y = map_detailed(vec3(p.x,p.y+ASTEROID_EPSILON,p.z), id);
    n.z = map_detailed(vec3(p.x,p.y,p.z+ASTEROID_EPSILON), id);
    n = normalize(n-map_detailed(p, id));
    
    asteroidUnTransForm( n, id );
    return n;
}

vec2 asteroidSpheretracing(vec3 ori, vec3 dir, vec3 id) {

    asteroidTransForm( ori, id );
    asteroidTransForm( dir, id );
    
    vec2 td = vec2(0.0);
    for(int i = 0; i < ASTEROID_NUM_STEPS; i++) {
        vec3 p = ori + dir * td.x;
        td.y = map(p, id);
        if(td.y < ASTEROID_TRESHOLD) break;
        td.x += (td.y-ASTEROID_TRESHOLD) * 0.9;
    }
    return td;
}

// stone
vec3 asteroidGetStoneColor(vec3 p, float c, vec3 l, vec3 n, vec3 e) {
   vec3 color = RING_COLOR_1;
        
	float fresnel = .5*pow(1.0-abs(dot(n,e)),5.);
    color = mix( diffuse(n,l)*color*SUN_COLOR, SUN_COLOR*specular(n,l,e,3.0),fresnel);    
    
    return color;
}


//-----------------------------------------------------
// Ring (by me ;))
//-----------------------------------------------------

vec3 ringShadowColor( const in vec3 ro ) {
    if( iSphere( ro, SUN_DIRECTION, vec4( 0., 0., 0., EARTH_RADIUS ) ) > 0. ) {
        return vec3(0.);
    }
    return vec3(1.);
}

bool ringMap( const in vec3 ro ) {
    return ro.z < RING_HEIGHT/RING_VOXEL_STEP_SIZE && hash(ro)<.5;
}

vec4 renderRingNear( const in vec3 ro, const in vec3 rd ) { 
// find startpoint 
    float d1 = iPlane( ro, rd, vec4( 0., 0., 1., RING_HEIGHT ) );
    float d2 = iPlane( ro, rd, vec4( 0., 0., 1., -RING_HEIGHT ) );
   
    if( d1 < 0. && d2 < 0. ) return vec4( 0. );
    
    float d = min( max(d1,0.), max(d2,0.) );
    
    if( d > ASTEROID_MAX_DISTANCE ) return vec4( 0. );
    
    vec3 ros = ro + rd*d;
    
    // avoid precision problems..
    vec2 mroxy = mod(ros.xy, vec2(5.));
    vec2 roxy = ros.xy - mroxy;
    ros.xy -= roxy;
    
    ros /= RING_VOXEL_STEP_SIZE;
    
	vec3 pos = floor(ros);
	vec3 ri = 1.0/rd;
	vec3 rs = sign(rd);
	vec3 dis = (pos-ros + 0.5 + rs*0.5) * ri;
	
    float alpha = 0., dint;
	vec3 offset = vec3(0.), id, asteroidro;
    vec2 asteroid;
    
	for( int i=0; i<RING_VOXEL_STEPS; i++ ) {
		if( ringMap(pos) ) {
            id = hash33(pos);
            offset = id*(1.-2.*ASTEROID_RADIUS)+ASTEROID_RADIUS;
            dint = iSphere( ros, rd, vec4(pos+offset, ASTEROID_RADIUS) );
            
#ifdef SHOW_ASTEROIDS   
            if( dint > 0. ) {
                asteroidro = ros+rd*dint-(pos+offset);
    	        asteroid = asteroidSpheretracing( asteroidro, rd, id );
				
                if( asteroid.y < .1 ) {
	                alpha = 1.;
        	    	break;	    
                }
            }
#else
        if( dint > 0. ) {
            alpha = 1.;
            break;	    
        }
#endif
        }
		vec3 mm = step(dis.xyz, dis.yxy) * step(dis.xyz, dis.zzx);
		dis += mm * rs * ri;
        pos += mm * rs;
	}
    
    if( alpha > 0. ) {
        
#ifdef SHOW_ASTEROIDS            
        vec3 intersection = ros + rd*(asteroid.x+dint);
        vec3 n = asteroidGetNormal( asteroidro + rd*asteroid.x, id );
#else
        vec3 intersection = ros + rd*dint;
        vec3 n = nSphere( intersection, vec4(pos+offset, ASTEROID_RADIUS) );     
#endif
        vec3 col = asteroidGetStoneColor(intersection, .1, SUN_DIRECTION, n, rd);

        intersection *= RING_VOXEL_STEP_SIZE;
        intersection.xy += roxy;
        col *= ringShadowColor( intersection );
         
	    return vec4( col, 1.-smoothstep(0.4*ASTEROID_MAX_DISTANCE, 0.5* ASTEROID_MAX_DISTANCE, distance( intersection, ro ) ) );
    }
    
	return vec4(0.);
}

//-----------------------------------------------------
// Ring (by me ;))
//-----------------------------------------------------

vec4 renderRingFar( const in vec3 ro, const in vec3 rd, inout float maxd ) {
    // intersect plane
    float d = iPlane( ro, rd, vec4( 0., 0., 1., 0.) );
    
    if( d > 0. && d < maxd ) {
        maxd = d;
	    vec3 intersection = ro + rd*d;
        float l = length(intersection.xy);
        
        if( l > RING_INNER_RADIUS && l < RING_OUTER_RADIUS ) {
            float dens = .5 + .5 * (.2+.8*noise( l*.07 )) * (.5+.5*noise(intersection.xy));
            vec3 col = mix( RING_COLOR_1, RING_COLOR_2, abs( noise(l*0.2) ) ) * abs(dens) * 1.5;
            
            col *= ringShadowColor( intersection );
    		col *= .8+.3*diffuse( vec3(0,0,1), SUN_DIRECTION );
			col *= SUN_COLOR;
            return vec4( col, dens );
        }
    }
    return vec4(0.);
}

vec4 renderRing( const in vec3 ro, const in vec3 rd, inout float maxd ) {
    vec4 far = renderRingFar( ro, rd, maxd );
	
    float l = length( ro.xy );
    
    // detail needed ?
    
    if( abs(ro.z) < RING_HEIGHT+RING_DETAIL_DISTANCE 
        && l < RING_OUTER_RADIUS+RING_DETAIL_DISTANCE 
        && l > RING_INNER_RADIUS-RING_DETAIL_DISTANCE ) {
     	
	    float d = iPlane( ro, rd, vec4( 0., 0., 1., 0.) );
        float detail = mix( .5 * noise( fract(ro.xy+rd.xy*d) * 92.1)+.25, 1., smoothstep( 0.,RING_DETAIL_DISTANCE, d) );
        far.xyz *= detail;    
    }
    
	// are asteroids neaded ?
    if( abs(ro.z) < RING_HEIGHT+ASTEROID_MAX_DISTANCE 
        && l < RING_OUTER_RADIUS+ASTEROID_MAX_DISTANCE 
        && l > RING_INNER_RADIUS-ASTEROID_MAX_DISTANCE ) {
        
        vec4 near = renderRingNear( ro, rd );
        far = mix( far, near, near.w );
        maxd=0.;
    }
    
    return far;
}

//-----------------------------------------------------
// Planet (by me ;))
//-----------------------------------------------------

vec4 renderStars( const in vec3 rd ) {
	vec3 rds = rd;
	vec3 col = vec3(0);
    float v = 1.0/( 2. * ( 1. + rds.z ) );
    
    vec2 xy = vec2(rds.y * v, rds.x * v);
    float s = noise(rds*134.);
 //   s += noise_3(rds*370.);
    s += noise(rds*470.);
    s = pow(s,19.0) * 0.00001;
    if (s > 0.5) {
        vec3 backStars = vec3(s)*.5 * vec3(0.95,0.8,0.9); 
        col += backStars;
    }
	return   vec4( col, 1 ); 
} 

//-----------------------------------------------------
// Planet (by me ;))
//-----------------------------------------------------

vec4 renderPlanet( const in vec3 ro, const in vec3 rd, inout float maxd ) {
    float d = iSphere( ro, rd, vec4( 0., 0., 0., EARTH_RADIUS ) );
                      
	if( d < 0. || d > maxd) {
        return vec4(0);
	}
    maxd = d;
    vec3 col = vec3( .2, 7., 4. ) * 0.4;
    
    col *= diffuse( normalize( ro+rd*d ), SUN_DIRECTION ) * SUN_COLOR;
                 
    float m = MAX;
    col *= (1. - renderRingFar( ro+rd*d, SUN_DIRECTION, m ).w );
    
 	return vec4( col, 1 ); 
}

//-----------------------------------------------------
// Atmospheric Scattering by GLtracy
// 
// https://www.shadertoy.com/view/lslXDr
//-----------------------------------------------------

// scatter const
const float K_R = 0.166;
const float K_M = 0.0025;
const float E = 14.3; 						// light intensity
const vec3  C_R = vec3( 0.3, 0.7, 1.0 ); 	// 1 / wavelength ^ 4
const float G_M = -0.85;					// Mie g

const float SCALE_H = 4.0 / ( EARTH_ATMOSPHERE );
const float SCALE_L = 1.0 / ( EARTH_ATMOSPHERE );

const int NUM_OUT_SCATTER = 8;
const float FNUM_OUT_SCATTER = 8.0;

const int NUM_IN_SCATTER = 8;
const float FNUM_IN_SCATTER = 8.0;


// ray intersects sphere
// e = -b +/- sqrt( b^2 - c )
vec2 ray_vs_sphere( vec3 p, vec3 dir, float r ) {
	float b = dot( p, dir );
	float c = dot( p, p ) - r * r;
	
	float d = b * b - c;
	if ( d < 0.0 ) {
		return vec2( MAX, -MAX );
	}
	d = sqrt( d );
	
	return vec2( -b - d, -b + d );
}

// Mie
// g : ( -0.75, -0.999 )
//      3 * ( 1 - g^2 )               1 + c^2
// F = ----------------- * -------------------------------
//      2 * ( 2 + g^2 )     ( 1 + g^2 - 2 * g * c )^(3/2)
float phase_mie( float g, float c, float cc ) {
	float gg = g * g;
	
	float a = ( 1.0 - gg ) * ( 1.0 + cc );

	float b = 1.0 + gg - 2.0 * g * c;
	b *= sqrt( b );
	b *= 2.0 + gg;	
	
	return 1.5 * a / b;
}

// Reyleigh
// g : 0
// F = 3/4 * ( 1 + c^2 )
float phase_reyleigh( float cc ) {
	return 0.75 * ( 1.0 + cc );
}

float density( vec3 p ){
	return exp( -( length( p ) - EARTH_RADIUS ) * SCALE_H );
}

float optic( vec3 p, vec3 q ) {
	vec3 step = ( q - p ) / FNUM_OUT_SCATTER;
	vec3 v = p + step * 0.5;
	
	float sum = 0.0;
	for ( int i = 0; i < NUM_OUT_SCATTER; i++ ) {
		sum += density( v );
		v += step;
	}
	sum *= length( step ) * SCALE_L;
	
	return sum;
}

vec4 in_scatter( vec3 o, vec3 dir, vec2 e, vec3 l ) {
	float len = ( e.y - e.x ) / FNUM_IN_SCATTER;
	vec3 step = dir * len;
	vec3 p = o + dir * e.x;
	vec3 v = p + dir * ( len * 0.5 );

    float sumdensity = 0.;
	vec3 sum = vec3( 0.0 );

    for ( int i = 0; i < NUM_IN_SCATTER; i++ ) {
		vec2 f = ray_vs_sphere( v, l, EARTH_RADIUS + EARTH_ATMOSPHERE );
		vec3 u = v + l * f.y;
		
		float n = ( optic( p, v ) + optic( v, u ) ) * ( PI * 4.0 );
		
        float dens = density( v );
        
	    float m = MAX;
		sum += dens * exp( -n * ( K_R * C_R + K_M ) ) 
    		* (1. - renderRingFar( u, SUN_DIRECTION, m ).w );
        
		sumdensity += dens;
        
		v += step;
	}
	sum *= len * SCALE_L;
	
	float c  = dot( dir, -l );
	float cc = c * c;
	
	return vec4( sum * ( K_R * C_R * phase_reyleigh( cc ) + K_M * phase_mie( G_M, c, cc ) ) * E, sumdensity * len * SCALE_L);
}

vec4 renderAtmospheric( const in vec3 ro, const in vec3 rd, inout float d ) {
	vec2 e = ray_vs_sphere( ro, rd, EARTH_RADIUS + EARTH_ATMOSPHERE );
	if ( e.x > e.y ) {
        d = MAX;
		return vec4(0.);
	}
	
	vec2 f = ray_vs_sphere( ro, rd, EARTH_RADIUS + 3. );
	e.y = min( e.y, f.x );
	d = e.y;
    
    return in_scatter( ro, rd, e, SUN_DIRECTION );
}

//-----------------------------------------------------
// Lens flare by musk
//
// https://www.shadertoy.com/view/4sX3Rs
//-----------------------------------------------------

vec3 lensflare(vec2 uv,vec2 pos) {
	vec2 main = uv-pos;
	vec2 uvd = uv*(length(uv));
	
	float f0 = 1.5/(length(uv-pos)*16.0+1.0);
	
	float f1 = max(0.01-pow(length(uv+1.2*pos),1.9),.0)*7.0;

	float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
	float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
	float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;
	
	vec2 uvx = mix(uv,uvd,-0.5);
	
	float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
	float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
	float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;
	
	vec3 c = vec3(.0);
	
	c.r+=f2+f4; c.g+=f22+f42; c.b+=f23+f43;
	c = c*.5 - vec3(length(uvd)*.05);
	c+=vec3(f0);
	
	return c;
}

//-----------------------------------------------------
// cameraPath
//-----------------------------------------------------

vec3 pro, pta, pup;
float dro, dta, dup;

void camint( inout vec3 ret, const in float t, const in float duration, const in vec3 dest, inout vec3 prev, inout float prevt ) {

    if( t >= prevt && t <= prevt+duration ) {
    	ret = mix( prev, dest, smoothstep(prevt, prevt+duration, t) );
    }
    
    prev = dest;
    prevt += duration;
}

void cameraPath( in float t, out vec3 ro, out vec3 ta, out vec3 up ) {
    t = mod( t, 66. );
    
    dro = dta = dup = 0.;
    
    pro = ro = vec3(-6300. ,-5000. ,1500. );
    pta = ta = vec3(    0. ,    0. ,   0. );
    pup = up = vec3(    0. ,    0.2,   1. ); 
 
  
    camint( ro, t, 5., vec3(-4300. ,-1000. , 500. ), pro, dro );
    camint( ta, t, 5., vec3(    0. ,    0. ,   0. ), pta, dta );
    camint( up, t, 7., vec3(    0. ,    0.1,   1. ), pup, dup ); 
    
//    camint( ro, t, 5., vec3(-3300. , 1000. , 200. ), pro, dro );
//    camint( ta, t, 5., vec3(    0. ,    0. ,   0. ), pta, dta );
//    camint( up, t, 6., vec3(    0. ,  -0.3,    1. ), pup, dup ); 
    
    camint( ro, t, 8., vec3(-2000. , 1600. , 200. ), pro, dro );
    camint( ta, t, 5., vec3(    0. ,  700. ,-100. ), pta, dta );
    camint( up, t, 4., vec3(    0. ,  -0.3,    1. ), pup, dup ); 
    

    camint( ro, t, 3., vec3(-1355. , 1795. , 1.2 ), pro, dro );
    camint( ta, t, 1., vec3(    0. , 300. ,-600. ), pta, dta );
    camint( up, t, 6., vec3(    0. ,  0.1,    1. ), pup, dup );

    camint( ro, t, 15., vec3(-1354.95 , 1795.11 , 1.19 ), pro, dro );
    camint( ta, t, 19., vec3(    0. , 100. ,   600. ), pta, dta );
    camint( up, t, 14., vec3(    0. ,  0.3,    1. ), pup, dup );
    
    
    camint( ro, t, 7., vec3(-1354.93 , 1795.51 , 1.4 ), pro, dro );
    camint( ta, t, 7., vec3(    0. , 0. , 0. ), pta, dta );
    camint( up, t, 7., vec3(    0. ,  0.25,    1. ), pup, dup );
    
    
    camint( ro, t, 7., vec3(2900.5 , 3102. , 200.5 ), pro, dro );
    camint( ta, t, 7., vec3(    0. , 0. , 0. ), pta, dta );
    camint( up, t, 6., vec3(    0. ,  0.2,    1. ), pup, dup );
    
    camint( ro, t, 11., vec3(4102. , -2900. , 450. ), pro, dro );
    camint( ta, t, 11., vec3(    0. ,   -100. ,   0. ), pta, dta );
    camint( up, t, 18., vec3(    0. ,    0.15,   1. ), pup, dup ); 
    
    camint( ro, t, 10., vec3(-6300. ,-5000. , 1500. ), pro, dro );
    camint( ta, t, 10., vec3(    0. ,    0. ,   0. ), pta, dta );
    camint( up, t, 3., vec3(    0. ,    0.2,   1. ), pup, dup ); 
    
    up = normalize( up );
}

//-----------------------------------------------------
// mainImage
//-----------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 p = -1.0 + 2.0 * (fragCoord.xy) / iResolution.xy;
    p.x *= iResolution.x/iResolution.y;
    
    // black bands
    vec2 bandy = vec2(.1,.9);
    if( uv.y < bandy.x || uv.y > bandy.y ) {
        fragColor = vec4(0.,0.,0.,1.);
        return;
    }
    
    // camera
	vec3 ro, ta, up;
    cameraPath( iTime*.7, ro, ta, up );
      
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,up) );
    vec3 vv = normalize( cross(uu,ww));
	vec3 rd = normalize( -p.x*uu + p.y*vv + 2.2*ww );
    
    float maxd = MAX;  
	vec3 col = renderStars( rd ).xyz;
    
    vec4 planet = renderPlanet( ro, rd, maxd );       
    if( planet.w > 0. ) col.xyz = planet.xyz;
    
    float atmosphered = MAX;
    vec4 atmosphere = renderAtmospheric( ro, rd, atmosphered );
    col = col * (1.-atmosphere.w ) + atmosphere.xyz; 

    vec4 ring = renderRing( ro, rd, maxd );
    if( ring.w > 0. && atmosphered < maxd ) {
	    ring.xyz = ring.xyz * (1.-atmosphere.w ) + atmosphere.xyz; 
    }
    col = col * (1.-ring.w ) + ring.xyz;
    
    // post processing
	col = pow( clamp(col,0.0,1.0), vec3(0.4545) );
	col *= vec3(1.,0.99,0.95);   
	col = clamp(1.06*col-0.03, 0., 1.);      
    
    
	vec2 sunuv =  2.7*vec2( dot( SUN_DIRECTION, -uu ), dot( SUN_DIRECTION, vv ) );
	float flare = dot( SUN_DIRECTION, normalize(ta-ro) );
	col += vec3(1.4,1.2,1.0)*lensflare(p, sunuv)*clamp( flare+.3, 0., 1.);
    
    fragColor = vec4( col ,1.0);
}
