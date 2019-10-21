// Outrun. Created by Reinder Nijhoff 2013
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/Mdf3Dr
//

// DON'T LOOK AT THE MATH!!!

#define MAXDISTANCE 10000.
#define TRACKSVISIBLE 10
#define SEGMENTSPERTRACK 10
#define SECONDSPERTRACK 0.97
#define TRACKLENGTH 200.

#define time iTime

//
// math functions
//

float hash( float n ) {
	return fract(sin(n)*43758.5453);
}
float noise(in float x) {
	float p = floor(x);
	float f = fract(x);
		
	f = f*f*(3.0-2.0*f);	
	return mix( hash(p+  0.0), hash(p+  1.0),f);
}
float crossp( vec2 a, vec2 b ) { return a.x*b.y - a.y*b.x; }

//
// intersection functions
//

void intersectSegment(const vec3 ro, const vec3 rd, const vec2 a, const vec2 b, out float dist, out float u) {
	dist = MAXDISTANCE;
	vec2 p = ro.yz;
	vec2 r = rd.yz;
	vec2 q = a-p;
	vec2 s = b-a;
	float rCrossS = crossp(r, s);
	
	if( rCrossS == 0.){
		return;
	}
	float t = crossp(q, s) / rCrossS;
	u = crossp(q, r) / rCrossS;
	
	if(0. <= t && 0. <= u && u <= 1.){
		dist = t;
	}
}

float trackAngle( float s ) {
	return (2.*noise( s*0.1 )-1.)*2.;
}
float trackHeight( float s ) {
	return 500.*noise( s*0.2 );
}

float traceTrack( vec3 ro, vec3 rd, out vec2 texcoord ) {
	float dist = MAXDISTANCE, dtest, xdist, zdist = MAXDISTANCE;
	float utest;
	
	float tf = time / SECONDSPERTRACK;
	float starttrack = floor(tf);
	float fracttrack = fract(tf);
	
	float z = -fracttrack*TRACKLENGTH;
	
	float sa = trackAngle( tf );
		
	for( int it=0; it<TRACKSVISIBLE; it++) {
		float t = float(it)+starttrack;
			
		for( int is=0; is<SEGMENTSPERTRACK; is++ ) {			
			float dt = float(is)/float(SEGMENTSPERTRACK);
			intersectSegment( ro, rd, vec2( trackHeight( t+dt ), z ), 
							 vec2( trackHeight( t+dt+(1./float(SEGMENTSPERTRACK)) ), z+(TRACKLENGTH/float(SEGMENTSPERTRACK))), dtest, utest );
			if( dtest < dist ) {
				dist = dtest;
				texcoord.y = utest;
				xdist = ro.x+rd.x*dist;
				zdist = ro.z+rd.z*dist;
				texcoord.x = xdist + 2.*zdist*sin( trackAngle(t+dt+(utest/float(SEGMENTSPERTRACK)))-sa );
			}
			z+=(TRACKLENGTH/float(SEGMENTSPERTRACK));
		}
	}
	return zdist;
}

vec3 trackColor( vec2 texcoord ) {
	if( abs(texcoord.x)<50. ) { // road
		if(texcoord.y>0.5) {
			return abs(texcoord.x)>46.?vec3(1.):vec3( 146./255. );
		} else {
			return mod(texcoord.x, 22.)<1.5?vec3(1.):vec3( 154./255. );
		}
	} else { // desert
		return (texcoord.y>0.5)?vec3( 235./255., 219./255., 203./255. )
			:vec3( 227./255., 211./255., 195./255. );
	}
}
vec3 skyColor( vec2 texcoord ) {
	vec3 col = vec3( 0./255., 146./255., 255./255.);
	float n = noise( texcoord.x )*texcoord.y*10.+texcoord.y*4.;
	n += noise( texcoord.x * 10. );
	if( n < 1. ) col = mix(
		vec3( 170./255., 154./255., 138./255.),
		vec3( 235./255., 219./255., 203./255. ), clamp(texcoord.y*16., 0., 1.) );
	return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;

	vec3 ro = vec3( -20.*sin(trackAngle(time/SECONDSPERTRACK)), 10.+trackHeight(time/SECONDSPERTRACK), -14. );
	vec3 rd = normalize( vec3( p, 1. ) );	
	vec3 color = vec3( 0. );
	
	vec2 texcoord;
	float d =  traceTrack( ro, rd, texcoord );
	if( d < MAXDISTANCE ) {
		color = mix( trackColor( texcoord ), vec3( 170./255., 154./255., 138./255.), d/(float(TRACKSVISIBLE)*TRACKLENGTH));
	} else {
		if( rd.y > 0. ) {
			color = skyColor( vec2( p.x-2.*trackAngle(time/SECONDSPERTRACK), p.y) );
		} else {
			color = vec3( 170./255., 154./255., 138./255.);
		}
	}
	
	fragColor = vec4( clamp(color, 0., 1.),1.0);
}