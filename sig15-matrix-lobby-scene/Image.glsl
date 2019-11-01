// Created by Reinder Nijhoff 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/MtsXzf
//
//   *Created for the Shadertoy Competition 2015*
//
// Theme: Your Favorite Movie/Game Moment
//
// https://www.shadertoy.com/eventsAugust2015.php5
//

#define HIGHQUALITY 1
#define RENDERDEBRIS 0
#define REFLECTIONS 1

#define MARCHSTEPS 90
#define MARCHSTEPSREFLECTION 30
#define DEBRISCOUNT 8

#define BPM             (140.0)
#define STEP            (4.0 * BPM / 60.0)
#define ISTEP           (1./STEP)
#define STT(t)			(t*(60.0/BPM))

float damageMod;
vec4 ep1, ep2, ep3, ep4, ep5;  

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
  
    float ne = 0.;
    ne += smoothstep( -0.7, 0., -distance( p, ep1.xyz ) );
    ne += smoothstep( -0.7, 0., -distance( p, ep2.xyz ) );
    ne += smoothstep( -0.7, 0., -distance( p, ep3.xyz ) );
    ne += smoothstep( -0.7, 0., -distance( p, ep4.xyz ) );
    ne += smoothstep( -0.7, 0., -distance( p, ep5.xyz ) );
    
    n += .5 * max((ne - p2 ),0.) * ne;
  
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
    } else {    
        vec2 e = vec2(1.0,-1.0)*(0.5773*eps);
        vec3 n =  normalize( e.xyy*mapDamageHigh( pos + e.xyy ) + 
                             e.yyx*mapDamageHigh( pos + e.yyx ) + 
                             e.yxy*mapDamageHigh( pos + e.yxy ) + 
                             e.xxx*mapDamageHigh( pos + e.xxx ) );
        n = bumpMapNormal( pos, n );
        return n;  
    }
}

//----------------------------------------------------------------------
// lighting

float calcAO( in vec3 pos, in vec3 nor ) {
	float occ = 0.0;
    for( int i=0; i<6; i++ ) {
        float h = 0.1 + 1.2*float(i);
        occ += (h-map( pos + h*nor ));
    }
    return clamp( 1.0 - occ*0.025, 0.0, 1.0 );    
}

float calcFakeAOAndShadow( in vec3 pos ) { 
    float r = (1.-abs(pos.x)/30.5);
    
    r *= max( min( .35-pos.z / 40., 1.), 0.65);
    r *= .5+.5*smoothstep( -66., -.65, pos.z);
    
    if( pos.y < 25. ) r *= 1.-smoothstep( 18., 25., .5*pos.y+abs(pos.x) ) * (.6+pos.y/25.);
    r *= 1.-smoothstep(5., 8., abs(pos.x) ) * .75 * (smoothstep( 60.,63.,abs(pos.z)));
    
    return clamp(r, 0., 1.);
}

//----------------------------------------------------------------------
// materials

float matMarble( in vec3 pos, in vec3 nor ) {
    float i = tileId( pos, nor );
    
    return .072*(hash(i)+noise(pos*7.))+.12*noise(pos*25.);
}

float matSideLamp( in vec3 pos, in vec3 nor ) {
    float l = (1.-smoothstep(0.05,0.15, abs( pos.y-13.75 ) ))
        	* (1.-smoothstep(1.5,1.7, abs( mod(pos.z, 3.6)-1.8 ) ));
    return 5. * l;
}

float matOutdoorLight( in vec3 pos, in vec3 nor ) {
    float l = ( smoothstep( 0.03, 0.1, abs( mod( pos.x, 1.8 ) / 1.8 - .5) ))
			* ( smoothstep( 0.03, 0.1, abs( mod( pos.y, 3.6 ) / 3.6 - .5) ));
    return mix( 8.,12., l);
}

