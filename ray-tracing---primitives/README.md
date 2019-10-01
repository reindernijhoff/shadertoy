# Ray Tracing - Primitives
[View shader on Shadertoy](https://www.shadertoy.com/view/tl23Rm) - _Published on 2019-06-03_ 

![thumbnail](./thumbnail.jpg)


I wanted to create a reference shader similar to "Raymarching - Primitives"
(https://www.shadertoy.com/view/Xds3zN), but with ray-primitive intersection
routines instead of sdf routines.

As usual, I ended up mostly just copy-pasting code from Íñigo Quílez:

http://iquilezles.org/www/articles/intersectors/intersectors.htm

Please let me know if there are other routines that I should add to this shader.

You can find all intersection routines in the Common tab. The routines have a similar
signature: a routine returns the distance to the first hit inside the
[distBound.x, distBound.y] interval and will set the normal if an intersection is found.
If no intersection is found, the routine will return MAX_DIST.

I made a simple ray tracer (Buffer A) to visualize a scene with all primitives.

Use your mouse to change the camera viewpoint.


## Shaders

### Common

Source: [Common.glsl](./Common.glsl)

### Buffer A

Source: [Buffer A.glsl](./Buffer&#32;A.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_

### Image

Source: [Image.glsl](./Image.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_

## Links
* [Ray Tracing - Primitives](https://www.shadertoy.com/view/tl23Rm) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy

## License

[The MIT License.](https://opensource.org/licenses/MIT)
