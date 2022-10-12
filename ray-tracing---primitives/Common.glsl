// Ray Tracing - Primitives. Created by Reinder Nijhoff 2019
// The MIT License
// @reindernijhoff
//
// https://www.shadertoy.com/view/tl23Rm
//
// I wanted to create a reference shader similar to "Raymarching - Primitives" 
// (https://www.shadertoy.com/view/Xds3zN), but with ray-primitive intersection 
// routines instead of sdf routines.
// 
// As usual, I ended up mostly just copy-pasting code from Íñigo Quílez: 
// 
// https://iquilezles.org/articles/intersectors
// 
// Please let me know if there are other routines that I should add to this shader.
// 
// Sphere:          https://www.shadertoy.com/view/4d2XWV
// Box:             https://www.shadertoy.com/view/ld23DV
// Capped Cylinder: https://www.shadertoy.com/view/4lcSRn
// Torus:           https://www.shadertoy.com/view/4sBGDy
// Capsule:         https://www.shadertoy.com/view/Xt3SzX
// Capped Cone:     https://www.shadertoy.com/view/llcfRf
// Ellipsoid:       https://www.shadertoy.com/view/MlsSzn
// Rounded Cone:    https://www.shadertoy.com/view/MlKfzm
// Triangle:        https://www.shadertoy.com/view/MlGcDz
// Sphere4:         https://www.shadertoy.com/view/3tj3DW
// Goursat:         https://www.shadertoy.com/view/3lj3DW
// Rounded Box:     https://www.shadertoy.com/view/WlSXRW
//
// Disk:            https://www.shadertoy.com/view/lsfGDB
//

#define MAX_DIST 1e10
float dot2( in vec3 v ) { return dot(v,v); }

// Plane 
float iPlane( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
              in vec3 planeNormal, in float planeDist) {
    float a = dot(rd, planeNormal);
    float d = -(dot(ro, planeNormal)+planeDist)/a;
    if (a > 0. || d < distBound.x || d > distBound.y) {
        return MAX_DIST;
    } else {
        normal = planeNormal;
    	return d;
    }
}

// Sphere:          https://www.shadertoy.com/view/4d2XWV
float iSphere( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
               float sphereRadius ) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - sphereRadius*sphereRadius;
    float h = b*b - c;
    if (h < 0.) {
        return MAX_DIST;
    } else {
	    h = sqrt(h);
        float d1 = -b-h;
        float d2 = -b+h;
        if (d1 >= distBound.x && d1 <= distBound.y) {
            normal = normalize(ro + rd*d1);
            return d1;
        } else if (d2 >= distBound.x && d2 <= distBound.y) { 
            normal = normalize(ro + rd*d2);            
            return d2;
        } else {
            return MAX_DIST;
        }
    }
}

// Box:             https://www.shadertoy.com/view/ld23DV
float iBox( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal, 
            in vec3 boxSize ) {
    vec3 m = sign(rd)/max(abs(rd), 1e-8);
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
    if (tN > tF || tF <= 0.) {
        return MAX_DIST;
    } else {
        if (tN >= distBound.x && tN <= distBound.y) {
        	normal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
            return tN;
        } else if (tF >= distBound.x && tF <= distBound.y) { 
        	normal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
            return tF;
        } else {
            return MAX_DIST;
        }
    }
}

// Capped Cylinder: https://www.shadertoy.com/view/4lcSRn
float iCylinder( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
                 in vec3 pa, in vec3 pb, float ra ) {
    vec3 ca = pb-pa;
    vec3 oc = ro-pa;

    float caca = dot(ca,ca);
    float card = dot(ca,rd);
    float caoc = dot(ca,oc);
    
    float a = caca - card*card;
    float b = caca*dot( oc, rd) - caoc*card;
    float c = caca*dot( oc, oc) - caoc*caoc - ra*ra*caca;
    float h = b*b - a*c;
    
    if (h < 0.) return MAX_DIST;
    
    h = sqrt(h);
    float d = (-b-h)/a;

    float y = caoc + d*card;
    if (y > 0. && y < caca && d >= distBound.x && d <= distBound.y) {
        normal = (oc+d*rd-ca*y/caca)/ra;
        return d;
    }

    d = ((y < 0. ? 0. : caca) - caoc)/card;
    
    if( abs(b+a*d) < h && d >= distBound.x && d <= distBound.y) {
        normal = normalize(ca*sign(y)/caca);
        return d;
    } else {
        return MAX_DIST;
    }
}

