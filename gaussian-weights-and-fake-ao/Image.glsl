// Gaussian Weights and Fake AO. Created by Reinder Nijhoff 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/Wtj3Wc
//
// Sometimes you need to calculate the weights of a Gaussian blur kernel 
// yourself. For example if you want to calculate weights for a kernel where
// the center of the Gaussian curve is not exactly in the "center of the
// kernel" but has a sub-pixel offset. These "shifted" Gaussian kernels can be
// used if you want to blur-and-upscale an image in a single pass, e.g. if you
// are adding a low-res raytraced reflection buffer to your high-res
// rasterized scene. It is also needed for the fake ambient occlusion (AO)
// term as used in this shader.
//
// The Gaussian weights for a blur kernel can be calculated, either by
// numerical integration, or by directly calculating the value of the Gauss
// error funtion, as shown below.
//
// In this shader I calculate a fake ambient occlusion (AO) term for each
// sample point. The AO-term is based on the weighted average of fake AO-terms
// for all cells in a 7x7 grid around the sample point, corresponding with a
// 7x7 Gaussian kernel with the sample point as its center. The AO-term for
// a single cell in this weighted average is simply given by the difference in
// height of the cell and that of the sample point.
//

#define AA 2.
#define MAX_DIST 10000.

//
// Approximation of the Gauss error function (https://en.wikipedia.org/wiki/Error_function)
// http://people.math.sfu.ca/~cbm/aands/page_299.htm
//
float erf(float x) {
    const float p  =  .47047;
    const float a1 =  .3480242;
    const float a2 = -.0958798;  
    const float a3 =  .7478556;

    float t = 1. / (1. + p * x);
    return 1. - t * (a1 + t * (a2 + t * a3)) * exp(-x*x);
}
    
float gaussianWeight(int cell, float center, const float sigma) {
    float x0 = float(cell) - center;
    float x1 = abs(x0+1.);
    x0 = abs(x0);
    
    float erfx0 = erf(x0 / sigma);
    float erfx1 = erf(x1 / sigma);
    
    return x0 < 1. && x1 < 1. ? abs(erfx0 + erfx1) : abs(erfx0 - erfx1);
}

float gaussianWeight(ivec2 cell, vec2 center, const float sigma) {
	float ix = gaussianWeight(cell.x, center.x, sigma);
	float iy = gaussianWeight(cell.y, center.y, sigma);
    
    return ix * iy;
}

// Hash by Dave_Hoskins: https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float curveXOffset(vec2 pos) {
    return 15.*cos(pos.y*.1);;
}

// camera path
vec3 curve(float time) {
	vec3 p = vec3(0., 3.5+.8*cos(.95*time), 8.5*sin(.1+.37*time)+12.*time);
    p.x = curveXOffset(p.xz);
    return p;
}

float map(vec2 pos) {
    float x = pos.x - curveXOffset(pos);
    return (2.*hash12(pos) + 5.) * (.3+min(3.,.002*(x*x)));
}

float fakeAO(vec3 p) {
    const int gridOffset = 3;
    float sum =0., accum = 0.;
    
    for (int x = -gridOffset; x <= gridOffset; x++) {
        for (int y = -gridOffset; y <= gridOffset; y++) {
            ivec2 s = ivec2(x,y) + ivec2(p.xz);
            float weight = gaussianWeight(s, p.xz, 1.5);
            
            sum += max(map(vec2(s))-p.y, 0.) * weight;
            accum += weight;
        }
    }
    return sum / accum;
}

// trace cubes in grid
vec3 trace( in vec3 ro, in vec3 rd, const int steps, inout vec3 normal ) {
	vec2 pos = floor(ro.xz);
    vec3 rdi = 1./rd;
    vec3 rda = abs(rdi);
	vec3 rds = sign(rd);
	vec2 dis = (pos - ro.xz + .5 + rds.xz*.5) * rdi.xz;
	vec3 roi = rdi*(ro-vec3(.5,0,.5));
    
	vec2 mm = vec2(0.0);
	for( int i=0; i<steps; i++ ) {        
        vec3 n = roi - rdi * vec3(pos.x, 0, pos.y);
        vec3 k = rda*vec3(.5, map(pos), .5);

        vec3 t1 = -n - k;
        vec3 t2 = -n + k;

        float tN = max( max( t1.x, t1.y ), t1.z );
        float tF = min( min( t2.x, t2.y ), t2.z );

        if (tN < tF && tN >= 0.) {
            normal = -rds*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
            return vec3(tN, pos);
        }
        
		mm = step( dis.xy, dis.yx ); 
		dis += mm*rda.xz;
        pos += mm*rds.xz;
	}

	return vec3(MAX_DIST);
}

vec3 render( in vec3 ro, in vec3 rd, bool full ) {
    vec3 normal, col = vec3(0);
	float ref = 1.;
    
    for (int i=1; i>=0; i--) {
        vec3 d = trace(ro, rd, i*64+64, normal);
        if (d.x < MAX_DIST) { // cube hit
            ro += d.x * rd;
            
            float fresnel = full ? pow(1.-max(0.,-dot(normal,rd)),5.) : 0.;
            float mat = full ? hash12(d.zy) : 1.;
            mat *= exp(-1.5*fakeAO(ro)) * ref * (1.-fresnel) 
                * (.8 + .2 * dot(normal, vec3(-.25916,.8639,-.4319)));
	       	col += mat;
            
            ref *= fresnel;
            rd = reflect(rd, normal);
        } else { // background 
            col +=vec3(.5,.8,1) * (ref*(5.-2.5*rd.y));
            return col;
        }
        if (ref <= .001) return col;
    }    
    return col;
}

mat3 setLookAt( in vec3 ro, in vec3 ta, float cr ) {
	vec3  cw = normalize(ta-ro);
	vec3  cp = vec3(sin(cr), cos(cr), 0.);
	vec3  cu = normalize(cross(cw,cp));
	vec3  cv = normalize(cross(cu,cw));
    return mat3(cu, cv, cw);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float time = .2*iTime + 20.*iMouse.x/iResolution.x;    
    vec2 p = (-iResolution.xy+2.*(fragCoord)) / iResolution.y;
	bool full = fract(.5*time + .015*(p.x + p.y)) < .5;
    
    vec3 ro = curve(time);
    vec3 ta = curve(time+.1);
    ta.y -= .3 + .1*sin(time);
    float roll = .2*sin(.1*ro.z-1.6);

    mat3 ca = setLookAt( ro, ta, roll );
    
    vec3 tot = vec3(0);    
    for (float x=0.; x<AA; x+=1.) {     
        for (float y=0.; y<AA; y+=1.) {
            vec3 rd = normalize(ca * vec3(p + vec2(x,y)*(2./(AA*iResolution.y)), 2.));
            vec3 col = render(ro, rd, full);
            col = pow(col, vec3(.4545));
            tot += min(col, vec3(1));
        }
	}
    tot /= (AA*AA);
    
    fragColor = vec4(tot, 1);
}
