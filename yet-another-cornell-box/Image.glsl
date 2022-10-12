// Yet another Cornell Box. Created by Reinder Nijhoff 2019
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/3dfGR2
// 
// Yet another Cornell Box. I have optimised the code of my shader "RIOW 2.07: Instances"
// for the Cornell Box and added direct light sampling to reduce noise. Only Lambertian 
// solid materials and cubes are supported. 
//
// These shaders are my implementation of the raytracer described in the (excellent) 
// book "Ray tracing in one weekend" and "Ray tracing: the next week"[1] by Peter Shirley 
// (@Peter_shirley).
//
// = Ray tracing in one week =
// Chapter  7: Diffuse                           https://www.shadertoy.com/view/llVcDz
// Chapter  9: Dielectrics                       https://www.shadertoy.com/view/MlVcDz
// Chapter 11: Defocus blur                      https://www.shadertoy.com/view/XlGcWh
// Chapter 12: Where next?                       https://www.shadertoy.com/view/XlycWh
//
// = Ray tracing: the next week =
// Chapter  6: Rectangles and lights             https://www.shadertoy.com/view/4tGcWD
// Chapter  7: Instances                         https://www.shadertoy.com/view/XlGcWD
// Chapter  8: Volumes                           https://www.shadertoy.com/view/XtyyDD
// Chapter  9: A Scene Testing All New Features  https://www.shadertoy.com/view/MtycDD
//
// [1] http://in1weekend.blogspot.com/2016/01/ray-tracing-in-one-weekend.html
//

#define MOVE_CAMERA

#define MAX_FLOAT 1e5
#define EPSILON 0.01
#define MAX_RECURSION 3
#define SAMPLES (12+min(0,iFrame))

#define LAMBERTIAN 0
#define DIFFUSE_LIGHT 1

//
// Hash functions by Nimitz:
// https://www.shadertoy.com/view/Xt3cDn
//

uint base_hash(uvec2 p) {
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}

float g_seed = 0.;

vec2 hash2(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    uvec2 rz = uvec2(n, n*48271U);
    return vec2(rz.xy & uvec2(0x7fffffffU))/float(0x7fffffff);
}

vec3 hash3(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    uvec3 rz = uvec3(n, n*16807U, n*48271U);
    return vec3(rz & uvec3(0x7fffffffU))/float(0x7fffffff);
}

//
// Ray trace helper functions
//

vec3 random_cos_weighted_hemisphere_direction( const vec3 n, inout float seed ) {
  	vec2 r = hash2(seed);
	vec3  uu = normalize(cross(n, abs(n.y) > .5 ? vec3(1.,0.,0.) : vec3(0.,1.,0.)));
	vec3  vv = cross(uu, n);
	float ra = sqrt(r.y);
	float rx = ra*cos(6.28318530718*r.x); 
	float ry = ra*sin(6.28318530718*r.x);
	float rz = sqrt(1.-r.y);
	vec3  rr = vec3(rx*uu + ry*vv + rz*n);
    return normalize(rr);
}

vec2 random_in_unit_disk(inout float seed) {
    vec2 h = hash2(seed) * vec2(1.,6.28318530718);
    float phi = h.y;
    float r = sqrt(h.x);
	return r * vec2(sin(phi),cos(phi));
}

vec3 rotate_y(const in vec3 p, const in float t) {
    float co = cos(t);
    float si = sin(t);
    vec2 xz = mat2(co,si,-si,co)*p.xz;
    return vec3(xz.x, p.y, xz.y);
}

//
// Ray
//

struct ray {
    vec3 origin, direction;
};

ray ray_translate(const in ray r, const in vec3 t) {
    ray rt = r;
    rt.origin -= t;
    return rt;
}

ray ray_rotate_y(const in ray r, const in float t) {
    ray rt = r;
    rt.origin = rotate_y(rt.origin, t);
    rt.direction = rotate_y(rt.direction, t);
    return rt;
}

//
// Material
//

struct material {
    int type;
    vec3 color;
};

//
// Hit record
//

struct hit_record {
    float t;
    vec3 p, normal;
    material mat;
};

hit_record hit_record_translate(const in hit_record h, const in vec3 t) {
    hit_record ht = h;
    ht.p -= t;
    return ht;
}
   