// Torus:           https://www.shadertoy.com/view/4sBGDy
float iTorus( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
              in vec2 torus ) {
    // bounding sphere
    vec3 tmpnormal;
    if (iSphere(ro, rd, distBound, tmpnormal, torus.y+torus.x) > distBound.y) {
        return MAX_DIST;
    }
    
    float po = 1.0;
    
	float Ra2 = torus.x*torus.x;
	float ra2 = torus.y*torus.y;
	
	float m = dot(ro,ro);
	float n = dot(ro,rd);

#if 1
	float k = (m + Ra2 - ra2)/2.0;
    float k3 = n;
	float k2 = n*n - Ra2*dot(rd.xy,rd.xy) + k;
    float k1 = n*k - Ra2*dot(rd.xy,ro.xy);
    float k0 = k*k - Ra2*dot(ro.xy,ro.xy);
#else
	float k = (m - Ra2 - ra2)/2.0;
	float k3 = n;
	float k2 = n*n + Ra2*rd.z*rd.z + k;
	float k1 = k*n + Ra2*ro.z*rd.z;
	float k0 = k*k + Ra2*ro.z*ro.z - Ra2*ra2;
#endif
    
#if 1
    // prevent |c1| from being too close to zero
    if (abs(k3*(k3*k3-k2)+k1) < 0.01) {
        po = -1.0;
        float tmp=k1; k1=k3; k3=tmp;
        k0 = 1.0/k0;
        k1 = k1*k0;
        k2 = k2*k0;
        k3 = k3*k0;
    }
#endif
    
    // reduced cubic
    float c2 = k2*2.0 - 3.0*k3*k3;
    float c1 = k3*(k3*k3-k2)+k1;
    float c0 = k3*(k3*(c2+2.0*k2)-8.0*k1)+4.0*k0;
    
    c2 /= 3.0;
    c1 *= 2.0;
    c0 /= 3.0;

    float Q = c2*c2 + c0;
    float R = c2*c2*c2 - 3.0*c2*c0 + c1*c1;
    
    float h = R*R - Q*Q*Q;
    float t = MAX_DIST;
    
    if (h>=0.0) {
        // 2 intersections
        h = sqrt(h);
        
        float v = sign(R+h)*pow(abs(R+h),1.0/3.0); // cube root
        float u = sign(R-h)*pow(abs(R-h),1.0/3.0); // cube root

        vec2 s = vec2( (v+u)+4.0*c2, (v-u)*sqrt(3.0));
    
        float y = sqrt(0.5*(length(s)+s.x));
        float x = 0.5*s.y/y;
        float r = 2.0*c1/(x*x+y*y);

        float t1 =  x - r - k3; t1 = (po<0.0)?2.0/t1:t1;
        float t2 = -x - r - k3; t2 = (po<0.0)?2.0/t2:t2;

        if (t1 >= distBound.x) t=t1;
        if (t2 >= distBound.x) t=min(t,t2);
	} else {
        // 4 intersections
        float sQ = sqrt(Q);
        float w = sQ*cos( acos(-R/(sQ*Q)) / 3.0 );

        float d2 = -(w+c2); if( d2<0.0 ) return MAX_DIST;
        float d1 = sqrt(d2);

        float h1 = sqrt(w - 2.0*c2 + c1/d1);
        float h2 = sqrt(w - 2.0*c2 - c1/d1);
        float t1 = -d1 - h1 - k3; t1 = (po<0.0)?2.0/t1:t1;
        float t2 = -d1 + h1 - k3; t2 = (po<0.0)?2.0/t2:t2;
        float t3 =  d1 - h2 - k3; t3 = (po<0.0)?2.0/t3:t3;
        float t4 =  d1 + h2 - k3; t4 = (po<0.0)?2.0/t4:t4;

        if (t1 >= distBound.x) t=t1;
        if (t2 >= distBound.x) t=min(t,t2);
        if (t3 >= distBound.x) t=min(t,t3);
        if (t4 >= distBound.x) t=min(t,t4);
    }
    
	if (t >= distBound.x && t <= distBound.y) {
        vec3 pos = ro + rd*t;
        normal = normalize( pos*(dot(pos,pos) - torus.y*torus.y - torus.x*torus.x*vec3(1,1,-1)));
        return t;
    } else {
        return MAX_DIST;
    }
}

