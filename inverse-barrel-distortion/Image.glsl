// Inverse Barrel Distortion. Created by Reinder Nijhoff 2019
// The MIT License
// @reindernijhoff
//
// https://www.shadertoy.com/view/Wd3XDr
//
// The inverse of a Barrel Distortion. 
//
// I couldn't find this function online, so I derived it myself. 
// A surprisingly complex formula ;-).
//
// ```
// uv -= .5;
//    
// float b = distortion;
// float l = length(uv);
//    
// float x0 = pow(9.*b*b*l + sqrt(3.) * sqrt(27.*b*b*b*b*l*l + 4.*b*b*b), 1./3.);
// float x = x0 / (pow(2., 1./3.) * pow(3., 2./3.) * b) - pow(2./3., 1./3.) / x0;
//    
// return uv * (x / l) + .5;
// ```
//

#define BARREL_DISTORTION 1.5

vec2 barrelDistortion(vec2 uv, float distortion) {    
    uv -= .5;
    uv *= 1. + dot(uv, uv) * distortion;
    return uv + .5;
}

vec2 inverseBarrelDistortion(vec2 uv, float distortion) {    
    uv -= .5;
    
    float b = distortion;
    float l = length(uv);
    
    float x0 = pow(9.*b*b*l + sqrt(3.) * sqrt(27.*b*b*b*b*l*l + 4.*b*b*b), 1./3.);
    float x = x0 / (pow(2., 1./3.) * pow(3., 2./3.) * b) - pow(2./3., 1./3.) / x0;
       
    return uv * (x / l) + .5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    
    vec2 uvDist = barrelDistortion(uv, BARREL_DISTORTION);
    vec2 uvInv  = inverseBarrelDistortion(uvDist, BARREL_DISTORTION);
        
    vec3 col = texture(iChannel0, fract(iTime*.5) > .5 ? uvDist : uvInv).rgb;
    
    fragColor = vec4(col,1.0);
}