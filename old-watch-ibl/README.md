# Old watch (IBL)
[View shader on Shadertoy](https://www.shadertoy.com/view/lscBW4) - _Published on 2018-04-30_ 

![thumbnail](./thumbnail.jpg)


This shader uses Image Based Lighting (IBL) to render an old watch. The
materials of the objects have physically-based properties.

A material is defined by its albedo and roughness value and it can be a
metal or a non-metal.

I have used the IBL technique as explained in the article 'Real Shading in
Unreal Engine 4' by Brian Karis of Epic Games.[1] According to this article,
the lighting of a material is the sum of two components:

1. Diffuse: a look-up (using the normal vector) in a pre-computed environment map.
2. Specular: a look-up (based on the reflection vector and the roughness of the
material) in a pre-computed environment map, combined with a look-up in a
pre-calculated BRDF integration map (Buf B).

Note that I do NOT (pre)compute the environment maps needed in this shader. Instead,
I use (the lod levels of) a Shadertoy cubemap that I have remapped using a random
function to get something HDR-ish. This is not correct and not how it is described
in the article, but I think that for this scene the result is good enough.

I made a shader that renders this same scene using a simple path tracer. You can
compare the result here:

https://www.shadertoy.com/view/MlyyzW

[1] http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf



## Shaders

### Common

Source: [Common.glsl](./Common.glsl)

### Buffer A

Source: [Buffer A.glsl](./Buffer&#32;A.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png) _(mipmap, repeat, vflipped)_
 * **iChannel2**: [texture](https://shadertoy.com/media/a/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg) _(mipmap, repeat, vflipped)_

### Buffer B

Source: [Buffer B.glsl](./Buffer&#32;B.glsl)

#### Inputs

 * **iChannel0**: Buffer B _(linear, clamp, vflipped)_

### Image

Source: [Image.glsl](./Image.glsl)

#### Inputs

 * **iChannel0**: cubemap _(mipmap, repeat, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/1f7dca9c22f324751f2a5a59c9b181dfe3b5564a04b724c657732d0bf09c99db.jpg) _(mipmap, repeat, vflipped)_
 * **iChannel2**: Buffer A _(linear, clamp, vflipped)_
 * **iChannel3**: Buffer B _(linear, clamp, vflipped)_

## Links
* [Old watch (IBL)](https://www.shadertoy.com/view/lscBW4) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy
* [http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf](http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf)

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.](https://creativecommons.org/licenses/by-nc-sa/3.0/)
