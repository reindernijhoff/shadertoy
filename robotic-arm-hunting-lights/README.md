# Robotic Arm Hunting Lights
[View shader on Shadertoy](https://www.shadertoy.com/view/tlSSDV) - _Published on 2019-08-29_ 

![thumbnail](./thumbnail.jpg)


This shader is a proof of concept to find out if I could
create a “typical” Shadertoy shader, i.e. a shader that renders
a non-trivial animated 3D scene, by using a ray tracer instead
of the commonly used raymarching techniques.

Some first conclusions:

- It is possible to visualize an animated 3D scene in a single
shader using ray tracing.
- The compile-time of this shader is quite long.
- The ray tracer is not super fast, so it was not possible to cast
enough rays per pixel to support global illumination or soft
shadows. Here I miss the cheap AO and soft shadow algorithms that
are available when raymarching an SDF.
- Modelling a 3D scene for a ray tracer in code is verbose. It was
not possible to exploit the symmetries in the arm and the domain
repetition of the sphere-grid that would have simplified the
description of an SDF.
- I ran in GPU-dependent unpredictable precision problems. Hopefully,
most problems are solved now. I’m not sure if they are inherent
to ray tracing, but I didn’t have these kinds of problems using
raymarching before.


## Shaders

### Image

Source: [Image.glsl](./Image.glsl)

## Links
* [Robotic Arm Hunting Lights](https://www.shadertoy.com/view/tlSSDV) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.](https://creativecommons.org/licenses/by-nc-sa/4.0/)
