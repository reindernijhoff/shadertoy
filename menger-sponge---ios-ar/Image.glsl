// Menger Sponge - iOS AR. Created by Reinder Nijhoff 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/XttfRN
//
// This is an experiment to create an "AR shader" by implementing the mainVR-function and 
// using the WebCam texture as background. If you view this shader with the Shadertoy iOS 
// app[1], you can walk around the cube to view it from all sides.
//
// If you don't have an iOS device (or if you don't have the app installed) you can find a
// screen capture of the shader in action here: https://youtu.be/7woT6cTx-bo.
//
// The SDF of this shader is based on the "Menger Sponge" shader by Íñigo Quílez:
// https://www.shadertoy.com/view/4sX3Rn
//
// [1] https://itunes.apple.com/us/app/shadertoy/id717961814
//

float sdBox( vec3 p, vec3 b ) {
  vec3  di = abs(p) - b;
  float mc = max(di.x,max(di.y,di.z));
  return min(mc,length(max(di,0.0)));
}

float boxIntersect( in vec3 ro, in vec3 rd, in vec3 rad ) {
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	if( tN > tF || tF < 0.0) return 1e30;
	return tN;
}

float map( in vec3 p ) {
    float d = sdBox(p,vec3(1.0));
    float s = .5;
    for( int m=0; m<4; m++ ) {
        vec3 a = fract( p*s )-.5;
        s *= 3.;
        vec3 r = abs(1.-6.*abs(a));
        float da = max(r.x,r.y);
        float db = max(r.y,r.z);
        float dc = max(r.z,r.x);
        float c = (min(da,min(db,dc))-1.0)/(2.*s);

        if( c>d ) {
          d = c;
        }
    }
    return d;
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax ) {
	float res = 1.0;
    float t = mint;
    float ph = 1e10; 
    for( int i=0; i<32; i++ ) {
		float h = map( ro + rd*t );
       	float y = h*h/(2.0*ph);
        float d = sqrt(max(0.,h*h-y*y));
        res = min( res, 8.0*d/max(0.0001,t-y) );
        ph = h;
        t += h;//min(h, .1);// clamp( h, 0.02, 0.10 );
        if( res<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAO( in vec3 pos, in vec3 nor ) {
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ ) {
        float hr = 0.01 + 0.5*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.9;
    }
    return clamp( 1. - 3.0*occ, 0.0, 1.0 );    
}

vec3 calcNormal(in vec3 pos) {
    vec3  eps = vec3(.001,0.0,0.0);
    vec3 nor;
    nor.x = map(pos+eps.xyy) - map(pos-eps.xyy);
    nor.y = map(pos+eps.yxy) - map(pos-eps.yxy);
    nor.z = map(pos+eps.yyx) - map(pos-eps.yyx);
    return normalize(nor);
}

vec4 tex3D( sampler2D sam, in vec3 p, in vec3 n ) {
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );

	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv, in sampler2D tex ) {
    ro *= 2.; // scale scene
    const float tmax = 100.;
    vec3 lightDir = normalize(vec3(0.7,1.,.2));
    float tmin = boxIntersect(ro, rd, vec3(1.));
    if (all(lessThan(abs(ro),vec3(1)))) tmin = 0.01;
    
    float t = tmin;
    for( int i=0; i<64; i++ ) {
	    float precis = 0.001*t;
	    float d = map( ro+rd*t );
        if( abs(d)<precis || t>tmax ) break;
        t += d;
    }
    
    vec3 col = texture(tex, uv).xyz;
    // Use mipmap level 9 to get an average environment color from the webcam texture
    // used for lighting.
    vec3 lightColor = pow(.25 + .75 * texelFetch(tex, ivec2(0), 9).rgb, vec3(2.2)) * 3.;
    
    if (t < tmax) {
        vec3 p = ro + t * rd;
  		vec3 n = calcNormal(p);
        vec3 ref = reflect(rd, n);

        float ao = .4 + .6 * calcAO(p, n);
        float sh = .4 + .6 * calcSoftshadow(p, lightDir, 0.005, 1.);
    
        float diff = max(0.,dot(lightDir,n)) * ao * sh;
        float amb  = (.4+.2*n.y) * ao * sh;
		float spe = pow(clamp(dot(ref,lightDir), 0., 1.),8.) * sh * .5;
           
        vec3 mat = tex3D(iChannel2, p, n).rgb;
        col = (amb + diff) * mix(vec3(.4,.6,.8),vec3(.1,.2,.3),mat.r) + spe * dot(mat,mat);
        col *= lightColor;
    }
    
    // gamma
    col = mix(col, sqrt(clamp(col,vec3(0),vec3(1))), .95);
    
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
    vec3 ro = 2. * vec3( sin(a), .1, cos(a) );
    vec3 ta = vec3( 0.0, 0., 0.0 );
    
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    vec3 col = render( ro, rd, fragCoord.xy/iResolution.xy, iChannel1 );
    fragColor = vec4(col,1.0);
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 ro, in vec3 rd ) {
    ro += vec3(0,0.5,1.5);
    vec3 col = render( ro, rd, fragCoord.xy/iResolution.xy, iChannel0 );
    fragColor = vec4(col,1.0);
}