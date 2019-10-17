# [SH17B] Legend of the Gelatinous
[View shader on Shadertoy](https://www.shadertoy.com/view/Xs2Bzy) - _Published on 2017-07-25_ 

![thumbnail](./thumbnail.jpg)


I created this shader in one long night for the Shadertoy Competition 2017


## Shaders

### Buffer A

Source: [Buffer A.glsl](./Buffer&#32;A.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png) _(mipmap, repeat, vflipped)_
 * **iChannel2**: keyboard _(linear, clamp, vflipped)_

### Buffer B

Source: [Buffer B.glsl](./Buffer&#32;B.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg) _(nearest, repeat, vflipped)_
 * **iChannel2**: Buffer B _(linear, clamp, vflipped)_
 * **iChannel3**: [texture](https://shadertoy.com/media/a/08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png) _(mipmap, repeat, vflipped)_

### Image

Source: [Image.glsl](./Image.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(linear, clamp, vflipped)_
 * **iChannel1**: [texture](https://shadertoy.com/media/a/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg) _(nearest, repeat, vflipped)_
 * **iChannel2**: [texture](https://shadertoy.com/media/a/10eb4fe0ac8a7dc348a2cc282ca5df1759ab8bf680117e4047728100969e7b43.jpg) _(nearest, repeat, vflipped)_
 * **iChannel3**: Buffer B _(linear, clamp, vflipped)_

## Links
* [[SH17B] Legend of the Gelatinous](https://www.shadertoy.com/view/Xs2Bzy) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.](https://creativecommons.org/licenses/by-nc-sa/4.0/)
