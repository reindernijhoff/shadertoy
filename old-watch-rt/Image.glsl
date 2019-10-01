// Old watch (RT). Created by Reinder Nijhoff 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/MlyyzW
//
// A simple path tracer is used to render an old watch. The old watch scene is
// (almost) the same scene as rendered using image based lighting in my shader "Old
// watch (IBL)":
// 
// https://www.shadertoy.com/view/lscBW4
//
// You can find the path tracer in Buffer B. I'm no expert in ray or path tracing so
// there are probably a lot of errors in this code.
//
// Use your mouse to change the camera viewpoint.
//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord), 0);
    vec3 col = data.rgb / data.w;
    
    // gamma correction
    col = max( vec3(0), col - 0.004);
    col = (col*(6.2*col + .5)) / (col*(6.2*col+1.7) + 0.06);
    
    // Output to screen
    fragColor = vec4(col,1.0);
}