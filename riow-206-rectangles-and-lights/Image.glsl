// Ray tracing: the next week, chapter 6: Rectangles and lights. Created by Reinder Nijhoff 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/4tGcWD
//
// These shaders are my implementation of the raytracer described in the (excellent) 
// book "Ray tracing in one weekend" and "Ray tracing: the next week"[1] by Peter Shirley 
// (@Peter_shirley). I have tried to follow the code from his book as much as possible, but 
// I had to make some changes to get it running in a fragment shader:
//
// - There are no classes (and methods) in glsl so I use structs and functions instead. 
//   Inheritance is implemented by adding a type variable to the struct and adding ugly 
//   if/else statements to the (not so overloaded) functions.
// - The scene description is procedurally implemented in the world_hit function to save
//   memory.
// - The color function is implemented using a loop because it is not possible to have a 
//   recursive function call in glsl.
// - Only one sample per pixel per frame is calculated. Samples of all frames are added 
//   in Buffer A and averaged in the Image tab.
//
// Besides that, I also made some other design choices. Most notably:
//
// - In my code ray.direction is always a unit vector so I could clean up the rest of
//   the code by removing some implicit normalizations.
// - Cosine weighted hemisphere sampling is used for the Lambertian material.
//
// You can find the raytracer / pathtracer in Buffer A.
//
// = Ray tracing in one week =
// Chapter  7: Diffuse                           https://www.shadertoy.com/view/llVcDz
// Chapter  9: Dielectrics                       https://www.shadertoy.com/view/MlVcDz
// Chapter 11: Defocus blur                      https://www.shadertoy.com/view/XlGcWh
// Chapter 12: Where next?                       https://www.shadertoy.com/view/XlycWh
//
// = Ray tracing: the next week =
// Chapter  6: Rectangles and lights             https://www.shadertoy.com/view/4tGcWD
// Chapter  7: Instances                         https://www.shadertoy.com/view/XlGcWD
// Chapter  8: Volumes                           https://www.shadertoy.com/view/XtyyDD
// Chapter  9: A Scene Testing All New Features  https://www.shadertoy.com/view/MtycDD
//
// [1] http://in1weekend.blogspot.com/2016/01/ray-tracing-in-one-weekend.html
//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord),0);
    fragColor = vec4(sqrt(data.rgb/data.w),1.0);
}