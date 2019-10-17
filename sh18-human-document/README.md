# [SH18] Human Document
[View shader on Shadertoy](https://www.shadertoy.com/view/XtcyW4) - _Published on 2018-07-25_ 

![thumbnail](./thumbnail.jpg)


* Created for the Shadertoy Competition 2018 *

07/29/2018 I have made some optimizations and bugfixes, so I could enable AA.

!! Please change AA (line 47) to 1 if your framerate is below 60
(or if you're running the shader fullscreen).

This shader uses motion capture data to animate a humanoid. The animation data is
compressed by storing only a fraction of the coeffecients of the Fourier transform
of the positions of the bones (Buffer A). An inverse Fourier transform is used to
reconstruct the data needed.

Image Based Lighting (IBL) is used to render the scene. Have a look at my shader
"Old watch (IBL)" (https://www.shadertoy.com/view/lscBW4) for a clean implementation
of IBL.

Buffer A: I have preprocessed a (motion captured) animation by taking the Fourier
transform of the position of all bones (14 bones, 760 frames). Only a fraction
of all calculated coefficients are stored in this shader: the first
coefficients with 16 bit precision, later coefficients with 8 bit. The positions
of the bones are reconstructed each frame by taking the inverse Fourier
transform of this data.

I have used (part of) an animation from the Carnegie Mellon University Motion
Capture Database. The animations of this database are free to use:

- http://mocap.cs.cmu.edu/

Íñigo Quílez has created some excellent shaders that show the properties of
Fourier transforms, for example:

- https://www.shadertoy.com/view/4lGSDw
- https://www.shadertoy.com/view/ltKSWD

Buffer B: The BRDF integration map used for the IBL and the drawing of the humanoid
are precalculated.

Buffer C: Additional custom animation of the bones is calculated for the start
and end of the loop.


## Shaders

### Common

Source: [Common.glsl](./Common.glsl)

### Buffer A

Source: [Buffer A.glsl](./Buffer&#32;A.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_

### Buffer B

Source: [Buffer B.glsl](./Buffer&#32;B.glsl)

#### Inputs

 * **iChannel0**: Buffer B _(linear, clamp, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/92d7758c402f0927011ca8d0a7e40251439fba3a1dac26f5b8b62026323501aa.jpg) _(mipmap, repeat, vflipped)_

### Buffer C

Source: [Buffer C.glsl](./Buffer&#32;C.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_

### Image

Source: [Image.glsl](./Image.glsl)

#### Inputs

 * **iChannel0**: cubemap _(mipmap, clamp, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/1f7dca9c22f324751f2a5a59c9b181dfe3b5564a04b724c657732d0bf09c99db.jpg) _(mipmap, repeat, vflipped)_
 * **iChannel2**: Buffer C _(linear, clamp, vflipped)_
 * **iChannel3**: Buffer B _(linear, clamp, vflipped)_

## Links
* [[SH18] Human Document](https://www.shadertoy.com/view/XtcyW4) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.](https://creativecommons.org/licenses/by-nc-sa/4.0/)