vec2 shade( in vec3 pos, in vec3 nor, in float m, in float t, in bool reflection ) {
    float refl = 0.1;
    float mate = 0.;
 	float light = 0.;            
    float col = 0.;
    
    if( m < .5 ) {
   		if( pos.y < .01 ) {
	    	mate = .05 * (.25+.2*texture( iChannel1, pos.xz*.05 ).r);
            float x = abs(pos.x);
            if( (x > 12. && x < 14.8) ||  (x > 3.2 && x < 6.8) || abs(pos.z) > 68.4 ) mate *= 0.25;
        } else if( pos.y > 13.5 && pos.y < 13.99 && abs( pos.x ) > 27.99 ) {
            light = matSideLamp( pos, nor ); 
        } else if( pos.z > 62. && pos.y > 52. ) {
            light = matOutdoorLight( pos, nor );
        } else {
 			mate = matMarble( pos, nor );
            refl = 0.05;
   		}
        if( abs(mapDamageHigh(pos)-map(pos)) > 0.0001 * t ) {
            refl = 0.;
            mate = 0.21;
        }
        if( abs( pos.z ) > 73.1 ) {
            mate = 0.02;
            if( mod( abs( pos.x ), 2.25 ) < .3 ||
            	mod( abs( pos.y ), 2.25 ) < .3 ) mate = 0.0025;
            refl = 0.02;
        }
            
        if( nor.y < -0.8 && pos.y > 13.49 ) {
            col += mate * (0.4 * pow( max( (abs(pos.x*.38)-7.2),0.), 2.));
        }        
    } 
#if RENDERDEBRIS
    else if( m < 1.5 ) {
            refl = 0.;
            mate = 0.1 * noise(pos);
    }
#endif
    
    col += mate * (
        25. * ( 0.02 +
        .2 * min(1., max( -nor.x * sign(pos.x), 0.)) + 
        .5 * min(1., max( nor.y, 0. )) +
        .05 * abs( nor.z ) ) * calcFakeAOAndShadow( pos ) );
    
    col *= calcAO( pos, nor );
    col += light;
    
    return vec2( col, refl );
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
        h = .9*mapDamage( ro+rd*t );
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


float intersectReflection( in vec3 ro, in vec3 rd ) {
	const float precis = 0.00125;
    float h = precis*2.0;
    float t = 0.;
        
    float d = -(ro.y)/rd.y;
    float maxdist = d>0.?d:500.;
    
	for( int i=0; i < MARCHSTEPSREFLECTION; i++ ) {
        h = map( ro+rd*t );
        if( h < precis ) {
            return t;
        } 
        t += h+0.01*t;
        if( t > maxdist ) {
            return maxdist;
        }
    }
    return -1.;
}

//----------------------------------------------------------------------
// render functions

float renderExplosionDebris( const in vec3 ro, const in vec3 rd, in float maxdist, const in vec4 ep, inout vec3 nor, 
                             const in float time ) {
    float maxRadius = 30.*(time - ep.w - .025);
    float minRadius = 0.2 * maxRadius;
    if( maxRadius > 30. ) return maxdist;
    
    for( int i=0; i<DEBRISCOUNT; i++ ) {
        float id = hash(  ep.w+float(i) );
        vec3 dir = normalize( -1.+2.*vec3( id, hash(  ep.w+.5*float(i) ), hash(  ep.w+1.5*float(i) ) ) - vec3( 2.*sign(ep.x), 0., 0.) );
        vec3 pos = ep.xyz + dir*mix( minRadius, maxRadius, id ) + vec3(0.,-maxRadius*sin( maxRadius*0.005 ),0.);
        float d = iSphere( ro, rd, vec4( pos, 0.1*id+0.003 ) );
        if( d > 0. && d < maxdist ) {
            maxdist = d;
            nor = nSphere( ro+rd*d, vec4( pos, 0.1*id+0.003 ) );
        }
    }
    
    return maxdist;
}

void renderExplosionDust( const in vec3 ro, const in vec3 rd, in float dist, const in vec4 ep, inout vec2 col, 
                          const in float time, const in vec3 grd ) {
    float maxRadius = 10.*(time - ep.w + .25);
    if( maxRadius > 40. ) return ;
    
    float dens = 0.;
    float ho = hash( ep.w ); // id of explosion
    float fade = pow( 2., -maxRadius*0.11-2.);
    float zoom = 2.5/maxRadius;
    vec2 down = vec2(sin(maxRadius*0.005+.1), 0.);
                     
	// intersect planes
    vec2 d = -(ro.xz - ep.xz )/rd.xz;
    if( d.x > 0. ) {
        vec3 pos = ro+d.x*rd;
        float radius = distance( ep.yz, pos.yz );
        if( radius < maxRadius  ) {
            float l = max( 0.025*(dist-d.x) + .5, 0. ) 
                        			* fade 
                      				* abs( grd.x )
                     				* (1.-smoothstep( 0.8*maxRadius, maxRadius, radius ));            
	        float excol = mix( col.x, 1., pow( max(1.-2.*textureLod( iChannel2,ho+(pos.yz-ep.yz)*zoom + down, 0.0 ).x,0.),3.) );               
    	    col.x = mix( col.x, excol, l);
            col.y += l;
        }
    }
    
    if( d.y > 0. ) {
        vec3 pos = ro+d.y*rd;
        float radius = distance( ep.yx, pos.yx );
        if( radius < maxRadius  ) {
            float l = max( 0.025*(dist-d.y) + .5, 0. ) 
                        			* fade 
                      				* abs( grd.z )
                     				* (1.-smoothstep( 0.8*maxRadius, maxRadius, radius ));
	        float excol = mix( col.x, 1., pow( max(1.-2.*textureLod( iChannel2,ho+(pos.yx-ep.yx)*zoom + down, 0.0 ).x,0.),3.) );   
    	    col.x = mix( col.x, excol, l);
            col.y += l;
        }
    }
}

vec3 render( const in vec3 ro, const in vec3 rd, in float time, const in float fog, const in vec3 grd ) {
    const float eps = 0.01;
    vec2 col = vec2(0.);
    
    float t = intersect( ro, rd );
    if( time > STT(98.) ) {
        time = STT(95.5)+.4*(time-STT(95.5)); // slow motion
    }
    time += .03*hash( rd.x + rd.y*5341.1231 ); // motionblur
    
    if( t > 0. ) {
        vec3 nor;
        float m = 0.;

#if RENDERDEBRIS
        float d = renderExplosionDebris( ro, rd, t, ep1, nor, time );
        d = renderExplosionDebris( ro, rd, d, ep3, nor, time );
        d = renderExplosionDebris( ro, rd, d, ep5, nor, time );
#if HIGHQUALITY 
        d = renderExplosionDebris( ro, rd, d, ep2, nor, time );
        d = renderExplosionDebris( ro, rd, d, ep4, nor, time );
#endif
        if( d < t ) {
            m = 1.;
            t = d;
        } 
#endif
   
        vec3 pos = ro + t*rd;
        if( m < .5 ) {
	        nor = calcNormalDamage( pos, eps );
        }
        col = shade( pos, nor, m, t, false );

#if REFLECTIONS        
        vec3 rdReflect = reflect( rd, -nor );
        float tReflect = intersectReflection( pos + eps*rdReflect, rdReflect );

        if( tReflect >= 0. && col.y > 0. ) {
            vec3 posReflect = pos + tReflect*rdReflect;
            vec3 norReflect = calcNormalDamage( posReflect, eps );

            col += shade( posReflect, norReflect, 0., tReflect, true ) * col.y;
        }
#endif
    } else {
        t = 60.;
    }

    col.y = 0.; 
    renderExplosionDust( ro, rd, t, ep1, col, time, grd );
    renderExplosionDust( ro, rd, t, ep2, col, time, grd );
    renderExplosionDust( ro, rd, t, ep3, col, time, grd );
    renderExplosionDust( ro, rd, t, ep4, col, time, grd );
    renderExplosionDust( ro, rd, t, ep5, col, time, grd );
    
 // add fog
    vec3 dcol = vec3( max(col.x,0.) );
 	dcol = mix( vec3(.5), dcol, exp( -t*(.02*fog+.005*col.y) ) );
        
    return pow( dcol, vec3(0.45) );
}

//----------------------------------------------------------------------
// explosions

#define E1(a,b,c,d) t+=a;if( time >= t ){ep1 = vec4(b,c,d,t);}
#define E2(a,b,c,d) t+=a;if( time >= t ){ep2 = vec4(b,c,d,t);}
#define E3(a,b,c,d) t+=a;if( time >= t ){ep3 = vec4(b,c,d,t);}
#define E4(a,b,c,d) t+=a;if( time >= t ){ep4 = vec4(b,c,d,t);}
#define E5(a,b,c,d) t+=a;if( time >= t ){ep5 = vec4(b,c,d,t);}

void initExplosions( const in float time ) {
	ep1 = ep2 = ep3 = ep4 = ep5 = vec4(-1000.);
    
    float t = 0.;    
    E1(STT(21.), 16., 3.9, 8.2 );
    E2(.7, 16., 5.4, 6.1 );
    E3(.3, 16., 6.3, 7.7 );
    E4(1., 16., 4.8, 8.2 );
    E5(.7, 16., 5.7, 7.3 );
    
    t = 0.;
    E1(STT(34.), -16., 3.9, 5.2 );
    E2(.5, -16., 5.4, 5.1 );
    E3(.7, -16., 6.3, 6.7 );
    E4(.5, -16., 4.8, 7.2 );
    E5(.4, -16., 5.7, 6.3 );
        
    t = 0.;
    E1(STT(42.), -19.1, 3.9, -4.5 );
    E2(1.3, -17.4, 5.4, -4.5 );
    E3(.3, -18.2, 6.3, -4.5 );
    E4(.4, -17.7, 4.8, -4.5 );
    E5(.3, -16.7, 5.7, -4.5 );
  
    E3(.3, -18.2, 6.3, -4.5 );
    E2(.2, -17.4, 5.4, -4.5 );
    E3(.1, -18.2, 6.3, -4.5 );
    E4(.2, -17.7, 4.8, -4.5 );
    E5(.1, -16.7, 5.7, -4.5 );
    
    E1(.9, -16., 3.9, -5.2 );
    E2(.5, -16., 5.4, -5.1 );
    E3(.3, -16., 6.3, -6.7 );
    E4(.5, -16., 4.8, -7.2 );
    E5(.4, -16., 5.7, -6.3 );    
    
    t = 0.;    
    E1(STT(58.), 16., 3.9, 2.2 );
    E2(.2, 16., 5.4, 4.1 );
    E3(.3, 24., 6.3, 3.7 );
    E4(.5, 16., 4.8, 8.2 );
    E5(.7, 24., 5.7, 4.3 );
    E1(.1, 16., 1.9, 8.2 );
    E2(.2, 24., 5.4, -2.1 );
    
    t = 0.;
    E1(STT(66.), 16., 3.9, 6.5 );
    E2(.2, 16., 5.4, 6.1 );
    E5(.3, 16., 6.7, 7.3 );
    E3(.3, 16., 6.3, 5.7 );
    E4(.2, 16., 7.8, 6.2 );
        
    E5(.1, 16., 5.7, 4.7 );
    E1(.2, 16., 3.9, -6.2 );
    E2(.3, 17., 6.4, -4.5 );
    E3(.3, 16., 6.3, -5.7 );
    E4(.5, 16., 7.8, -6.2 );    
    E5(.3, 16., 5.7, -7.7 );
    E1(.2, 16., 3.9, -6.2 );
    E2(.3, 16., 6.4, -4.5 );
   
    t = 0.;
    E1(STT(78.), -17.1, 3.9, -4.5 );
    E2(.3, -17.4, 5.4, -4.5 );
    E3(.3, -18.2, 6.3, -4.5 );
    E4(.4, -17.7, 4.8, -4.5 );
    E5(.3, -16.7, 5.7, -4.5 );
  
    E3(1.3, -18.2, 6.3, -4.5 );
    E2(.2, -17.4, 5.4, -4.5 );
    E3(.1, -18.2, 6.3, -4.5 );
    E4(.2, -17.7, 4.8, -4.5 );
    E5(.1, -16.7, 5.7, -4.5 );
    
    E2(.5, -19.6, 5.4, -5.1 );
    E1(.9, -19.6, 3.9, -5.2 );
    E3(.3, -19.6, 6.3, -6.7 );
    E4(.5, -19.6, 4.8, -7.2 );
    E5(.4, -19.6, 5.7, -6.3 );
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
	    
    // letterbox
    if( abs(2.*fragCoord.y-iResolution.y) > iResolution.x * 0.42 ) {
        fragColor = vec4( 0., 0., 0., 1. );
        return;
    }
    vec3 ro, ta;
    float fl, fog;
      
    getCamPath( time, ro, ta, fl, fog );
        
    initExplosions( time );
    
    mat3 ca = setCamera( ro, ta, 0.0, (1./1.5) );    
    vec2 p = (-iResolution.xy+2.*(fragCoord.xy))/iResolution.x;
    vec3 rd = normalize( ca * vec3(p,-fl) );

    vec3 col = render( ro, rd, time, fog, normalize( ta-ro ) );
    
    col *= vec3(0.704,0.778,0.704);    
	col = col*0.8 + 0.2*col*col*(3.0-2.0*col);
	col *= vec3(1.378,1.56,1.3);
        
    // vignette
    col *= 0.15 + 0.85*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );

    // flicker
    col *= 1.0 + 0.015*fract( 17.1*sin( 13.1*floor(12.0*iTime) ));
    
	// fade in
    col *= clamp( time*.7, 0., 1. );
    col *= clamp( abs(time-STT(12.)), 0., 1. );
    if( time < STT(33.5) ) col *= clamp( (STT(33.5)-time-.5), 0., 1. );
    col *= clamp( abs(time-STT(98.)), 0., 1. );
    
    fragColor = vec4( col, 1.0 );
}