// Capsule:         https://www.shadertoy.com/view/Xt3SzX
float iCapsule( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
                in vec3 pa, in vec3 pb, in float r ) {
    vec3  ba = pb - pa;
    vec3  oa = ro - pa;

    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoa = dot(ba,oa);
    float rdoa = dot(rd,oa);
    float oaoa = dot(oa,oa);

    float a = baba      - bard*bard;
    float b = baba*rdoa - baoa*bard;
    float c = baba*oaoa - baoa*baoa - r*r*baba;
    float h = b*b - a*c;
    if (h >= 0.) {
        float t = (-b-sqrt(h))/a;
        float d = MAX_DIST;
        
        float y = baoa + t*bard;
        
        // body
        if (y > 0. && y < baba) {
            d = t;
        } else {
            // caps
            vec3 oc = (y <= 0.) ? oa : ro - pb;
            b = dot(rd,oc);
            c = dot(oc,oc) - r*r;
            h = b*b - c;
            if( h>0.0 ) {
                d = -b - sqrt(h);
            }
        }
        if (d >= distBound.x && d <= distBound.y) {
            vec3  pa = ro + rd * d - pa;
            float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
            normal = (pa - h*ba)/r;
            return d;
        }
    }
    return MAX_DIST;
}

// Capped Cone:     https://www.shadertoy.com/view/llcfRf
float iCone( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
             in vec3  pa, in vec3  pb, in float ra, in float rb ) {
    vec3  ba = pb - pa;
    vec3  oa = ro - pa;
    vec3  ob = ro - pb;
    
    float m0 = dot(ba,ba);
    float m1 = dot(oa,ba);
    float m2 = dot(ob,ba); 
    float m3 = dot(rd,ba);

    //caps
    if (m1 < 0.) { 
        if( dot2(oa*m3-rd*m1)<(ra*ra*m3*m3) ) {
            float d = -m1/m3;
            if (d >= distBound.x && d <= distBound.y) {
                normal = -ba*inversesqrt(m0);
                return d;
            }
        }
    }
    else if (m2 > 0.) { 
        if( dot2(ob*m3-rd*m2)<(rb*rb*m3*m3) ) {
            float d = -m2/m3;
            if (d >= distBound.x && d <= distBound.y) {
                normal = ba*inversesqrt(m0);
                return d;
            }
        }
    }
                       
    // body
    float m4 = dot(rd,oa);
    float m5 = dot(oa,oa);
    float rr = ra - rb;
    float hy = m0 + rr*rr;
    
    float k2 = m0*m0    - m3*m3*hy;
    float k1 = m0*m0*m4 - m1*m3*hy + m0*ra*(rr*m3*1.0        );
    float k0 = m0*m0*m5 - m1*m1*hy + m0*ra*(rr*m1*2.0 - m0*ra);
    
    float h = k1*k1 - k2*k0;
    if( h < 0. ) return MAX_DIST;

    float t = (-k1-sqrt(h))/k2;

    float y = m1 + t*m3;
    if (y > 0. && y < m0 && t >= distBound.x && t <= distBound.y) {
        normal = normalize(m0*(m0*(oa+t*rd)+rr*ba*ra)-ba*hy*y);
        return t;
    } else {   
	    return MAX_DIST;
    }
}

