// Super simple raymarching example. Created by Reinder Nijhoff 2017
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
// 
// https://www.shadertoy.com/view/4dSBz3
//
// This is the shader used as example in my ray march tutorial: https://www.shadertoy.com/view/4dSfRc
//
// Created for the Shadertoy Competition 2017 
//

//
// Distance field function for the scene. It combines
// the seperate distance field functions of three spheres
// and a plane using the min-operator.
//
float map(vec3 p) {
    float d = distance(p, vec3(-1, 0, -5)) - 1.;     // sphere at (-1,0,5) with radius 1
    d = min(d, distance(p, vec3(2, 0, -3)) - 1.);    // second sphere
    d = min(d, distance(p, vec3(-2, 0, -2)) - 1.);   // and another
    d = min(d, p.y + 1.);                            // horizontal plane at y = -1
    return d;
}

//
// Calculate the normal by taking the central differences on the distance field.
//
vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yyx * map(p + e.yyx) +
        e.yxy * map(p + e.yxy) +
        e.xxx * map(p + e.xxx));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 ro = vec3(0, 0, 1);                           // ray origin

    vec2 q = (fragCoord.xy - .5 * iResolution.xy ) / iResolution.y;
    vec3 rd = normalize(vec3(q, 0.) - ro);             // ray direction for fragCoord.xy

    // March the distance field until a surface is hit.
    float h, t = 1.;
    for (int i = 0; i < 256; i++) {
        h = map(ro + rd * t);
        t += h;
        if (h < 0.01) break;
    }

    if (h < 0.01) {
        vec3 p = ro + rd * t;
        vec3 normal = calcNormal(p);
        vec3 light = vec3(0, 2, 0);
        
        // Calculate diffuse lighting by taking the dot product of 
        // the light direction (light-p) and the normal.
        float dif = clamp(dot(normal, normalize(light - p)), 0., 1.);
		
        // Multiply by light intensity (5) and divide by the square
        // of the distance to the light.
        dif *= 5. / dot(light - p, light - p);
        
        
        fragColor = vec4(vec3(pow(dif, 0.4545)), 1);     // Gamma correction
    } else {
        fragColor = vec4(0, 0, 0, 1);
    }
}