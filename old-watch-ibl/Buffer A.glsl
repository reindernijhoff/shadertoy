// Old watch (IBL). Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/lscBW4
//
// In this buffer the albedo of the dial (red channel) and the roughness
// of the glass (green channel) is pre-calculated.
//

bool resolutionChanged() {
    return floor(texelFetch(iChannel0, ivec2(0), 0).r) != floor(iResolution.x);
}

float printChar(vec2 uv, uint char) {
    float d = textureLod(iChannel1, (uv + vec2( char & 0xFU, 0xFU - (char >> 4))) / 16.,0.).a;
	return smoothstep(1.,0., smoothstep(.5,.51,d));
}

float dialSub( in vec2 uv, float wr ) {
    float r = length( uv );
    float a = atan( uv.y, uv.x )+3.1415926;

    float f = abs(2.0*fract(0.5+a*60.0/6.2831)-1.0);
    float g = 1.0-smoothstep( 0.0, 0.1, abs(2.0*fract(0.5+a*12.0/6.2831)-1.0) );
    float w = fwidth(f);
    f = 1.0 - smoothstep( 0.2*g+0.05-w, 0.2*g+0.05+w, f );
    float s = abs(fwidth(r));
    f *= smoothstep( 0.9 - wr -s, 0.9 - wr, r ) - smoothstep( 0.9, 0.9+s, r );
    float hwr = wr * .5;
    f -= 1.-smoothstep(hwr+s,hwr,abs(r-0.9+hwr)) - smoothstep(hwr-s,hwr,abs(r-0.9+hwr));

    return .1 + .8 * clamp(1.-f,0.,1.);
}

float dial(vec2 uv) {
    float d = dialSub(uv, 0.05);

    vec2 uvs = uv;
    
    uvs.y += 0.6;
    uvs *= 1./(0.85-0.6);

    d = min(d, dialSub(uvs, 0.1));
    
    vec2 center = vec2(0.5);
    vec2 radius = vec2(3.65, 0.);
    
    for (int i=0; i<9; i++) {
        if(i!=5) {
	        float a = 6.28318530718 * float(i+4)/12.;
    	    vec2 uvt = clamp(uv * 5. + center + rotate(radius, a), vec2(0), vec2(1));
        	d = mix(d, 0.3, printChar(uvt, uint(49+i)));
        }
    }
    for (int i=0; i<3; i++) {
	    float a = 6.28318530718 * float(i+13)/12.;
    	vec2 uvt1 = clamp(uv * 5. + center + rotate(radius, a) + vec2(.25,0.), vec2(0), vec2(1));
        d = mix(d, 0.3, printChar(uvt1, uint(49)));
    	vec2 uvt = clamp(uv * 5. + center + rotate(radius, a)+ vec2(-.15,0.), vec2(0), vec2(1));
        d = mix(d, 0.3, printChar(uvt, uint(48+i)));
    }
    
    d *= .9 + .25*texture(iChannel2, uv*.5+.5).r;
    
    return pow(clamp(d, 0., 1.), 2.2);
}

float roughnessGlass(vec2 uv) {
    uv = uv * .5 + .5;
    return smoothstep(0.2, 0.8, texture(iChannel2, uv * .3).r) * .4 + .2;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {   
    if(resolutionChanged() && iChannelResolution[1].x > 0.  && iChannelResolution[2].x > 0.) {
        if (fragCoord.x < 1.5 && fragCoord.y < 1.5) {
            fragColor = floor(iResolution.xyxy);
        } else {
            vec2 uv = (2.0*fragCoord.xy-iResolution.xy)/iResolution.xy;

            fragColor = vec4( dial(uv), roughnessGlass(uv), 0., 1.0 );      
        }
    } else {
        fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    }
}