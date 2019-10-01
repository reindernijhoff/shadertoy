// Legend of the Gelatinous Cube. Created by Reinder Nijhoff 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
// 
// https://www.shadertoy.com/view/Xs2Bzy
//
// I created this shader in one long night for the Shadertoy Competition 2017
// 

// RENDER THE DUNGEON AND ADD UI FROM BUFFER B

#define MAXSTEPS 8
const int MOVESTEPS = 60;
const int USERMOVESTEPS = 30;
const int USERROTATESTEPS = 30;
const int DOORMOVESTEPS = 30;
const int MAXSWORD = 30;
const int REDFLASHSTEPS = 15;

const int NONE = 0;
const int FORWARD = 1;
const int BACK = 2;
const int ROT_LEFT = 3;
const int ROT_RIGHT = 4;
const int ACTION = 5;

vec3 USERRD = vec3(0);

const ivec2 DIRECTION[] = ivec2[] (
    ivec2(0,1),
    ivec2(1,0),
    ivec2(0,-1),
    ivec2(-1,0)
);

#define HASHSCALE1 .1031
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p3)
{
	p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 rotate(vec3 r, float v){ return vec3(r.x*cos(v)+r.z*sin(v),r.y,r.z*cos(v)-r.x*sin(v));}

vec2 boxIntersection(vec3 ro, vec3 rd, vec3 boxSize, out vec3 outNormal) {

    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    vec2 time = vec2( max( max( t1.x, t1.y ), t1.z ),
                 min( min( t2.x, t2.y ), t2.z ) );
	
    if( !(time.y>time.x && time.y>0.0) ) return vec2(-1);
    
    outNormal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    return time;
}

ivec4 m(ivec2 uv) {
    return ivec4(texelFetch(iChannel0, uv + ivec2(32,0), 0));
}

ivec4 w(ivec2 uv) {
    return ivec4( texelFetch(iChannel0, uv, 0) );
}


//----------------------------------------------------------------------
// Material helper functions

#define COL(r,g,b) vec3(r/255.,g/255.,b/255.)

float onLine( const float c, const float b ) {
	return clamp( 1.-abs(b-c), 0., 1. );
}
float onBand( const float c, const float mi, const float ma ) {
	return clamp( (ma-c+1.), 0., 1. )*clamp( (c-mi+1.), 0., 1. );
}
float onRect( const vec2 c, const vec2 lt, const vec2 rb ) {
	return onBand( c.x, lt.x, rb.x )*onBand( c.y, lt.y, rb.y );
}
vec3 addBevel( const vec2 c, const vec2 lt, const vec2 rb, const float size, const float strength, const float lil, const float lit, const vec3 col ) {
	float xl = clamp( (c.x-lt.x)/size, 0., 1. ); 
	float xr = clamp( (rb.x-c.x)/size, 0., 1. );	
	float yt = clamp( (c.y-lt.y)/size, 0., 1. ); 
	float yb = clamp( (rb.y-c.y)/size, 0., 1. );	

	return mix( col, col*clamp(1.0+strength*(lil*(xl-xr)+lit*(yb-yt)), 0., 2.), onRect( c, lt, rb ) );
}
float stepeq( float a, float b ) { 
	return step( a, b )*step( b, a );
}
//----------------------------------------------------------------------
// Generate materials!

void decorateWall(in vec2 uv, const float decorationHash, inout vec3 col ) {	
	vec3 fgcol;
	
	uv = floor( mod(uv+64., vec2(64.)) );
	vec2 uvs = uv / 64.;
	
	// basecolor
	vec3 basecol = col;	
	float br = hash12(uv);

	
// prison door	
	if( decorationHash > 0.95 ) {	
		vec4 prisoncoords = vec4(12.,14.,52.,62.);
	// shadow
		col *= 1.-0.5*onRect( uv,  vec2( 11., 13. ), vec2( 53., 63. ) );
	// hinge
		col = mix( col, COL(72.,72.,72.), stepeq(uv.x, 53.)*step( mod(uv.y+2.,25.), 5.)*step(13.,uv.y) );
		col = mix( col, COL(100.,100.,100.), stepeq(uv.x, 53.)*step( mod(uv.y+1.,25.), 3.)*step(13.,uv.y) );
		
		vec3 pcol = vec3(0.)+COL(100.,100.,100.)*step( mod(uv.x-4., 7.), 0. ); 
		pcol += COL(55.,55.,55.)*step( mod(uv.x-5., 7.), 0. ); 
		pcol = addBevel(uv, vec2(0.,17.), vec2(63.,70.), 3., 0.8, 0., -1., pcol);
		pcol = addBevel(uv, vec2(0.,45.), vec2(22.,70.), 3., 0.8, 0., -1., pcol);
		
		fgcol = COL(72.,72.,72.);
		fgcol = addBevel(uv, prisoncoords.xy, prisoncoords.zw+vec2(1.,1.), 1., 0.5, -1., 1., fgcol );
		fgcol = addBevel(uv, prisoncoords.xy+vec2(3.,3.), prisoncoords.zw-vec2(2.,1.), 1., 0.5, 1., -1., fgcol );
		fgcol = mix( fgcol, pcol, onRect( uv, prisoncoords.xy+vec2(3.,3.), prisoncoords.zw-vec2(3.,2.) ) );
		fgcol = mix( fgcol, COL(72.,72.,72.), onRect( uv, vec2(15.,32.5), vec2(21.,44.) ) );
		
		fgcol = mix( fgcol, mix( COL(0.,0.,0.), COL(43.,43.,43.), (uv.y-37.) ), stepeq(uv.x, 15.)*step(37.,uv.y)*step(uv.y,38.) );
		fgcol = mix( fgcol, mix( COL(0.,0.,0.), COL(43.,43.,43.), (uv.y-37.)/3. ), stepeq(uv.x, 17.)*step(37.,uv.y)*step(uv.y,40.) );
		fgcol = mix( fgcol, COL(43.,43.,43.), stepeq(uv.x, 18.)*step(37.,uv.y)*step(uv.y,41.) );
		fgcol = mix( fgcol, mix( COL(0.,0.,0.), COL(100.,100.,100.), (uv.y-37.)/3. ), stepeq(uv.x, 18.)*step(36.,uv.y)*step(uv.y,40.) );
		fgcol = mix( fgcol, COL(43.,43.,43.), stepeq(uv.x, 19.)*step(37.,uv.y)*step(uv.y,40.) );

		fgcol = mix( fgcol, mix( COL(84.,84.,84.), COL(108.,108.,108.), (uv.x-15.)/2. ), stepeq(uv.y, 32.)*step(15.,uv.x)*step(uv.x,17.) );
		fgcol = mix( fgcol, COL(81.,81.,81.), stepeq(uv.y, 32.)*step(20.,uv.x)*step(uv.x,21.) );

		col = mix( col, fgcol, onRect( uv, prisoncoords.xy, prisoncoords.zw ) );
	}	
// fake 8-bit color palette and dithering	
	col = floor( (col+0.5*mod(uv.x+uv.y,2.)/32.)*32.)/32.;
}

// store functions

ivec4 LoadVec4( in ivec2 vAddr ) {
    return ivec4( texelFetch( iChannel0, vAddr, 0 ) );
}

bool AtAddress( ivec2 p, ivec2 c ) { return all( equal( floor(vec2(p)), vec2(c) ) ); }

void StoreVec4( in ivec2 vAddr, in ivec4 vValue, inout vec4 fragColor, in ivec2 fragCoord ) {
    fragColor = AtAddress( fragCoord, vAddr ) ? vec4(vValue) : fragColor;
}

// map

vec4 debugMap( in vec2 fragCoord ) {
    ivec4 ud1 = LoadVec4( ivec2(0,32 ) );
   	ivec2 uv = ivec2(fragCoord.xy * .1);
    vec4 col = vec4(1);
    if( uv.x < 32 && uv.y < 32 ) {
        vec4 wall = texelFetch(iChannel0, uv, 0);
        vec4 monster = texelFetch(iChannel0, uv+ivec2(32,0),0);
        
        if( wall.x > 0. ) col.rgb = vec3(0,0,0);
        if( wall.x > 1. ) col.rgb = vec3(0,1,0);
        if( wall.x > 2. ) col.rgb = vec3(0,0,1);
        if( wall.x > 5. ) col.rgb = vec3(0,1,1);
        if( monster.x > 0. ) col.rgb = vec3( monster.y<0.?1.:.5,0,0);
    }
    if( uv.x == ud1.x && uv.y == ud1.y ) col = vec4(1,0,1,1);
    return col;
}

// draw level

vec4 drawSword( vec2 uv, int level ) {
    uv = floor(fract(uv)*64.) - 32.;
    if( abs(uv.x) < 16. && abs(uv.y) < 16. ) {
        float l = step(abs(uv.y), .5); 
        l = max(l, step(abs(uv.y), 1.5) * step(uv.x, 13.));   
        l = max(l, step(abs(uv.y), 5.5) * step(abs(uv.x+9.), 1.));
                        
	    vec3 col = mix( vec3(.8), vec3(.5,.3,.2), step(uv.x, -11.));
        vec3 scol = mix( vec3(.5,.3,.2), vec3(1.), clamp(float(level) / float(MAXSWORD/2), 0., 1.) );
        scol = mix( scol, vec3(0.,.9, 1.), clamp(float(level-MAXSWORD/2) / float(MAXSWORD/2), 0., 1.) );
        col = mix( scol, col, step(uv.x, -8.));        
        
        return vec4( 2. * l * (.5 + .5 * texture(iChannel1, uv/64.).x) * col, l );
    } else {
        return vec4(0);
    }
}

vec4 drawKey( vec2 uv, int color ) {
    uv = floor(fract(uv)*64.) - 32.;
    if( abs(uv.x) < 16. && abs(uv.y) < 16. ) {
        float l = step(abs(uv.y), 1.);
        l = max(l, step(length(uv+vec2(8,0)), 7.5));
        l -= step(length(uv+vec2(8,0)), 4.5);
        l = max(l, step(6.,uv.x)*step(uv.x, 7.)*step(0.,uv.y)*step(abs(uv.y), 5.));
        l = max(l, step(10.,uv.x)*step(uv.x, 11.)*step(0.,uv.y)*step(abs(uv.y), 7.));
        l = max(l, step(14.,uv.x)*step(0.,uv.y)*step(abs(uv.y), 6.));
        
	    vec3 col = vec3(0);
    	col[color-7] = 1.;
        return vec4( 2. * l * (.5 + .5 * texture(iChannel1, uv/64.).x) * col, l );
    } else {
        return vec4(0);
    }
}

vec4 drawLock( vec2 uv, int color ) {
    uv = floor(fract(uv)*64.) - 32.;
    if( abs(uv.x) < 6. && abs(uv.y) < 8. ) {
        float l = 1.;
        l -= smoothstep( 3., 2., length(uv+vec2(0,2.5)));
        l = min( l, 1.-step(abs(uv.x),.5)*step(abs(uv.y), 5.));
	    vec3 col = vec3(0);
    	col[color-3] = 1.;
        return vec4( l * (.5 + .5 * texture(iChannel1, uv/64.).x) * col, 1 );
    } else {
        return vec4(0);
    }
}

vec4 drawHealth( vec2 uv ) {
    uv = floor(fract(uv)*64.) - 32.;
    if( abs(uv.x) < 12. && abs(uv.y) < 12. ) {
        vec4 col = vec4( 1,1,1, smoothstep( 10., 9., length(uv)) );
        col.rgb = mix( col.rgb, vec3(1,0,0), step(abs(uv.y), 1.)*step(abs(uv.x),7.) );
        col.rgb = mix( col.rgb, vec3(1,0,0), step(abs(uv.y), 7.)*step(abs(uv.x),1.) );
        return vec4( 2.*col.rgb * (.5 + .5 * texture(iChannel1, uv/64.).x), col.a );
    } else {
        return vec4(0);
    }
}


vec3 getLight( vec3 pos, float d, vec3 nor ) {
    return vec3(0.,0.05, 0.2) * smoothstep(0., 6., d) * smoothstep(6., 5.5, d) + // fog
        (0.5 + 0.4*dot(nor, -USERRD)) 
        * (1. + .025*sin(iTime * 20. + cos(iTime*10.))) * vec3(1., .9, .6) * clamp(7./(d*d)-.1, 0., 1.);
}

void getCeilingColor( const vec3 ro, const vec3 rd, inout vec3 col ) {
	float d = -(ro.y-1.)/rd.y;
	vec3 pos = ro + rd * d;
    col = texture(iChannel1, floor(pos.xz*64.)/64.,0.).rgb * vec3(.5, .4, .3);
    col *= getLight(pos, d, vec3(0,-1,0)) * .8;
}

void getFloorColor( const vec3 ro, const vec3 rd, inout vec3 col ) {
	float d = -(ro.y)/rd.y;
	vec3 pos = ro + rd * d;
    col = texture(iChannel1, floor(pos.xz*64.)/64.,0.).rgb * vec3(.5, .4, .3) * 1.2;
    
    ivec4 map = w(ivec2(pos.xz));
    if( map.x > 8 ) {
        vec4 s = drawHealth(pos.xz);
        col = mix(col, s.rgb, s.a);
    } else if( map.x > 6 ) { // key
        vec4 s = drawKey( pos.xz, map.x );
        col = mix( col, s.rgb, s.a);
    } else if( map.x > 5 ) {
        vec4 s = drawSword( pos.xz, map.z );
        col = mix( col, s.rgb, s.a);
    }
    
    col *= getLight(pos, d, vec3(0,1,0));
}

bool getMapColorForPosition( 
    const vec3 ro, const vec3 rd, const vec3 vos, 
    const vec3 pos, const vec3 nor, const float t, in ivec4 map, inout vec3 col ) {
    
    if( map.x > 1) {
        if( map.x < 6 ) {
        // a door is hit
            float h = .95*min(float(map.w),float(DOORMOVESTEPS))/float(DOORMOVESTEPS);
            vec3 mpos = vec3( vos.x+.5, .5+h, vos.z+.5);
            vec3 nn;
            vec3 dim = map.y == 1 ? vec3(.025, .5, .5) : vec3(.5, .5, .025 );
            vec2 intersect = boxIntersection(ro - mpos, rd, dim, nn);
            vec3 p = ro + rd * intersect.x;

            if( intersect.x > 0. && p.y < 1.) {
                vec2 i = map.y == 1 ? p.yz : p.yx; 
                i.x -= h;
                vec2 uv = floor(i*64.);
                col = (.2+.5*texture(iChannel1,uv/64.,0.).rgb) * vec3(1.,.6, .4);
                col.rgb *= .5 + .5*step( 1., mod(uv.y, 8.) );
                if( map.x > 2) {
                	vec4 s = drawLock( -i.yx, map.x );
                	col = mix( col, s.rgb, s.a);
                }
                col *= getLight(p, intersect.x, nn);         
                return true;
            }
        }
        return false;
    } else {    
 		if( pos.y <= 1. && pos.y >= 0. ) {
	    // a wall is hit
        	vec2 mpos = vec2( dot(vec3(-nor.z,0.0,nor.x),pos), -pos.y );
            vec2 uv = floor(mpos*64.);
        	col = texture(iChannel2, uv/64.,0.).rgb * .7;  
            decorateWall( uv, hash12(vos.xz), col.rgb );        
        	col *= getLight(vos, t, vec3(nor.x,0,nor.z));
        	return true;
    	}
    }
    return false;
}

bool getMonsterColorForPosition( 
    const vec3 ro, const vec3 rd, const vec3 vos, 
    const vec3 pos, const vec3 nor, const float t, inout vec3 col,
	ivec4 monster ) {
    
    vec3 mpos = vec3( vos.x+.5, .5, vos.z+.5);
    if( monster.y != 0 ) {
	    mpos.xz += float(monster.y)/float(MOVESTEPS) * vec2(DIRECTION[monster.z-1]);
    }
    
    vec3 nn;
    vec3 roo = ro-mpos+ sin(rd*1e2+5.*iTime)*.0025;
    vec3 rdd = rd + sin(rd*70.+iTime)*.01;
    
    float size = .2 + .025*smoothstep( 0., 30., float(monster.w));
    
    vec2 intersect = boxIntersection(roo, rdd, vec3(size), nn);
    if( intersect.x > 0.) {
       col = mix( vec3(.5,0,0), vec3(0,1,0), float(monster.w)/30.);
       col.b = .5+.5*sin(iTime);
       vec3 i = intersect.x*rd+ro-mpos;
       vec2 texUV;
       if( abs(nn.x) > .5 ) {
           texUV = i.yz;
       } else {
           texUV = i.xy;           
       }
       texUV += vec2(sin(iTime*5.+20.*texUV.y),cos(iTime*4.+20.*texUV.x))*.01;
       col *= .5 +.5*texture(iChannel1, floor(texUV*64.)/64.,0.).x;
        float hl = hash13( floor(vec3(texUV*64.,iTime+hash12(floor(texUV*64.)))));
       col += .2 * hl * hl * hl;
       col = mix( col, normalize(i)*.5+.5, .25);
       col *= getLight(intersect.x*rd+ro, intersect.x, nn) *(.5 + smoothstep(4., 1., intersect.x) * .1/dot(i,i));
       return true;
    }
    
    return false;
}

bool castRay( const vec3 ro, const vec3 rd, inout vec3 col ) {
	vec3 pos = floor(ro);
	vec3 ri = 1.0/rd;
	vec3 rs = sign(rd);
	vec3 dis = (pos-ro + 0.5 + rs*0.5) * ri;
	
	float res = 0.0;
	vec3 mm = vec3(0.0);
	bool hit = false;
	
	for( int i=0; i<MAXSTEPS; i++ )	{
		mm = step(dis.xyz, dis.zyx);
		dis += mm * rs * ri;
        pos += mm * rs;		
        
		vec3 mini = (pos-ro + 0.5 - 0.5*vec3(rs))*ri;
		float t = max ( mini.x, mini.z );	
        
        ivec4 map = w(ivec2(pos.xz));
        
        
        vec3 h = ro + rd*t;     
        if( h.y > 1. || h.y < 0. ) {
            if( rd.y < 0. ) {
                getFloorColor(ro, rd, col);
            } else {
                getCeilingColor(ro, rd, col);
            }
            return true;
        }
        
		if( map.x > 0 ) { 		
			hit = getMapColorForPosition( ro, rd, pos, ro+rd*t, -mm*sign(rd), t, map, col );
        }
        ivec4 monster = m(ivec2(pos.xz));
        if( monster.x > 0 && !hit) { 		
			hit = getMonsterColorForPosition( ro, rd, pos, ro+rd*t, -mm*sign(rd), t, 
                                                  col, monster );
        }
        if( hit ) return true;
	}
	return hit;
}

vec4 render(in vec2 fragCoord) {
    float time = iTime;
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= iResolution.x/ iResolution.y;
	
	vec3 ro = vec3( mod(iTime, 31.) + 1.,.5, mod(iTime*1.1, 31.) + 1. );
    
    ivec4 ud1 = LoadVec4( ivec2(0,32 ) );
    ivec4 ud2 = LoadVec4( ivec2(1,32 ) );
    
    vec2 USERCOORD = vec2(ud1.xy);
    int USERDIR = ud1.z;
    int actionCount = ud1.w;
    int action = ud2.x;
 
    vec3 dir = vec3(DIRECTION[USERDIR].x, 0, DIRECTION[USERDIR].y);
    
    ro = vec3(USERCOORD.x + .5, .5, USERCOORD.y + .5 );
    float angle = 0.;
    
    if( action == FORWARD ) {
        float progress = float(actionCount)/float(USERMOVESTEPS);
        ro -= dir * progress;
    }
	if( action == BACK ) {
        float progress = float(actionCount)/float(USERMOVESTEPS);
        ro += dir * progress;
    }
    if( action == ROT_RIGHT ) {
        float progress = float(actionCount)/float(USERROTATESTEPS);
        angle = -progress * 1.57079632679;
    }
    if( action == ROT_LEFT ) {
        float progress = float(actionCount)/float(USERROTATESTEPS);
        angle = progress * 1.57079632679;
    }
    
    
    vec3 rd = rotate( dir, angle );
    USERRD = rd;
    rd.y -= 0.025;
    vec3 uu = normalize(cross( vec3(0.,1.,0.), rd ));
    vec3 vv = normalize(cross(rd,uu));
    rd = normalize( p.x*uu + p.y*vv + 2.25*rd );
    
	vec3 col = vec3(0.);
    castRay( ro, rd, col );
    return vec4(col,1);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec4 col = debugMap( fragCoord );
    col = render( fragCoord );
   // col = mix( col, debugMap( fragCoord ), .5);
    
    int flash = ivec4( texelFetch( iChannel3, ivec2(0), 0 ) ).y;
    
    col.rgb = mix( col.rgb, vec3(1,0,0), float(flash) / 120. );
    
    vec4 ui = texture(iChannel3, fragCoord/iResolution.xy);    
    col = mix( col, ui, min(1.,ui.a) );
    
	fragColor = col;
}