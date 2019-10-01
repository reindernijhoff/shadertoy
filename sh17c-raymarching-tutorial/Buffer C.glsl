// [SH17C] Raymarching tutorial. Created by Reinder Nijhoff 2017
// @reindernijhoff
// 
// https://www.shadertoy.com/view/4dSfRc
//
// In this tutorial you will learn how to render a 3d-scene in Shadertoy
// using distance fields.
//
// The tutorial itself is created in Shadertoy, and is rendered
// using ray marching a distance field.
//
// The shader studied in the tutorial can be found here: 
//     https://www.shadertoy.com/view/4dSBz3
//
// Created for the Shadertoy Competition 2017 
//
// Most of the render code is taken from: 'Raymarching - Primitives' by Inigo Quilez.
//
// You can find this shader here:
//     https://www.shadertoy.com/view/Xds3zN
//

// COPY LAST FRAME FOR FADES

#define SLIDE_FADE_STEPS 60 

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    int SLIDE_STEPS_VISIBLE = int(texelFetch( iChannel0, ivec2(0,0), 0 ).y);
    
    if(iFrame == 0) {
  		fragColor = vec4(0,0,0,1);
    } else if(SLIDE_STEPS_VISIBLE > SLIDE_FADE_STEPS) {
  		fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);
    } else {
    	fragColor = texelFetch(iChannel2, ivec2(fragCoord), 0);
    }
}