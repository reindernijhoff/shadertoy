// Nyan. Created by Reinder Nijhoff 2013
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/XsfGzM
//

// seconds needed to walk through room
#define WALKINGSPEED 3.

#define DIRT
#define NYANSPEED 16.

#define NUMBERLIGHTS 4

#define EXPOSURE 1.9
#define AMBIANT 3.
#define DYNAMICLIGHTSTRENGTH 2.
#define PI 3.1415926

#define INTERVALBACKGROUND 16.
#define INTERVALFLOOR 16.
#define INTERVALFOREGROUND 16.
#define INTERVALSPECULARCOLOR 1.
#define INTERVALDIRT 10.


float dirtFactor;


//
// math functions
//

const mat2 mr = mat2 (0.84147,  0.54030,
					  0.54030, -0.84147 );
float hash( float n ) {
	return fract(sin(n)*43758.5453);
}
vec2 hash2( float n ) {
    return fract(sin(vec2(n,n+1.0))*vec2(2.1459123,3.3490423));
}

vec3 hash3( float n ) {
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(3.5453123,4.1459123,1.3490423));
}
float noise(in float x) {
	float p = floor(x);
	float f = fract(x);
		
	f = f*f*(3.0-2.0*f);	
	return mix( hash(p+  0.0), hash(p+  1.0),f);
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
float fbm( vec2 p ) {
	float f;
	f  =      0.5000*noise( p ); p = mr*p*2.02;
	f +=      0.2500*noise( p ); p = mr*p*2.33;
	f +=      0.1250*noise( p ); p = mr*p*2.01;
	f +=      0.0625*noise( p ); p = mr*p*2.01;
	return f/(0.9175);
}

//
// material functions
//

float matfhf, matflf;
float matnoisehf;
vec3 math3;

void materialInit(in float seed, const vec2 coord) {
	matfhf = fbm( coord * 171. );
	matflf = fbm( coord );
	matnoisehf = noise( coord * 193. );
	math3  = hash3( seed * 11. );
}

vec3 materialBaseColor( float t ) {
	t = mod( t, 3490423. );
	return texture( iChannel0, vec2( t )*vec2(0.14591255443,0.34934560423) ).xyz;
}

void materialDirt( const vec2 coord, out vec3 color, out vec2 normal ) {
	color = vec3( 0.7, 0.5, 0.4 ) * (0.25+0.75*matfhf);
	normal = vec2( matnoisehf*2. -1. );
}

vec2 materialGrooves( float seed, bool iswall ) {
	vec2 math2 = hash2( seed );
	if( iswall ) return clamp( floor(math2*6.) / 8. - 0.25, vec2(0.), vec2(1.));
	return clamp( floor( math2*4.) / 8., vec2(0.), vec2(1.));
}

float grooveHeight( float l, const float w, float p ) {
	if( l == 0. ) return 1.;
	return (smoothstep( 0.,  w*0.5, mod(p, l) )) * (1.-smoothstep( l-w*0.5, l, mod(p, l) ));
}

float materialHeightMap( const vec2 grooves, const vec2 coord ) {
	return min( grooveHeight( grooves.x, 0.01, coord.x ), grooveHeight( grooves.y, 0.01, coord.y ));
}

float materialDirtAmount( const vec2 grooves, const vec2 coord ) {
	vec2 f = mix( vec2(0.01), grooves*2., dirtFactor );
	return 1. - 0.5*min( grooveHeight( grooves.x, f.x, coord.x ), grooveHeight( grooves.y, f.y, coord.y ));
}

// calculate color

void getMaterial( float seed, const vec2 coord, const vec2 grooves,  bool isfloor, bool iswall, 
			  	  out vec3 color, out vec2 normal, out float spec ) {

	float height = materialHeightMap( grooves, coord );	
	normal.x = (height-materialHeightMap( grooves, coord-vec2(0.002,0.) )) * 500.;
	normal.y = (height-materialHeightMap( grooves, coord-vec2(0.,0.002) )) * 500.;
	normal += 0.1*fract( math3.y * 1.64325 ) * (2. * vec2( matfhf, matnoisehf ) - vec2(1.));
	
	spec = (height + 4.*matfhf )*0.1*fract( math3.x * 1.13 )*matflf;
	
	vec3 color1 = materialBaseColor( seed ); 	
	vec3 color2 = materialBaseColor( seed*2.6345 ); 	

	// checkboard ?
	bool checkx = grooves.x > 0. && mod( coord.x, grooves.x*2. ) < grooves.x;
	bool checky = grooves.y > 0. && mod( coord.y, grooves.y*2. ) < grooves.y;
	
	if( fract( math3.z * 4.435 ) < 0.5 && ((checkx && checky) || (!checkx && !checky)) ) {
		color = mix( color2, color1, matflf*fract(math3.y*45.234) );
	} else {		
		color = mix( color1, color2, matflf*fract(math3.y*45.234) );
	}
	
	color *= (0.8+0.2*height+0.2*fract( math3.x*3.76 )*matfhf);
		
#ifdef DIRT	
	if( dirtFactor > 0.1 ) { // dirt
		vec2 dirtNormal; vec3 dirtColor;		
		materialDirt( coord, dirtColor, dirtNormal );
		
		float dirtAmount = materialDirtAmount( grooves, coord );	

		if( iswall ) {
			dirtAmount += clamp( dirtFactor - coord.y, -dirtAmount, 1.);
		} else	if( !isfloor ) {
			dirtAmount *= 0.5; // less dirt on ceiling
		}
	
		dirtFactor = clamp( 10. * (0.5* (dirtAmount * matflf + matfhf ) - (1.-dirtFactor)), 0., 1.);
	
		if( dirtFactor > 0.1 ) {
			color = mix( color, dirtColor, dirtFactor );
			spec *= 1. - dirtFactor;
			normal = mix( normal, dirtNormal, dirtFactor );
		}
	}
#endif
}

void getWallMaterial( float seed, vec2 coord,  
					  out vec3 color, out vec2 normal, out float spec ) {
	coord *= 0.1;
	materialInit( seed, coord );
	
	float s = mod( floor( math3.y*13.4361 ), 8. ) * 0.125;
	
	float wseed = seed;
	if( coord.y > s ) wseed += 1.;	

	vec2 grooves = materialGrooves( wseed, true );

	getMaterial( seed, coord, vec2(grooves.x, max( grooves.y, s )), false, true, color, normal, spec );
}

void getFloorMaterial( float seed, vec2 coord, bool isfloor,  
					   out vec3 color, out vec2 normal, out float spec ) {	
	coord *= 0.1;
	materialInit( seed, coord );
	vec2 grooves = materialGrooves( seed, false );

	getMaterial( seed, coord, grooves, isfloor, false, color, normal, spec );
}


vec3 getColor(vec2 coord, float time) {
	float z, spec, offset;
	vec3 color, position, normal, retcolor;
	vec2 ntangent;
	
    
	offset = time * NYANSPEED;
	
	coord.y += 0.4;
	
	if( coord.y >  0. ) { // wall at z = -8.
		z = 8.; vec2 dxy = vec2( z );
		position = vec3( coord*dxy, z );
		float material = floor( (position.x+offset) / INTERVALBACKGROUND );	
		getWallMaterial( material, position.xy+offset*vec2(1., 0.), color, ntangent, spec );
		normal = normalize( vec3( -ntangent.x, -ntangent.y, -1. ) );
	} else if( coord.y < -0.125 ) { // wall at z = -4;
		z = 4.; vec2 dxy = vec2( z );
		position = vec3( (coord+vec2(0.,0.125))*dxy, z );
		float material = floor( (position.x+offset) / INTERVALFOREGROUND );
		getFloorMaterial( material, position.xy+offset*vec2(1., 0.), false, color, ntangent, spec );
		normal = normalize( vec3( -ntangent.x, -ntangent.y, -1. ) );
	} else { // floor
		z = -1./(coord.y-0.125); vec2 dxy = vec2( z );
		position = vec3( coord*dxy, z );
		float material = floor( (position.x+offset) / INTERVALFLOOR );
		getFloorMaterial( material, position.xz+offset*vec2(1., 0.), true, color, ntangent, spec );
		normal = normalize( vec3( -ntangent.x, 1., -ntangent.y ) );
	}
	
	// nyan cat! at z=-7;
	z = 7.; vec2 dxy = vec2( z );
	vec2 nyanpos = coord*dxy+vec2( 6.5, 1.2 );
	bool nyanhit = false;
	
	if( nyanpos.x >= 0. && nyanpos.x < 5. && nyanpos.y >= 0. && nyanpos.y < 5. ) {
		vec2 nyancoord = nyanpos/5.;
		
		float ofx = floor( mod( time*NYANSPEED, 6.0 ) );
		float ww = 40.0/256.0;
				
		nyancoord.y = 1.0-nyancoord.y;
		nyancoord.x = clamp( nyancoord.x*ww + ofx*ww, 0.0, 1.0 );
		vec4 nyan = texture( iChannel1, nyancoord );
		if( nyan.w > 0. ) {
			color = nyan.xyz;
			normal = vec3( 0., 0., -1. );
			position =  vec3( nyanpos, z );
			spec = 0.5;
			nyanhit = true;
		}
	}
		
	vec3 diffcolor = vec3(0.6);
	retcolor = diffcolor*color*AMBIANT * dot( normalize( -vec3( 0.8, -0.8, 1.0 ) ), normal );
	
	// dynamic lights

	float specfactor = time/INTERVALSPECULARCOLOR;
	vec3 speccolor = normalize( mix( hash3( floor( specfactor ) ), hash3( floor( specfactor+1. ) ), fract( specfactor ) ) );
	
	float totalwidth = 40.;
	vec3 rd = normalize( vec3( coord, 0.1 ) );
	
	for( int i=0; i<NUMBERLIGHTS; i++) {
		float lx = mod( float(i)*totalwidth/float(NUMBERLIGHTS)-offset, totalwidth)-totalwidth/2.;
		vec3 loffset = vec3( 1.5*sin(time*2.+float(i)), 4.4*cos(time*1.3+float(i)), 3.*sin(time*0.9+float(i)) );

		vec3 lpos = vec3( lx, 5., 4.5 ) + loffset;
		vec3 lvec = lpos - position;
		
		float llig = dot( lvec, lvec);
		float im = inversesqrt( llig );
		lvec = im * lvec;
		
		// diffuse
		float diff = DYNAMICLIGHTSTRENGTH * clamp( dot( lvec, normal ), 0., 1.);	
		// specular		
		float specu = clamp( dot( reflect(rd,normal), lvec ), 0.0, 1.0 );
		specu = 40. * DYNAMICLIGHTSTRENGTH * spec * (pow(specu,16.0) + 0.5*pow(specu,4.0));
		
		retcolor += speccolor * color * (diff+specu) / llig;
	}

	if( !nyanhit ) {
		float ao = length(position- vec3( -3.5, 1.3, 6.));
		retcolor *= clamp( ao*0.4, 0., 1.);
	}
	
	return retcolor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float time = iTime + 259.;
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
	
	dirtFactor = 0.4+0.2*sin(time/INTERVALDIRT+1.6);
	
	vec3 color = getColor( p, time );
	color = pow( 0.7*color, vec3(EXPOSURE) );	
    // vigneting
    color *= 0.25+0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );
	
	fragColor = vec4( color, 1.0);
}