// Contrast speed illusion. Created by Reinder Nijhoff 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
// 
// https://www.shadertoy.com/view/MtfBDN
//
// Both rectangles are moving at exactly the same speed.
//
// Based on the flash implementation by Jim Cash: https://scratch.mit.edu/projects/188838060/
//
// Research paper:
//
// https://quote.ucsd.edu/anstislab/files/2012/11/2001-Footsteps-and-inchworms.pdf
//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy;
    float scale = iResolution.x / 300.;
    
    float fade = smoothstep(0.1,0.2,abs(fract(iTime*.05+.5)-.5));
    
    vec3 bgpattern = vec3(round(fract(uv.x*20.*scale)-.02*scale));
    // vec3 bgpattern = .6+.6*cos(6.28*uv.x*20.*scale+vec3(0,-2.1,2.1));
    // vec3 bgpattern = vec3(.5+.5*sin(6.28*uv.x*20.*scale));
    
    vec3 c = mix(vec3(.7), bgpattern, fade);
    
    float p = fract(iTime*.1/scale);
    float x = step(uv.x,p+.3/scale)*step(p,uv.x);
    
    c = mix(c, vec3(1,1,0), x*step(abs(uv.y-.3),.03));
    c = mix(c, vec3(0,0,0.7), x*step(abs(uv.y-.7),.03));
    
	fragColor = vec4(c,1.0);
}