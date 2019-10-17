# Old watch (RT)
[View shader on Shadertoy](https://www.shadertoy.com/view/MlyyzW) - _Published on 2018-08-26_ 

![thumbnail](./thumbnail.jpg)


A simple path tracer is used to render an old watch. The old watch scene is
(almost) the same scene as rendered using image based lighting in my shader "Old
watch (IBL)":

https://www.shadertoy.com/view/lscBW4

You can find the path tracer in Buffer B. I'm no expert in ray or path tracing so
there are probably a lot of errors in this code.

Use your mouse to change the camera viewpoint.


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

 * **iChannel0**: cubemap _(mipmap, clamp, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/1f7dca9c22f324751f2a5a59c9b181dfe3b5564a04b724c657732d0bf09c99db.jpg) _(mipmap, repeat, vflipped)_
 * **iChannel2**: Buffer A _(linear, clamp, vflipped)_
 * **iChannel3**: Buffer B _(linear, clamp, vflipped)_

### Image

Source: [Image.glsl](./Image.glsl)

#### Inputs

 * **iChannel0**: Buffer B _(linear, clamp, vflipped)_

## Links
* [Old watch (RT)](https://www.shadertoy.com/view/MlyyzW) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.](https://creativecommons.org/licenses/by-nc-sa/4.0/)
