// Created by Reinder Nijhoff 2016
// @reindernijhoff
//
// https://www.shadertoy.com/view/ls3GWS
//
//
// demonstrating post process Screen Space Ambient Occlusion applied to a depth and normal map
// with the geometry of my shader '[SIG15] Matrix Lobby Scene': 
//
// https://www.shadertoy.com/view/MtsXzf
//


#define HIGHQUALITY 1

#define MARCHSTEPS 120

#define BPM             (140.0)
#define STEP            (4.0 * BPM / 60.0)
#define ISTEP           (1./STEP)
#define STT(t)			(t*(60.0/BPM))

float damageMod;

//-----------------------------------------------------
// noise functions

#define MOD2 vec2(.16632,.17369)
float hash(float p) { // by Dave Hoskins
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}

float noise( const in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}

float noise( const in vec2 x ) {
    vec2 p = floor(x);
    vec2 f = fract(x);
	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);
	return textureLod( iChannel0, (uv+118.4)/256.0, 0.0 ).x;
}

//-----------------------------------------------------
// intersection functions

vec3 nSphere( in vec3 pos, in vec4 sph ) {
    return (pos-sph.xyz)/sph.w;
}

float iSphere( in vec3 ro, in vec3 rd, in vec4 sph ) {
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.;
	return -b - sqrt( h );
}

//----------------------------------------------------------------------
// distance primitives

