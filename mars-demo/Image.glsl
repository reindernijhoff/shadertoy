// Mars demo. Created by Reinder Nijhoff 2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/XdsGWH
//

#define RAYMARCHSTEPS 150

#define time iTime

//
// math functions
//

const mat2 mr = mat2 (0.84147,  0.54030,
					  0.54030, -0.84147 );
float hash( in float n ) {
	return fract(sin(n)*43758.5453);
}
float noise(in vec2 x) {
	vec2 p = floor(x);
	vec2 f = fract(x);
		
	f = f*f*(3.0-2.0*f);	
	float n = p.x + p.y*57.0;
	
	float res = mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
					mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
	return res;
}
float fbm( in vec2 p ) {
	float f;
	f  =      0.5000*noise( p ); p = mr*p*2.02;
	f +=      0.2500*noise( p ); p = mr*p*2.33;
	f +=      0.1250*noise( p ); p = mr*p*2.01;
	f +=      0.0625*noise( p ); p = mr*p*5.21;
//	f +=      0.005*noise( p ); 
	return f/(0.9375);
}
float detailFbm( in vec2 p ) {
	float f;
	f  =      0.5000*noise( p ); p = mr*p*2.02;
	f +=      0.2500*noise( p ); p = mr*p*2.33;
	f +=      0.1250*noise( p ); p = mr*p*2.01;
	f +=      0.0625*noise( p ); p = mr*p*5.21;
	f +=      0.005*noise( p ); 
	return f/(0.9375);
}

//
// intersection functions
//

bool intersectPlane(vec3 ro, vec3 rd, float height, out float dist) {	
	if (rd.y==0.0) {
		return false;
	}
	
	float d = -(ro.y - height)/rd.y;
	d = min(100000.0, d);
	if( d > 0. ) {
		dist = d;
		return true;
	}
	return false;
}

//
// Scene
//

float skyDensity( vec2 p ) {
	return fbm( p*0.125 );
}
float mapHeight( vec2 p ) {
	return fbm(  p*0.35 )*4.;
}
float detailMapHeight( vec2 p ) {
	return detailFbm(  p*0.35 )*4.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = vec2(-1.0)+2.0*q;
	p.x *= iResolution.x/iResolution.y;
	
	vec2 pos = abs(iMouse.xy)*0.025 + vec2( 0.8, 10.);
	
	vec3 ro = vec3( pos.x, mapHeight( pos )+0.25, pos.y );
	vec3 rd = ( vec3(p, 1. ) );
	
	float dist;
	vec3 col = vec3(0.);
	vec3 intersection = vec3(9999.);
	
	// sky
	if( intersectPlane( ro, rd, 8., dist ) ) {
		intersection = ro+rd*dist;
		col = mix( vec3(240./255., 0./255., 0./255.), vec3(1.), skyDensity( intersection.xz ) );
	} else {
		col = mix( vec3(112./255.,2./255.,6./255.), vec3(0.), clamp(-p.y*3., 0., 1.) );
	}
	// terrain - raymarch
	float t, h = 0.;
	const float dt=0.05;
	
	t = mod( ro.z, dt );
	
	for( int i=0; i<RAYMARCHSTEPS; i++) {
		if( h < intersection.y ) {
			t += dt;
			intersection = ro + rd*t;
			
			h = mapHeight( intersection.xz );
		}
	}
	if( h > intersection.y ) {	
		// calculate projected height of intersection and previous point
		float h1 = (h-ro.y)/(rd.z*t);
		vec3 prev =  ro + rd*(t-dt);
		float h2 = (mapHeight( prev.xz )-ro.y)/(rd.z*(t-dt));
				
		float dx1 = detailMapHeight( intersection.xz+vec2(0.001,0.0) ) - detailMapHeight( intersection.xz+vec2(-0.001, 0.0) );
		dx1 *= (1./0.002);
		float dx2 = detailMapHeight( prev.xz+vec2(0.001,0.0) ) - detailMapHeight( prev.xz+vec2(-0.001, 0.0) );
		dx2 *= (1./0.002);
		
		
		float dx = mix( dx1, dx2, clamp( (h1-p.y)/(h1-h2), 0., 1.));
		
		col = mix( vec3(232./201.,121./255.,101./255.), vec3(31./255.,0.,0.), 0.5+0.25*dx );

	}
	
	fragColor = vec4(col,1.0);
}