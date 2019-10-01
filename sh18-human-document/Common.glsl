// [SH18] Human Document. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XtcyW4
//
//   * Created for the Shadertoy Competition 2018 *
//

// animation

#define FRAMES (760.)
#define DURATION_ANIM (FRAMES/60.)
#define DURATION_START (4.)
#define DURATION_END (4.)
#define DURATION_MORPH_ANIM (.5)
#define DURATION_MORPH_STILL (.5)
#define DURATION_MORPH (DURATION_MORPH_ANIM+DURATION_MORPH_STILL)
#define DURATION_TOTAL (DURATION_START+DURATION_ANIM+DURATION_END)

float frame;

float offsetTime(float time) {
    return max(0., time-2.);
}

void initAnimation(float time) {
    float t = mod(offsetTime(time), DURATION_TOTAL);
    frame = floor(clamp((t-DURATION_START)*60., 10., FRAMES-10.));
}

// bone functions

const float planeY = -9.5;

#define NUM_BONES 14

#define LEFT_LEG_1 3
#define LEFT_LEG_2 4
#define LEFT_LEG_3 5
#define RIGHT_LEG_1 0
#define RIGHT_LEG_2 1
#define RIGHT_LEG_3 2
#define LEFT_ARM_1 10
#define LEFT_ARM_2 11
#define LEFT_ARM_3 12
#define RIGHT_ARM_1 7
#define RIGHT_ARM_2 6
#define RIGHT_ARM_3 8
#define SPINE 13
#define HEAD 9

// render functions

#define MAT_TABLE    1.
#define MAT_PENCIL_0 2.
#define MAT_PENCIL_1 3.
#define MAT_PENCIL_2 4.
#define MAT_PAPER    5.
#define MAT_METAL_0  6.

#define PENCIL_POS vec3(-0.8,-0.2, -2.3)
#define PENCIL_ROT .95
#define PAPER_SIZE (vec2(1.95, 2.75)*1.1)

// http://www.johndcook.com/blog/2010/01/20/how-to-compute-the-soft-maximum/
float smin(in float a, in float b, const in float k) { return a - log(1.0+exp(k*(a-b))) * (1. / k); }

float opS( const float d1, const float d2 ) {
    return max(-d1,d2);
}

vec2 rotate( in vec2 p, const float t ) {
    float co = cos(t);
    float si = sin(t);
    return mat2(co,-si,si,co) * p;
}

float sdSphere( const vec3 p, const vec4 s ) {
    return distance(p,s.xyz)-s.w;
}

float sdBox( vec3 p, vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdCapsule(vec3 p,vec3 o,vec3 e,const float r0,const float r1) {
    vec3 d = e-o;
    float h = length(d);
    d *= (1./h);
    float t=clamp(dot(p-o,d),0.,h);
	vec3 np=o+t*d;
	return distance(np,p)-mix(r0,r1,t);
}

float sdCylinderZY( const vec3 p, const vec2 h ) {
  vec2 d = abs(vec2(length(p.zy),p.x)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdHexPrism( const vec3 p, const vec2 h ) {
    vec3 q = abs(p);
#if 0
    return max(q.x-h.y,max((q.z*0.866025+q.y*0.5),q.y)-h.x);
#else
    float d1 = q.x-h.y;
    float d2 = max((q.z*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

float sdCapsule( const vec3 p, const vec3 a, const vec3 b, const float r ) {
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdSphere( const vec3 p, const float r ) {
    return length(p) - r;
}

float sdCone( const vec3 p, const vec2 c ) {
    float q = length(p.yz);
    return dot(c,vec2(q,p.x));
}

vec2 sphIntersect( in vec3 ro, in vec3 rd, in float r ) {
	vec3 oc = ro;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - r * r;
	float h = b*b - c;
	if( h<0.0 ) return vec2(-1.0);
    h = sqrt( h );
	return vec2(-b - h, -b + h);
}

vec2 boxIntersect( in vec3 ro, in vec3 rd, in vec3 rad ) {
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	if( tN > tF || tF < 0.0) return vec2(-1);

	return vec2(tN, tF);
}

float planeIntersect( const vec3 ro, const vec3 rd, const float height) {	
	if (rd.y==0.0) return 500.;	
	float d = -(ro.y - height)/rd.y;
	if( d > 0. ) {
		return d;
	}
	return 500.;
}

//
// Material properties.
//

vec4 texNoise( sampler2D sam, in vec3 p, in vec3 n ) {
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );

	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}