float sdBox( const in vec3 p, const in vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdColumn( const in vec3 p, const in vec2 b ) {
    vec2 d = abs(p.xz) - b;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//----------------------------------------------------------------------
// distance operators

float opU( float d2, float d1 ) { return min( d1,d2); }
float opS( float d2, float d1 ) { return max(-d1,d2); }
    
//--------------------------------------------
// map

float tileId( const in vec3 p, const in vec3 nor ) { 
    if( abs(nor.y) > .9 ) return 0.;
    
    float x, y;
    if( abs(nor.z) < abs(nor.x)) {
        x = p.z-6.;
    } else {
        x = abs(p.x)-16.;
    }
    if( p.y < 2.5 ) {
    	return floor( x / 3.6 ) * sign(p.x);
    }
    return floor( x / 1.8 ) * sign(p.x) * (floor( (p.y+7.5) / 5. ));
}


vec3 bumpMapNormal( const in vec3 pos, in vec3 nor ) {
    float i = tileId( pos, nor );
    if( i > 0. ) {
        nor+= 0.0125 * vec3( hash(i), hash(i+5.), hash(i+13.) );
        nor = normalize( nor );
    }
    return nor;
}

float map( const in vec3 p ) {
    float d = -sdBox( p, vec3( 28., 14., 63. ) );

    vec3 pm = vec3( abs( p.x ) - 17.8, p.y, mod( p.z, 12.6 ) - 6.);    
    vec3 pm2 = abs(p) - vec3( 14., 25.25, 0. );
    vec3 pm3 = abs(p) - vec3( 6.8, 0., 56.4 );      

    d = opU( d, sdColumn( pm, vec2( 1.8, 1.8 ) ) );        
    d = opS( d, sdBox( p,  vec3( 2.5, 9.5, 74. ) ) );    
    d = opS( d, sdBox( p,  vec3( 5., 18., 73. ) ) );
    d = opS( d, sdBox( p,  vec3( 13.8, 14.88, 63. ) ) );
    d = opS( d, sdBox( p,  vec3( 13.2, 25., 63. ) ) );
    d = opS( d, sdColumn( p,  vec2( 9.5, 63. ) ) ); 
    d = opU( d, sdColumn( pm3, vec2( 1.8, 1.8 ) ) );
    d = opU( d, sdBox( pm2, vec3( 5., .45, 200. ) ) );
    
    return d;
}

float mapDamage( vec3 p ) {
    float d = map( p );

    float n = max( max( 1.-abs(p.z*.01), 0. )*
                   max( 1.-abs(p.y*.2-1.2), 0. ) *
                   noise( p*.3 )* (noise( p*2.3 ) +.2 )-.2 - damageMod, 0.);
   
	return d + n;
}

float mapDamageHigh( vec3 p ) {
    float d = map( p );
    
    float p1 = noise( p*2.3 );
    float p2 = noise( p*5.3 );
    
    float n = max( max( 1.-abs(p.z*.01), 0. )*
                   max( 1.-abs(p.y*.2-1.2), 0. ) *
                   noise( p*.3 )* (p1 +.2 )-.2 - damageMod, 0.);
    
    if( p.y < .1 ) {
        n += max(.1*(1.-abs(d)+7.*noise( p*.7 )+.9*p1+.5*p2)-4.5*damageMod,0.);
    }
    
    if( abs(n) > 0.0 ) {
        n += noise( p*11.) * .05;
        n += noise( p*23.) * .03;
    }
    
	return d + n;
}


vec3 calcNormalDamage( in vec3 pos, in float eps ) {
    if( pos.y < 0.001 && (mapDamageHigh(pos)-map(pos)) < eps ) {   		
	        return vec3( 0., 1., 0. );
    }
    
    vec2 e = vec2(1.0,-1.0)*(0.5773*eps);
    vec3 n =  normalize( e.xyy*mapDamageHigh( pos + e.xyy ) + 
			     		 e.yyx*mapDamageHigh( pos + e.yyx ) + 
					  	 e.yxy*mapDamageHigh( pos + e.yxy ) + 
					  	 e.xxx*mapDamageHigh( pos + e.xxx ) );
    n = bumpMapNormal( pos, n );
    return n;    
}

//----------------------------------------------------------------------
// intersection code

float intersect( in vec3 ro, in vec3 rd ) {
	const float precis = 0.00125;
    float h = precis*2.0;
    float t = 0.1;
        
    float d = -(ro.y)/rd.y;
    float maxdist = d>0.?d:500.;
    
	for( int i=0; i < MARCHSTEPS; i++ ) {
#if HIGHQUALITY
        h = .8*mapDamage( ro+rd*t );
#else
        h = map( ro+rd*t );
#endif
        if( h < precis ) {
            return t;
        } 
        t += h+0.00005*t;
        if( t > maxdist ) {
            return maxdist;
        }
    }
    return -1.;
}


vec4 render( const in vec3 ro, const in vec3 rd, in float time, const in float fog, const in vec3 grd ) {
    const float eps = 0.01;
    vec2 col = vec2(0.);
    
    float t = intersect( ro, rd );
    if( time > STT(98.) ) {
        time = STT(95.5)+.4*(time-STT(95.5)); // slow motion
    }
    time += .03*hash( rd.x + rd.y*5341.1231 ); // motionblur
    
    vec3 nor;
    
    if( t > 0. ) {
        float m = 0.;
   
        vec3 pos = ro + t*rd;
        if( m < .5 ) {
	        nor = calcNormalDamage( pos, eps );
        }
    } else {
        t = 60.;
    }        
    return vec4(nor, max(t/60.,0.));
}

//----------------------------------------------------------------------
// camera

mat3 setCamera( const in vec3 ro, const in vec3 rt, const in float cr, const in float fl ) {
	vec3 cw = normalize(rt-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -fl*cw );
}

#define SCAM(a,j,h,i,f,g,b,c,d,e) if(time >= t ){damageMod=j;sro=b;ero=c;sta=d;eta=e;st=t;dt=a;sfog=h;efog=i;}t+=a;
#define CCAM(a,j,h,i,f,g,b,c,d,e) if(time >= t ){sro=ero;ero=c;sta=eta;eta=e;st=t;dt=a;sfog=efog;efog=i;}t+=a;

void getCamPath( const in float time, inout vec3 ro, inout vec3 ta, inout float fl, inout float fog ) {
    vec3 sro, sta, ero, eta;
    float st = 0., dt, t = 0., sfog, efog;
    
    SCAM(STT(12.), 0., 0.,    0., 1.5, 1.5, vec3( 0., 5., 22.5 ), vec3( 0., 5.,  18.5 ), vec3( 0., 5., 0. ), vec3( 0., 5., 0. ) ); 
    SCAM(STT(7.5), 0., 0.,    0., 1.5, 1.5, vec3( -14., 5.,  18.5 ), vec3( 18., 4., 11. ), vec3( 10., 5., -50. ), vec3( 0., 5., -50. ) ); 
    CCAM(STT(7.5), 0., 0.,  0.05, 1.5, 1.5, vec3( 18., 4., 11. ), vec3( 21.5, 4., 11.5 ),  vec3( 0., 5., -50. ), vec3( -4., 7., 0. ) ); 
    CCAM(STT(2.5), 0., 0.05, 0.1, 1.5, 1.5, vec3( 21.5, 4., 11.5 ), vec3( 21.5, 4., 11.5 ),  vec3( -4., 7., 0. ), vec3( -16., 7., 8. ) ); 
    CCAM(STT(4.), 0.,  0.1, 0.15, 1.5, 4.5, vec3( 21.5, 4., 11.5 ), vec3( 10., 4.25, 11.35 ),  vec3( -16., 7., 8. ), vec3( -16., 6., 8. ) ); 
    
    SCAM(STT(7.5),  0., 0.1,  0.3, 1.5, 1.5, vec3( -11., 5.25, 7.05 ), vec3( -13., 5., 9. ),  vec3( -19., 5.2, 7. ), vec3( -16.5, 5., 5.3 ) );     
    SCAM(STT(13.), .4, 0.1,  0.5, 1.5, 1.5, vec3( -18., 5., 4.05 ), vec3( -10., 5.25, -6. ),  vec3( -17., 5.5, 0. ), vec3( -15.5, 5.25, -7.3 ) );     
	CCAM(STT(4.), .45, 0.5,  0.65, 1.5, 1.2, vec3( -10., 5.25, -6. ), vec3( -12., 5.25, -9. ),  vec3( -15.5, 5.25, -7.3 ), vec3( -13.5, 6.25, 2.3 ) );     

    SCAM(STT(7.5), .95, 0.4,  1.9, 1.5, 1.5, vec3( 18., 4., 11. ), vec3( 25.5, 4., 11.5 ),  vec3( 0., 5., -50. ), vec3( -4., 7., 0. ) ); 

    SCAM(STT(12.2), .95, 0.8,  1.3, 1.5, 1.5, vec3( 10., 4.7, 4. ), vec3( 10., 5., -7.5 ),  vec3( 50., 5., 2. ), vec3( 40., 5., -20. ) ); 
    
    SCAM(STT(16.25), 1., 0.4,  0.8, 1.5, 1.5, vec3( -18., 4.5, 4.05 ), vec3( -26., 3.25, -6. ),  vec3( -17., 5.5, 0. ), vec3( -15.5, 6.25, -7.3 ) );     
    CCAM(STT(4.),  1., 0.8,  0.6, 1.5, 1.5, vec3( -26., 3.25, -6. ), vec3( -26., 3.25, -6. ),  vec3( -15.5, 6.25, -7.3 ), vec3( -15.5, 6.25, -7.3 ) );     

    SCAM(STT(16.), 1.1, 0.4, 0.05, 1.5, 1.5, vec3( 0., 5.,  18.5 ), vec3( 0., 5.,  18.5 ), vec3( 0., 5., 0. ), vec3( 0., 5., 0. ) ); 
  
    dt = clamp( (time-st)/dt, 0., 1. );

    if(  time > STT(65.5) && time < STT(77.75)  ) {
	    ro = mix( sro, ero, dt);
    	ta = mix( sta, eta, dt);
    } else {
	    ro = mix( sro, ero, smoothstep(0.,1., dt));
    	ta = mix( sta, eta, smoothstep(0.,1., dt));
    }
	
    fl = 1.5;    
    if( time > STT(29.5) && time < STT(33.5) ) {
        fl = mix( 1.5, 4.5, smoothstep( STT(29.5), STT(33.5), time ) );
    }
    
   	fog = mix( sfog, efog, dt);
    damageMod = .4-.4*damageMod;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float time = mod(iTime, 60.);

    vec2 q = fragCoord.xy/iResolution.xy;
	 
    vec3 ro, ta;
    float fl, fog;
      
    getCamPath( time, ro, ta, fl, fog );
    
    if( dot(fragCoord.xy, fragCoord.xy) < 10. ) {
	   fragColor = vec4( fl );
       return;
    }
        
    mat3 ca = setCamera( ro, ta, 0.0, (1./1.5) );    
    vec2 p = (-iResolution.xy+2.*(fragCoord.xy))/iResolution.x;
    vec3 rd = normalize( ca * vec3(p,-fl) );

    vec4 r = render( ro, rd, time, fog, normalize( ta-ro ) ); 
    fragColor = vec4( ((r.xyz * ca)).xyz,  r.w );
}
