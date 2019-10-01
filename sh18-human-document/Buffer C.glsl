// [SH18] Human Document. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XtcyW4
//
//   * Created for the Shadertoy Competition 2018 *
//
// Buffer C: Additional custom animation of the bones is calculated for the start
//           and end of the loop.
//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    ivec2 f = ivec2(fragCoord);
    
    if (f.x > 0 || f.y > NUM_BONES) return;
    
    initAnimation(iTime);
    
    vec3 animPos = texelFetch(iChannel0, f, 0).xyz;
    animPos.y = max(animPos.y - planeY, 1.);
    
    vec3 startPos = vec3(animPos.x,-9,animPos.z);
    
    float t = mod(offsetTime(iTime), DURATION_TOTAL);
    vec3 pos = animPos;
	
    if (t < DURATION_START + DURATION_MORPH_ANIM) {
        float tm = t-(DURATION_START-DURATION_MORPH_STILL);
        if ( tm > 0.) {
            pos = mix(startPos, animPos, smoothstep(0.,1., tm / DURATION_MORPH));
        } else {
            pos = startPos;
        }
        
        if (f.y == HEAD) {
            pos.y = max(pos.y, 1.); 
            
            float tf = max(0., (t-DURATION_START*.5))*2.;
            float atm = clamp(1.-max(0.,tf/(DURATION_START+DURATION_MORPH_ANIM)), 0., 1.);
            float maxf = 50.f * atm*atm*atm*atm;
            float freq = min(10.,1.75/(.2+atm*atm));
            float h = maxf * abs(cos(freq*tf)); 
            pos.y += h;
        }
    } else if (t > DURATION_START + DURATION_ANIM - DURATION_MORPH_ANIM) {
        float tm = t-(DURATION_START + DURATION_ANIM - DURATION_MORPH_ANIM);
        if ( tm > 0.) {
            pos = mix(startPos, animPos, smoothstep(1.,0., tm / DURATION_MORPH));
        } else {
            pos = startPos;
        }
        
        if (f.y == HEAD) {
            pos.y = max(pos.y, 1.); 
            pos.xz += max(0.,tm) * vec2(3.5,30.);
        }
    } 
    
    
    pos = pos*.11;
    pos.z -= .5;
    
    fragColor = vec4(pos, 1.);
}