// Ellipsoid:       https://www.shadertoy.com/view/MlsSzn
float iEllipsoid( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
                  in vec3 rad ) {
    vec3 ocn = ro / rad;
    vec3 rdn = rd / rad;
    
    float a = dot( rdn, rdn );
	float b = dot( ocn, rdn );
	float c = dot( ocn, ocn );
	float h = b*b - a*(c-1.);
    
    if (h < 0.) {
        return MAX_DIST;
    }
    
	float d = (-b - sqrt(h))/a;
    
    if (d < distBound.x || d > distBound.y) {
        return MAX_DIST;
    } else {
        normal = normalize((ro + d*rd)/rad);
    	return d;
    }
}

// Rounded Cone:    https://www.shadertoy.com/view/MlKfzm
float iRoundedCone( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
                    in vec3  pa, in vec3  pb, in float ra, in float rb ) {
    vec3  ba = pb - pa;
	vec3  oa = ro - pa;
	vec3  ob = ro - pb;
    float rr = ra - rb;
    float m0 = dot(ba,ba);
    float m1 = dot(ba,oa);
    float m2 = dot(ba,rd);
    float m3 = dot(rd,oa);
    float m5 = dot(oa,oa);
	float m6 = dot(ob,rd);
    float m7 = dot(ob,ob);
    
    float d2 = m0-rr*rr;
    
	float k2 = d2    - m2*m2;
    float k1 = d2*m3 - m1*m2 + m2*rr*ra;
    float k0 = d2*m5 - m1*m1 + m1*rr*ra*2. - m0*ra*ra;
    
	float h = k1*k1 - k0*k2;
    if (h < 0.0) {
        return MAX_DIST;
    }
    
    float t = (-sqrt(h)-k1)/k2;
    
    float y = m1 - ra*rr + t*m2;
    if (y>0.0 && y<d2) {
        if (t >= distBound.x && t <= distBound.y) {
        	normal = normalize( d2*(oa + t*rd)-ba*y );
            return t;
        } else {
            return MAX_DIST;
        }
    } else {
        float h1 = m3*m3 - m5 + ra*ra;
        float h2 = m6*m6 - m7 + rb*rb;

        if (max(h1,h2)<0.0) {
            return MAX_DIST;
        }

        vec3 n = vec3(0);
        float r = MAX_DIST;

        if (h1 > 0.) {        
            r = -m3 - sqrt( h1 );
            n = (oa+r*rd)/ra;
        }
        if (h2 > 0.) {
            t = -m6 - sqrt( h2 );
            if( t<r ) {
                n = (ob+t*rd)/rb;
                r = t;
            }
        }
        if (r >= distBound.x && r <= distBound.y) {
            normal = n;
            return r;
        } else {
            return MAX_DIST;
        }
    }
}

// Triangle:        https://www.shadertoy.com/view/MlGcDz
float iTriangle( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
                 in vec3 v0, in vec3 v1, in vec3 v2 ) {
    vec3 v1v0 = v1 - v0;
    vec3 v2v0 = v2 - v0;
    vec3 rov0 = ro - v0;

    vec3  n = cross( v1v0, v2v0 );
    vec3  q = cross( rov0, rd );
    float d = 1.0/dot( rd, n );
    float u = d*dot( -q, v2v0 );
    float v = d*dot(  q, v1v0 );
    float t = d*dot( -n, rov0 );

    if( u<0. || v<0. || (u+v)>1. || t<distBound.x || t>distBound.y) {
        return MAX_DIST;
    } else {
        normal = normalize(-n);
        return t;
    }
}

