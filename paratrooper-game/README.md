# Paratrooper (game)
[View shader on Shadertoy](https://www.shadertoy.com/view/XsyfD3) - _Published on 2018-07-04_ 

![thumbnail](./thumbnail.jpg)


I made this shader because I wanted to try to create a simple
but complete game on Shadertoy.

Buffer A: Game logic. As usual this code started nice, but in the
end I added a lot of if-statements and it became a mess.
Buffer B: Rendering of the screen (320x200).
Buffer C: Encoding and decoding of bitmaps used.

So here it is: Paratrooper ("The worst IBM program of 1983").


```
             *Your Mission*

 Do not allow enemy  paratroopers to land
 on either side of your gun base. If four
 paratroopers  land on one  side of  your
 base,  they will overpower your defenses
 and blow  up your  gun.  After  you have
 survived the first round of helicopters,
 watch out for the jet bombers. Every jet
 pilot has a deadly aim!
 The numeric  key pad  controls  your gun
 and the firing of your bullets. Two keys
 start the gun moving:
     < and 4    counterclockwise
     > or 6     clockwise
 Using the ^ or 8 key stops  the movement
 of your gun and fires your bullets.

                 *Scoring*
     HELICOPTER or JET  .  .  10 points
     ENEMY PARATROOPER  .  .   5 points
     BOMB.  .  .  .  .  .  .  30 points

 Each bullet you fire costs you one point

    PRESS space bar FOR KEYBOARD PLAY

```

## Shaders

### Common

Source: [Common.glsl](./Common.glsl)

### Buffer A

Source: [Buffer A.glsl](./Buffer&#32;A.glsl)

#### Inputs

 * **iChannel0**: keyboard _(linear, clamp, vflipped)_
 * **iChannel1**: Buffer A _(nearest, clamp, vflipped)_

### Buffer B

Source: [Buffer B.glsl](./Buffer&#32;B.glsl)

#### Inputs

 * **iChannel0**: Buffer A _(nearest, clamp, vflipped)_
 * **iChannel1**: Buffer C _(nearest, clamp, vflipped)_

### Buffer C

Source: [Buffer C.glsl](./Buffer&#32;C.glsl)

#### Inputs

 * **iChannel0**: Buffer C _(nearest, clamp, vflipped)_

### Image

Source: [Image.glsl](./Image.glsl)

#### Inputs

 * **iChannel0**: Buffer B _(nearest, clamp, vflipped)_

## Links
* [Paratrooper (game)](https://www.shadertoy.com/view/XsyfD3) on Shadertoy
* [An overview of all my shaders](https://reindernijhoff.net/shadertoy/)
* [My public profile](https://www.shadertoy.com/user/reinder) on Shadertoy

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.](https://creativecommons.org/licenses/by-nc-sa/3.0/)
