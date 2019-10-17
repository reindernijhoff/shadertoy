# Gaussian Weights and Fake AO
[View shader on Shadertoy](https://www.shadertoy.com/view/Wtj3Wc) - _Published on 2019-06-24_ 

![thumbnail](./thumbnail.jpg)


Sometimes you need to calculate the weights of a Gaussian blur kernel
yourself. For example if you want to calculate weights for a kernel where
the center of the Gaussian curve is not exactly in the "center of the
kernel" but has a sub-pixel offset. These "shifted" Gaussian kernels can be
used if you want to blur-and-upscale an image in a single pass, e.g. if you
are adding a low-res raytraced reflection buffer to your high-res
rasterized scene. It is also needed for the fake ambient occlusion (AO)
term as used in this shader.

The Gaussian weights for a blur kernel can be calculated, either by
numerical integration, or by directly calculating the value of the Gauss
error funtion, as shown below.

In this shader I calculate a fake ambient occlusion (AO) term for each
sample point. The AO-term is based on the weighted average of fake AO-terms
for all cells in a 7x7 grid around the sample point, corresponding with a
7x7 Gaussian kernel with the sample point as its center. The AO-term for
a single cell in this weighted average is simply given by the difference in
height of the cell and that of the sample point.


## Shaders

### Image

Source: [Image.glsl](./Image.glsl)

## Links
* [Gaussian Weights and Fake AO](https://www.shadertoy.com/view/Wtj3Wc) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.](https://creativecommons.org/licenses/by-nc-sa/4.0/)