// Sphere4:         https://www.shadertoy.com/view/3tj3DW
float iSphere4( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
                in float ra ) {
    // -----------------------------
    // solve quartic equation
    // -----------------------------
    
    float r2 = ra*ra;
    
    vec3 d2 = rd*rd; vec3 d3 = d2*rd;
    vec3 o2 = ro*ro; vec3 o3 = o2*ro;

    float ka = 1.0/dot(d2,d2);

    float k0 = ka* dot(ro,d3);
    float k1 = ka* dot(o2,d2);
    float k2 = ka* dot(o3,rd);
    float k3 = ka*(dot(o2,o2) - r2*r2);

    // -----------------------------
    // solve cubic
    // -----------------------------

    float c0 = k1 - k0*k0;
    float c1 = k2 + 2.0*k0*(k0*k0 - (3.0/2.0)*k1);
    float c2 = k3 - 3.0*k0*(k0*(k0*k0 - 2.0*k1) + (4.0/3.0)*k2);

    float p = c0*c0*3.0 + c2;
    float q = c0*c0*c0 - c0*c2 + c1*c1;
    float h = q*q - p*p*p*(1.0/27.0);

    // -----------------------------
    // skip the case of 3 real solutions for the cubic, which involves 
    // 4 complex solutions for the quartic, since we know this objcet is 
    // convex
    // -----------------------------
    if (h<0.0) {
        return MAX_DIST;
    }
    
    // one real solution, two complex (conjugated)
    h = sqrt(h);

    float s = sign(q+h)*pow(abs(q+h),1.0/3.0); // cuberoot
    float t = sign(q-h)*pow(abs(q-h),1.0/3.0); // cuberoot

    vec2 v = vec2( (s+t)+c0*4.0, (s-t)*sqrt(3.0) )*0.5;
    
    // -----------------------------
    // the quartic will have two real solutions and two complex solutions.
    // we only want the real ones
    // -----------------------------
    
    float r = length(v);
	float d = -abs(v.y)/sqrt(r+v.x) - c1/r - k0;

    if (d >= distBound.x && d <= distBound.y) {
	    vec3 pos = ro + rd * d;
	    normal = normalize( pos*pos*pos );
	    return d;
    } else {
        return MAX_DIST;
    }
}

// Goursat:         https://www.shadertoy.com/view/3lj3DW
float cuberoot( float x ) { return sign(x)*pow(abs(x),1.0/3.0); }

float iGoursat( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
                in float ra, float rb ) {
// hole: x4 + y4 + z4 - (r2^2)·(x2 + y2 + z2) + r1^4 = 0;
    float ra2 = ra*ra;
    float rb2 = rb*rb;
    
    vec3 rd2 = rd*rd; vec3 rd3 = rd2*rd;
    vec3 ro2 = ro*ro; vec3 ro3 = ro2*ro;

    float ka = 1.0/dot(rd2,rd2);

    float k3 = ka*(dot(ro ,rd3));
    float k2 = ka*(dot(ro2,rd2) - rb2/6.0);
    float k1 = ka*(dot(ro3,rd ) - rb2*dot(rd,ro)/2.0  );
    float k0 = ka*(dot(ro2,ro2) + ra2*ra2 - rb2*dot(ro,ro) );

    float c2 = k2 - k3*(k3);
    float c1 = k1 + k3*(2.0*k3*k3-3.0*k2);
    float c0 = k0 + k3*(k3*(c2+k2)*3.0-4.0*k1);

    c0 /= 3.0;

    float Q = c2*c2 + c0;
    float R = c2*c2*c2 - 3.0*c0*c2 + c1*c1;
    float h = R*R - Q*Q*Q;
    
    
    // 2 intersections
    if (h>0.0) {
        h = sqrt(h);

        float s = cuberoot( R + h );
        float u = cuberoot( R - h );
        
        float x = s+u+4.0*c2;
        float y = s-u;
        
        float k2 = x*x + y*y*3.0;
  
        float k = sqrt(k2);

		float d = -0.5*abs(y)*sqrt(6.0/(k+x)) 
                  -2.0*c1*(k+x)/(k2+x*k) 
                  -k3;
        
        if (d >= distBound.x && d <= distBound.y) {
            vec3 pos = ro + rd * d;
            normal = normalize( 4.0*pos*pos*pos - 2.0*pos*rb*rb );
            return d;
        } else {
            return MAX_DIST;
        }
    } else {	
        // 4 intersections
        float sQ = sqrt(Q);
        float z = c2 - 2.0*sQ*cos( acos(-R/(sQ*Q)) / 3.0 );

        float d1 = z   - 3.0*c2;
        float d2 = z*z - 3.0*c0;

        if (abs(d1)<1.0e-4) {  
            if( d2<0.0) return MAX_DIST;
            d2 = sqrt(d2);
        } else {
            if (d1<0.0) return MAX_DIST;
            d1 = sqrt( d1/2.0 );
            d2 = c1/d1;
        }

        //----------------------------------

        float h1 = sqrt(d1*d1 - z + d2);
        float h2 = sqrt(d1*d1 - z - d2);
        float t1 = -d1 - h1 - k3;
        float t2 = -d1 + h1 - k3;
        float t3 =  d1 - h2 - k3;
        float t4 =  d1 + h2 - k3;

        if (t2<0.0 && t4<0.0) return MAX_DIST;

        float result = 1e20;
             if (t1>0.0) result=t1;
        else if (t2>0.0) result=t2;
             if (t3>0.0) result=min(result,t3);
        else if (t4>0.0) result=min(result,t4);

        if (result >= distBound.x && result <= distBound.y) {
            vec3 pos = ro + rd * result;
            normal = normalize( 4.0*pos*pos*pos - 2.0*pos*rb*rb );
            return result;
        } else {
            return MAX_DIST;
        }
    }
}

