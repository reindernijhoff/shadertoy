// [2TC 15] Minecraft. Created by Reinder Nijhoff 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/4tsGD7
// 

void mainImage( out vec4 z, in vec2 w ) {
    vec3 d = vec3(w,1)/iResolution-.5, p, c, f, g=d, o, y=vec3(1,2,0);
 	o.y = 3.*cos((o.x=.3)*(o.z=iDate.w));

    for( float i=.0; i<9.; i+=.01 ) {
        f = fract(c = o += d*i*.01), p = floor( c )*.3;
        if( cos(p.z) + sin(p.x) > ++p.y ) {
	    	g = (f.y-.04*cos((c.x+c.z)*40.)>.8?y:f.y*y.yxz) / i;
            break;
        }
    }
    z.xyz = g;
}

/*

// original:


void main() {
    vec3 d = gl_fragCoord.xyw/iResolution-.5, p, c, f, g=d, o, y=vec3(1,2,0);
 	o.y = 3.*cos((o.x=.3)*(o.z=iDate.w));

    for( float i=.0; i<9.; i+=.01 ) {
        f = fract(c = o += d*i*.01), p = floor( c )*.3;
        if( cos(p.z) + sin(p.x) > ++p.y ) {
	    	g = (f.y-.04*cos((c.x+c.z)*40.)>.8?y:f.y*y.yxz) / i;
            break;
        }
    }
    gl_fragColor.xyz = g;
}

*/