// Created by Reinder Nijhoff 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/XdcGzr
//
// Based on matrix - 255 char by FabriceNeyret2: https://www.shadertoy.com/view/4tlXR4
// compacting to 2-tweets patriciogv's Matrix shader https://www.shadertoy.com/view/MlfXzN ( 819 -> 255 chars ) 
// But first go see patriciogv's comments and readable sources :-D
//
// All credits go to FabriceNeyret2
//

#define R fract(43.*sin(p.x*7.+p.y*8.))

void mainImage( out vec4 o, vec2 i) {
    vec2 j = fract(i*=.1), 
         p = vec2(9,int(iTime*(9.+8.*sin(i-=j).x)))+i;
    o-=o; o.g=R; p*=j; o*=R>.5&&j.x<.6&&j.y<.8?1.:0.;
}