hit_record hit_record_rotate_y(const in hit_record h, const in float t) {
    hit_record ht = h;
    ht.p = rotate_y(ht.p, t);
    ht.normal = rotate_y(ht.normal, t);
    return ht;
}

void material_scatter(const in ray r_in, const in hit_record rec, out vec3 attenuation, 
                      out ray scattered) {
    scattered = ray(rec.p, random_cos_weighted_hemisphere_direction(rec.normal, g_seed));
    attenuation = rec.mat.color;
}

vec3 material_emitted(const in hit_record rec) {
    if (rec.mat.type == DIFFUSE_LIGHT) {
        return rec.mat.color;
    } else {
        return vec3(0);
    }
}

//
// Hitable
//

struct hitable { // always a box
    vec3 center, dimension; 
};
    
bool box_intersect(const in ray r, const in float t_min, const in float t_max,
                   const in vec3 center, const in vec3 rad, out vec3 normal, inout float dist) {
    vec3 m = 1./r.direction;
    vec3 n = m*(r.origin - center);
    vec3 k = abs(m)*rad;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	if( tN > tF || tF < 0.) return false;
    
    float t = tN < t_min ? tF : tN;
    if (t < t_max && t > t_min) {
        dist = t;
		normal = -sign(r.direction)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
	    return true;
    } else {
        return false;
    }
}

bool hitable_hit(const in hitable hb, const in ray r, const in float t_min, 
                 const in float t_max, inout hit_record rec) {
    float dist;
    vec3 normal;
    if (box_intersect(r, t_min, t_max, hb.center, hb.dimension, normal, dist)) {
        rec.t = dist;
        rec.p = r.origin + dist*r.direction;
        rec.normal = normal;
        return true;
    } else {
        return false;
    }
}

//
// Camera
//

struct camera {
    vec3 origin, lower_left_corner, horizontal, vertical, u, v, w;
    float lens_radius;
};

camera camera_const(const in vec3 lookfrom, const in vec3 lookat, const in vec3 vup, 
                    const in float vfov, const in float aspect, const in float aperture, 
                    const in float focus_dist) {
    camera cam;    
    cam.lens_radius = aperture / 2.;
    float theta = vfov*3.14159265359/180.;
    float half_height = tan(theta/2.);
    float half_width = aspect * half_height;
    cam.origin = lookfrom;
    cam.w = normalize(lookfrom - lookat);
    cam.u = normalize(cross(vup, cam.w));
    cam.v = cross(cam.w, cam.u);
    cam.lower_left_corner = cam.origin  - half_width*focus_dist*cam.u -half_height*focus_dist*cam.v - focus_dist*cam.w;
    cam.horizontal = 2.*half_width*focus_dist*cam.u;
    cam.vertical = 2.*half_height*focus_dist*cam.v;
    return cam;
}
    
ray camera_get_ray(camera c, vec2 uv) {
    vec2 rd = c.lens_radius*random_in_unit_disk(g_seed);
    vec3 offset = c.u * rd.x + c.v * rd.y;
    return ray(c.origin + offset, 
               normalize(c.lower_left_corner + uv.x*c.horizontal + uv.y*c.vertical - c.origin - offset));
}

//
// Color & Scene
//

