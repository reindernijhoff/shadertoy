// Paratrooper. Created by Reinder Nijhoff 2018
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/XsyfD3
//
// I made this shader because I wanted to try to create a simple 
// but complete game on Shadertoy.
//
// Buffer A: Game logic. As usual this code started nice, but in the
//           end I added a lot of if-statements and it became a mess.
// Buffer B: Rendering of the screen (320x200).
// Buffer C: Encoding and decoding of bitmaps used.
//
// So here it is: Paratrooper ("The worst IBM program of 1983").
//
//
//             *Your Mission*
//
// Do not allow enemy  paratroopers to land
// on either side of your gun base. If four
// paratroopers  land on one  side of  your
// base,  they will overpower your defenses
// and blow  up your  gun.  After  you have
// survived the first round of helicopters,
// watch out for the jet bombers. Every jet
// pilot has a deadly aim!
// The numeric  key pad  controls  your gun
// and the firing of your bullets. Two keys
// start the gun moving:
//     < and 4    counterclockwise
//     > or 6     clockwise
// Using the ^ or 8 key stops  the movement
// of your gun and fires your bullets.
//
//                 *Scoring*
//     HELICOPTER or JET  .  .  10 points
//     ENEMY PARATROOPER  .  .   5 points
//     BOMB.  .  .  .  .  .  .  30 points
//
// Each bullet you fire costs you one point
//
//    PRESS space bar FOR KEYBOARD PLAY
//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 scale = RES / (iResolution.xy - vec2(0,20));
    float s = max(scale.x, scale.y);
    vec2 uv = (fragCoord.xy * s - .5 * (iResolution.xy * s - RES));
    if( inBox(ivec2(uv), ivec2(0), ivec2(RES)) ) {    
	    if (iResolution.x < 320.) uv *= .5;
	    fragColor = vec4(texture(iChannel0, (uv + .5) / iResolution.xy).rgb, 1.0);
    } else {
        fragColor = vec4(0,0,0,1);
    }
}