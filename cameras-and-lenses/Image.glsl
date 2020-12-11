// Cameras and Lenses. Created by Reinder Nijhoff 2020
// https://www.shadertoy.com/view/wdyBRV
//
// Based on the shaders of the excellent article 'Cameras and Lenses' by 
// @BCiechanowski: https://ciechanow.ski/cameras-and-lenses/
//

const float aperture = 0.15;

vec2 hash2(float n) {
	return fract(n * vec2(0.754878, 0.56984));
}

vec2 random_in_unit_disk(float seed) {
    vec2 h = hash2(seed) * vec2(1.,6.28318530718);
	return sqrt(h.x) * vec2(sin(h.y),cos(h.y));
}

// https://www.shadertoy.com/view/4d2XWV by Inigo Quilez
float sphere_intersect(vec3 ro, vec3 rd, vec4 sph) {
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}

vec4 render(vec3 ro, vec3 rd) {
    vec3 color = vec3(0.94);

    // sphere positions and sphere colors
    const vec4 s0 = vec4(0.7, 0.7, 0.3, 0.3);
    const vec4 s1 = vec4(-0.7, -0.7, 0.5, 0.5);
    const vec3 c0 = vec3(1.0, 0.1, 0.05);
    const vec3 c1 = vec3(0.1, 0.8, 0.05);

    vec4 sphere = rd.y > 0.0 ? s0 : s1;

    float dist = sphere_intersect(ro, rd, sphere);
    if (dist > 0.0) { // spheres
        float diff = 0.5 + 0.5 * normalize(ro + rd * dist - sphere.xyz).z;
        color = ( rd.y > 0.0 ? c0 : c1) * sqrt(diff);
    }
    else if (rd.z < 0.0) { // plane
        dist = -ro.z / rd.z;
        vec2 pos = ro.xy + rd.xy * dist;

        if (abs(pos.x) < 2. && abs(pos.y) < 2.) {
            // checker pattern
            vec2  fpos = floor(pos * 2.0);
            float s = mod(fpos.x + fpos.y, 2.0) > 0.5 ? 0.54 : 0.66;
            
            // fake ambient occlusion
            vec2  d0 = pos - s0.xy;
            float f0 = 12.0 * dot(d0, d0);
            vec2  d1 = pos - s1.xy;
            float f1 = 5.0 * dot(d1, d1);
            float f = (f0*f1 - 1.0) / ((f0 + 1.0)*(f1 + 1.0));

            color = vec3(f * s);
        }
    }
    return vec4(color, clamp(dist, 1.5, 3.7));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float seed = fract(sin(dot(fragCoord.xy, vec2(1234.0, 5134.0))));
    
    vec2 uv = (fragCoord*2.0-iResolution.xy)/iResolution.y;
    
    vec3 ro = vec3(2.7, 0, 0.7);
    vec3 color = vec3(0.0);

	vec3  focusrd = normalize(vec3(-1., 0.6 * (iMouse.xy*2.-iResolution.xy)/iResolution.y));
	float focusingDistance = iMouse.x > 0. ? abs((ro + focusrd * render(ro, focusrd).w).x - ro.x) : 2.;
      
    for (float x = 0.0; x <= 6.0; x += 1.) {
        for (float y = 0.0; y <= 6.0; y += 1.) {
            vec2 offset = random_in_unit_disk(seed + x + 5.0 * y) * aperture;
            vec2 aa     = vec2(x - 2.5, y - 2.5) * (0.4 / iResolution.y);
            
            vec3 rd = normalize(vec3(-focusingDistance, (uv + aa) * focusingDistance * 0.6 + offset));
    
            color += render(ro - vec3(0.0, offset), rd).rgb;
        }
    }
 
    color *= (1.0/36.);
    
    fragColor = vec4(pow(color.rgb, vec3(0.45454)), 1.0);
}