bool world_hit(const in ray r, const in float t_min, 
               const in float t_max, out hit_record rec) {
    rec.t = t_max;
    bool hit = false;

    const material red = material(LAMBERTIAN, vec3(.65,.05,.05));
    const material white = material(LAMBERTIAN, vec3(.73));
    const material green = material(LAMBERTIAN, vec3(.12,.45,.15));

    const material light = material(DIFFUSE_LIGHT, vec3(15));
    
    if (hitable_hit(hitable(vec3(278,555,279.5), vec3(65,1,52.5)),r,t_min,rec.t,rec)) 
        hit=true, rec.mat=light;   
   
    ray r_ = ray_rotate_y(ray_translate(r, vec3(130,0,65)), -18./180.*3.14159265359);
    hit_record rec_ = rec;    
    if (hitable_hit(hitable(vec3(82.5), vec3(82.5)),r_,t_min,rec.t,rec_)) 
        hit=true, 
        rec=hit_record_translate(hit_record_rotate_y(rec_, 18./180.*3.14159265359),-vec3(130,0,65.)), 
        rec.mat=white;
    
	r_ = ray_rotate_y(ray_translate(r, vec3(265,0,295)), 15./180.*3.14159265359);
    rec_ = rec;    
    if (hitable_hit(hitable(vec3(82.5,165,82.5), vec3(82.5,165,82.5)),r_,t_min,rec.t,rec_)) 
        hit=true, 
        rec=hit_record_translate(hit_record_rotate_y(rec_, -15./180.*3.14159265359),-vec3(265,0,295)), 
        rec.mat=white;

  	if (hitable_hit(hitable(vec3(556,277.5,277.5), vec3(1,277.5,277.5)),r,t_min,rec.t,rec)) 
        hit=true, rec.mat=red;
    if (hitable_hit(hitable(vec3(-1,277.5,277.5), vec3(1,277.5,277.5)),r,t_min,rec.t,rec)) 
        hit=true, rec.mat=green;
   
    if (hitable_hit(hitable(vec3(277.5,556,277.5), vec3(277.5,1,277.5)),r,t_min,rec.t,rec)) 
        hit=true, rec.mat=white;
    if (hitable_hit(hitable(vec3(277.5,-1,277.5), vec3(277.5,1,277.5)),r,t_min,rec.t,rec)) 
        hit=true, rec.mat=white;
    if (hitable_hit(hitable(vec3(277.5,277.5,556), vec3(277.5,277.5,1)),r,t_min,rec.t,rec)) 
        hit=true, rec.mat=white;
    
    return hit;
}


bool shadow_hit(const in ray r, const in float t_min, const in float t_max) {
    hit_record rec;
    rec.t = t_max;
   
    ray r_ = ray_rotate_y(ray_translate(r, vec3(130,0,65)), -18./180.*3.14159265359);  
    if (hitable_hit(hitable(vec3(82.5), vec3(82.5)),r_,t_min,rec.t,rec)) 
        return true;
    
	r_ = ray_rotate_y(ray_translate(r, vec3(265,0,295)), 15./180.*3.14159265359);  
    if (hitable_hit(hitable(vec3(82.5,165,82.5), vec3(82.5,165,82.5)),r_,t_min,rec.t,rec)) 
        return true;
  
    return false;
}

vec3 color(in ray r) {
    vec3 col = vec3(0);
    vec3 emitted = vec3(0);
	hit_record rec;
    
    for (int i=0; i<MAX_RECURSION && world_hit(r, EPSILON, MAX_FLOAT, rec); i++) {
        if (rec.mat.type == DIFFUSE_LIGHT) { // direct light sampling code
            return i == 0 ? rec.mat.color : emitted;
        }

        vec3 attenuation;
        material_scatter(r, rec, attenuation, r);
        col = i == 0 ? attenuation : col * attenuation;

        // direct light sampling
        vec3 pointInSource = (2.*hash3(g_seed)-1.) * vec3(65,1,52.5) + vec3(278,555,279.5);
        vec3 L = pointInSource - rec.p;
        float rr = dot(L, L);
        L = normalize(L);

        ray shadowRay = ray(rec.p, L);
        if (L.y > 0.01 && dot(rec.normal, L) > 0. && !shadow_hit(shadowRay, .01, 1000.)) {
	        const float area = (65.*52.5*4.);
            float weight = area * L.y * dot(rec.normal, L) / (3.14 * rr);
            emitted += col * 15. * weight;
        }
    }
    return emitted;
}

//
// Main
//

void mainImage( out vec4 frag_color, in vec2 frag_coord ) {
    float aspect = iResolution.x/iResolution.y;
#ifdef MOVE_CAMERA
    vec3 lookfrom = vec3(278. + sin(iTime * .7)*200., 278, -800. + sin(iTime)*100.);
#else
    vec3 lookfrom = vec3(278. , 278, -800.);
#endif
    vec3 lookat = vec3(278,278,0);
    g_seed = float(base_hash(floatBitsToUint(frag_coord)))/float(0xffffffffU)+iTime;

    vec3 tcol = vec3(0);
    
    for (int i=0, l = SAMPLES; i<l; i++) {
        vec2 uv = (frag_coord + hash2(g_seed))/iResolution.xy;

        camera cam = camera_const(lookfrom, lookat, vec3(0,1,0), 40., aspect, .0, 10.);
        ray r = camera_get_ray(cam, uv);
        tcol += color(r);
    }
    
    frag_color = vec4(sqrt(tcol / float(SAMPLES)), 1.);
}