// Rounded Box:     https://www.shadertoy.com/view/WlSXRW
float iRoundedBox(in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
   				  in vec3 size, in float rad ) {
	// bounding box
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*(size+rad);
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
    if (tN > tF || tF < 0.0) {
    	return MAX_DIST;
    }
    float t = (tN>=distBound.x&&tN<=distBound.y)?tN:
    		  (tF>=distBound.x&&tF<=distBound.y)?tF:MAX_DIST;

    // convert to first octant
    vec3 pos = ro+t*rd;
    vec3 s = sign(pos);
    vec3 ros = ro*s;
    vec3 rds = rd*s;
    pos *= s;
        
    // faces
    pos -= size;
    pos = max( pos.xyz, pos.yzx );
    if (min(min(pos.x,pos.y),pos.z)<0.0) {
        if (t >= distBound.x && t <= distBound.y) {
            vec3 p = ro + rd * t;
            normal = sign(p)*normalize(max(abs(p)-size,0.0));
            return t;
        }
    }
    
    // some precomputation
    vec3 oc = ros - size;
    vec3 dd = rds*rds;
	vec3 oo = oc*oc;
    vec3 od = oc*rds;
    float ra2 = rad*rad;

    t = MAX_DIST;        

    // corner
    {
    float b = od.x + od.y + od.z;
	float c = oo.x + oo.y + oo.z - ra2;
	float h = b*b - c;
	if (h > 0.0) t = -b-sqrt(h);
    }

    // edge X
    {
	float a = dd.y + dd.z;
	float b = od.y + od.z;
	float c = oo.y + oo.z - ra2;
	float h = b*b - a*c;
	if (h>0.0) {
	  h = (-b-sqrt(h))/a;
      if (h>=distBound.x && h<t && abs(ros.x+rds.x*h)<size.x ) t = h;
    }
	}
    // edge Y
    {
	float a = dd.z + dd.x;
	float b = od.z + od.x;
	float c = oo.z + oo.x - ra2;
	float h = b*b - a*c;
	if (h>0.0) {
	  h = (-b-sqrt(h))/a;
      if (h>=distBound.x && h<t && abs(ros.y+rds.y*h)<size.y) t = h;
    }
	}
    // edge Z
    {
	float a = dd.x + dd.y;
	float b = od.x + od.y;
	float c = oo.x + oo.y - ra2;
	float h = b*b - a*c;
	if (h>0.0) {
	  h = (-b-sqrt(h))/a;
      if (h>=distBound.x && h<t && abs(ros.z+rds.z*h)<size.z) t = h;
    }
	}
    
	if (t >= distBound.x && t <= distBound.y) {
        vec3 p = ro + rd * t;
        normal = sign(p)*normalize(max(abs(p)-size,1e-16));
        return t;
    } else {
        return MAX_DIST;
    };
}