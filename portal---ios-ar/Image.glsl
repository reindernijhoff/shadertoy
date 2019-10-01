// Portal - iOS AR. Created by Reinder Nijhoff 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/lldcR8
//
// This is an experiment to create an "AR shader" by implementing the mainVR-function and 
// using the WebCam texture as background. If you view this shader with the Shadertoy iOS 
// app[1], you can walk around and enter the portal.
//
// If you don't have an iOS device (or if you don't have the app installed) you can find a
// screen capture of the shader in action here: https://youtu.be/IzeeoD0e6Ow.
//
//
// Common tab: The VR-scene is shaded using analytical area lighting. I have used code of
//             dys129 shader "Analytic Area Light" to implement this technique:
//             https://www.shadertoy.com/view/4tXSR4
//
// Buffer A:   Buffer A keeps track of the camera-position and calculates if the user has
//             entered the portal.
//
// Image tab:  A raymarcher is used to render the VR scene.
//
// [1] https://itunes.apple.com/us/app/shadertoy/id717961814
//

float hash12( vec2 p ) {
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float noise( in vec2 x ) {
    vec2 f = fract(x);
    vec2 u = f*f*(3.0-2.0*f);
    
    vec2 p = vec2(floor(x));
    float a = hash12( (p+vec2(0,0)) );
	float b = hash12( (p+vec2(1,0)) );
	float c = hash12( (p+vec2(0,1)) );
	float d = hash12( (p+vec2(1,1)) );
    
	return a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y;
}

const mat2 m2 = mat2(1.6,-1.2,1.2,1.6);

float fbm( in vec2 p, const int OCTAVES ) {
    float a = 0.;
    float b = .5;
    for( int i=0; i<OCTAVES; i++ ) {
        a += noise(p) * b;
		b *= 0.5;
        p = m2*p;
    }
	return a;
}

float iPlane( in vec3 ro, in vec3 rd, in vec4 pla ) {
    return (-pla.w - dot(pla.xyz,ro)) / dot( pla.xyz, rd );
}

float map( in vec3 p ) {
    p.xz += PILLAR_SPACING *.5;
    float d = p.y;
    
    vec2 pm = mod( p.xz + vec2(PILLAR_SPACING*.5), 
                  		  vec2(PILLAR_SPACING) ) - vec2(PILLAR_SPACING*.5);
    d = min(d, max(abs(pm.x) - PILLAR_WIDTH_HALF, abs(pm.y) - PILLAR_WIDTH_HALF));
    
    vec2 cm = mod( p.xz,  vec2(PILLAR_SPACING) ) - vec2(PILLAR_SPACING*.5);
    
    d = min( d, CEILING_HEIGHT - p.y );
    d = max( d, -PILLAR_WIDTH_HALF+PILLAR_SPACING*.5-
            length( vec2(p.y-CEILING_HEIGHT, min(abs(cm.x),abs(cm.y)))));
    return d;
}

vec4 tex3D( sampler2D sam, in vec3 p, in vec3 n ) {
    p.xz = mat2(0.8,-0.6,0.6,0.8) * p.xz + .5;
    
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );

	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

vec3 calcNormal( in vec3 pos ) {
    vec2 e = vec2(1.0,-1.0)*0.0001;
    return normalize( e.xyy*map( pos + e.xyy ) + 
					  e.yyx*map( pos + e.yyx ) + 
					  e.yxy*map( pos + e.yxy ) + 
					  e.xxx*map( pos + e.xxx ) );
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax ) {
	float res = 1.0;
    float t = mint;
    float ph = 1e10; 
    for( int i=0; i<24; i++ ) {
		float h = map( ro + rd*t );
       	float y = h*h/(2.0*ph);
        float d = sqrt(max(0.,h*h-y*y));
        res = min( res, 8.0*d/max(0.01,t-y) );
        ph = h;
        t += min(h, .2);// clamp( h, 0.02, 0.10 );
        if( res<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAO( in vec3 pos, in vec3 nor ) {
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.3*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.75;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv, in sampler2D sam, bool inside ) {
    float portalAlpha = 0.;
    vec3 fogColor = vec3(0.1,0.3,.5) + rd * .1;
    float tmin = 0.01;
    const float tmax = 21.;
    
    vec3 portalColor = texture(sam, uv).rgb * 1.25;
    // Use mipmap level 9 to get an average environment color from the webcam texture
    // used for lighting.
    vec3 lightColor = pow(.25 + .75 * texelFetch(sam, ivec2(0), 9).rgb, vec3(2.2)) * 3.;
      
    // portal intersection
    float portalDist = iPlane( ro, rd, vec4(0,0,1,-dot(PORTAL_POS,vec3(0,0,1))));
    if (portalDist < 0.) {
        portalDist = 5e5;
    } else {
        vec3 p = ro + rd * portalDist;
        float time = iTime * .15;
        float scale = 6.;
        vec2 offset = vec2(fbm(p.xy * scale + time, 4), fbm(p.yx * scale - time, 4)) -.5;
        p.xy += (fbm(offset * scale + time, 4) - .5) * .2;
        if(all(lessThan(abs(p.xy-PORTAL_POS.xy),PORTAL_SIZE.xy))) {
            vec2 bd = abs(p.xy-PORTAL_POS.xy) - (PORTAL_SIZE.xy -PORTAL_BORDER.xy);
            bd = max(bd, vec2(0))/PORTAL_BORDER.xy;
                
	        portalAlpha = 1.-smoothstep(0.5, 1., length(bd));
         }
        if(inside) {
        	tmin = portalDist;
        }
    }
    
    float t = tmin;
    for( int i=0; i<48; i++ ) {
	    float precis = 0.001*t;
	    float res = map( ro+rd*t );
        if( res<precis || t>tmax ) break;
        t += res;
    }
    
    portalAlpha = inside ? 1. - portalAlpha : portalAlpha;

    vec3 col = vec3(0);
    
    // background scene
    if (t < tmax && portalAlpha < 1.) {
        vec3 p = ro + t * rd;
        vec3 N = calcNormal(p);
        vec3 R = reflect(rd, N);
        vec3 tex = tex3D(iChannel2, p, N).rgb;

        col = vec3( tex ) * clamp(p.y+.6, 0., 1.);

        float diff = shd_polygonal(p, N, false);
        float spc = clamp(shd_polygonal(p, R, true), 0., 1.);
        float l = (diff * 6. + spc * dot(tex,tex));

        vec3 ld = p-PORTAL_POS;
        
        l *= calcSoftshadow(p, -normalize(ld), .02, length(ld)-.5);
		l *= (.5+.5*calcAO(p, N));
        col *= l * lightColor;
    }
    
    if (!inside && t < portalDist) {
        portalAlpha = 0.;
    }
    
    // height based fog, see http://iquilezles.org/www/articles/fog/fog.htm
    const float C = .075;
    const float B = 1.1;
    float fogAmount = clamp(C * exp(-ro.y*B) * (1.-exp( -t*rd.y*B))/rd.y, 0., 4.);
    col = mix( col, fogColor, fogAmount);

    // gamma
    col = mix(col, sqrt(clamp(col,vec3(0),vec3(1))), .95);
    
	col = mix( col, portalColor, portalAlpha);
    
    return clamp(col,vec3(0),vec3(1));
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr ) {
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
   
    float a = .3 * iTime;
    vec3 ro = vec3( 3.9*sin(a), 0.7, 3.2*cos(a) + .5 );
    vec3 ta = vec3( 0.25, 0.6, 0.5 );
    
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    vec3 col = render( ro, rd, fragCoord.xy/iResolution.xy, iChannel3, false);
    fragColor = vec4(col,1.0);
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 ro, in vec3 rd ) {
    ro += PORTAL_POS + START_OFFSET;
    
    vec3 col = render( ro, rd, fragCoord.xy/iResolution.xy, iChannel0, 
                      texelFetch(iChannel1, ivec2(0), 0).w > .5);
    fragColor = vec4(col,1.0);
}