// Folding. Created by Reinder Nijhoff 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/MdjXDV
//

#define MARCHSTEPS 250
#define PAPERHEIGHT 0.002
#define PI 3.1415926

float time;

//----------------------------------------------------------------------

vec3 RotateY( const in vec3 vPos, const in float fAngle ) {
    float s = sin(fAngle);
    float c = cos(fAngle);
   
    vec3 vResult = vec3( c * vPos.x + s * vPos.z, vPos.y, -s * vPos.x + c * vPos.z);
   
    return vResult;
}
   
vec3 RotateZ( const in vec3 vPos, const in float fAngle ) {
    float s = sin(fAngle);
    float c = cos(fAngle);
   
    vec3 vResult = vec3( c * vPos.x + s * vPos.y, -s * vPos.x + c * vPos.y, vPos.z);
   
    return vResult;
}

//----------------------------------------------------------------------
// distance primitives

float opS( float d2, float d1 ) { return max(-d1,d2); }

float sdBox( in vec3 p, in vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

//----------------------------------------------------------------------
// Map functions

vec3 fold( const in vec3 p, in float offset, const in float rot, in float a, const bool left ) {    
    a = clamp( a, -PI, PI );
    float b = PI-a;   
    vec3 rp = p;

    if( !left ) offset = -offset;
    
	rp.x -= offset;
    rp = RotateY( rp, rot );
    
	float angle = atan( rp.y, rp.x * (left?-1.:1.) );
     
    if( angle < 0. ) {
        if(  angle >  - b * 0.5 ) {
            rp = RotateZ( rp, a * (left?-1.:1.) );
        }
    } else {
        if( angle - a < b * 0.5 ) {
	        rp = RotateZ( rp, a * (left?-1.:1.) );
        }
    }
    
    rp = RotateY( rp, -rot );      
    rp += vec3(offset,0.,0.);
    
   
    return rp;
}

float timedAngle( const in float starttime, const in float totaltime, const in float angle ) {
	float i = clamp( time - starttime, 0., totaltime );
    return 3.1415926 * angle * i / totaltime;
}

float map( in vec3 p ) {
    
	// folding input domain
    p = fold( p, 0.,    0.,  		   timedAngle( 6., 2., 0.25), false );
    p = fold( p, 0.,    0.,  		   timedAngle(10., 2., 0.25), true );
    p = fold( p, -0.25,  0., 		   timedAngle( 8., 2.,-0.25), false  );
    p = fold( p, -0.25,  0., 		   timedAngle(12., 2.,-0.25), true  );
    
    if( time < 6.  ) 
    	p = fold( p, -1.4, PI*0.25,  timedAngle( 4., 2., -0.8 ) , true );
    if( time < 4.  ) 
		p = fold( p, -1.4, -PI*0.25, timedAngle( 2., 2., -0.8 ) , false );
    
    // just one paper plane
    float d = sdBox( p, vec3( 1., PAPERHEIGHT, 1.4) );
    
    if( time >= 6.  ) { // clip the plane hack :(
        vec3 po = p + vec3( 1.53, 0., 2.707 ); po = RotateY( po, PI*0.25 );
        d = opS( d, sdBox( po, vec3( 2., 1., 2. ) ) );
    } 
    
    if( time >= 4.  ) { // clip the plane hack :(
        vec3 po = p + vec3( -1.53, 0., 2.707 ); po = RotateY( po, PI*0.25 );
        d = opS( d, sdBox( po, vec3( 2., 1., 2. ) ) );
    } 
    
	return d;
}

//----------------------------------------------------------------------

vec3 calcNormal( in vec3 pos ) {
    const vec2 e = vec2(1.0,-1.0)*0.0025;

    vec3 n = normalize( e.xyy*map( pos + e.xyy ) + 
					    e.yyx*map( pos + e.yyx )   + 
					    e.yxy*map( pos + e.yxy )   + 
					    e.xxx*map( pos + e.xxx )   );  
    return n;
}

vec2 intersect( in vec3 ro, in vec3 rd ) {
	const float maxd = 60.0;
	const float precis = 0.001;
    float d = precis*2.0;
    float t = 0.;
    float m = 1.;
    
    for( int i=0; i<MARCHSTEPS; i++ ) {
	    d = 0.2 * map( ro+rd*t );
		t+=d;
        if( d<precis||t>maxd ) break;
    
    }

    if( t>maxd ) m=-1.0;
    return vec2( t, m );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {    
    time = mod( iTime + 8., 32. );
    vec2 q = fragCoord.xy / iResolution.xy;
	vec2 p = -1.0 + 2.0*q;
	p.x *= iResolution.x / iResolution.y;
        
    if (q.y < .12 || q.y >= .88) {
		fragColor=vec4(vec4(0.0));
		return;
	}
    
    if ( time > 16. ) { time = 32.-time; }
    
    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------

	vec3 ro = vec3(0.,1.75 + 0.25*sin( iTime * 0.42 ), 3.);
    ro = RotateY( ro, iTime*0.05 );
    vec3 ta = vec3( 0. ,0., 0. );

    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
	vec3 rd = normalize( -p.x*uu + p.y*vv + 2.2*ww );
    
    
     vec3 col = vec3(0.01);

    // raymarch
    vec2 ints = intersect(ro ,rd );
    if(  ints.y > -0.5 ) {
        vec3 i = ro + ints.x * rd;
        vec3 nor =  calcNormal( i );
    	col = vec3(1.) * (0.1+0.9 * clamp(dot( nor, normalize(vec3(0.5, 0.8, 0.2))),0.,1.));
	}
    
    // gamma
	col = pow( clamp(col,0.0,1.0), vec3(0.4545) );


    fragColor = vec4( col, 1.0 );
}
