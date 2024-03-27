// [SH17C] Raymarching tutorial. Created by Reinder Nijhoff 2017
// @reindernijhoff
// 
// https://www.shadertoy.com/view/4dSfRc
//
// In this tutorial you will learn how to render a 3d-scene in Shadertoy
// using distance fields.
//
// The tutorial itself is created in Shadertoy, and is rendered
// using ray marching a distance field.
//
// The shader studied in the tutorial can be found here: 
//     https://www.shadertoy.com/view/4dSBz3
//
// Created for the Shadertoy Competition 2017 
//
// Most of the render code is taken from: 'Raymarching - Primitives' by Inigo Quilez.
//
// You can find this shader here:
//     https://www.shadertoy.com/view/Xds3zN
//

// SLIDE NAVIGATION FUNCTIONS

// Load & store functions

#define SLIDE_FADE_STEPS 45

#define TITLE_DELAY   45
#define BODY_DELAY   90
#define CODE_DELAY   135
#define FOOTER_DELAY 180

#define NUM_SLIDES 25

int SLIDE = 0;
int SLIDE_STEPS_VISIBLE = 0;

ivec4 LoadVec4( in ivec2 vAddr ) {
    return ivec4( texelFetch( iChannel0, vAddr, 0 ) );
}

bool AtAddress( ivec2 p, ivec2 c ) { return all( equal( floor(vec2(p)), vec2(c) ) ); }

void StoreVec4( in ivec2 vAddr, in ivec4 vValue, inout vec4 fragColor, in ivec2 fragCoord ) {
    fragColor = AtAddress( fragCoord, vAddr ) ? vec4(vValue) : fragColor;
}

vec4 LoadFVec4( in ivec2 vAddr ) {
    return texelFetch( iChannel0, vAddr, 0 );
}

void StoreFVec4( in ivec2 vAddr, in vec4 vValue, inout vec4 fragColor, in ivec2 fragCoord ) {
    fragColor = AtAddress( fragCoord, vAddr ) ? vValue : fragColor;
}

// key functions

// Keyboard constants definition
const int KEY_SPACE = 32;
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;
const int KEY_A     = 65;
const int KEY_D     = 68;
const int KEY_S     = 83;
const int KEY_W     = 87;


bool KP(int key) {
	return texelFetch( iChannel1, ivec2(key, 0), 0 ).x > 0.0;
}

bool KT(int key) {
	return texelFetch( iChannel1, ivec2(key, 2), 0 ).x > 0.0;
}

// slide logic

struct SlideDataStruct {
    int title;
    int titleDelay;
    int body;
    int bodyDelay;
    int code;
    int codeDelay;
    vec3 ro;
    vec3 ta;
    int sceneMode;
    int codeS;
    int codeE;
    int distMode;
};

SlideDataStruct temp;
int tempCounter;

bool createSlideData( 
    const int title,
    const int titleDelay,
    const int body,
    const int bodyDelay,
    const int code,
    const int codeDelay,
    const vec3 ro,
    const vec3 ta,
    const int sceneMode,
    const int codeS,
    const int codeE,
	const int distMode ) {
        
    if(tempCounter == SLIDE) {
        temp.title = title;
  	  	temp.titleDelay = titleDelay;
   	 	temp.body = body;
   	 	temp.bodyDelay =bodyDelay;
   	 	temp.code = code;
   		temp.codeDelay =codeDelay;
   		temp.ro = ro;
   		temp.ta = ta;
   	 	temp.sceneMode = sceneMode;
  	 	temp.codeS = codeS;
  	  	temp.codeE = codeE;
		temp.distMode = distMode;
        return true;
    } else {
    	tempCounter++;
        return false;
    }
}

SlideDataStruct getSlideData() {
    tempCounter = 0;
    
    // intro
   if( createSlideData(1,TITLE_DELAY,1,BODY_DELAY,0,0, vec3(.0,0.,1.),vec3(0.,0.,-.5), 0, 0, 0, 0) ) return temp;

    // intro - show bw scene
   if( createSlideData(1,0,2,0,0,0, vec3(.0,0.,1.), vec3(0.,0.,-5.), -1, 0, 0, 0)) return temp;
    
    // create a ray - origin
   if( createSlideData(2,TITLE_DELAY,3,BODY_DELAY,0,0, vec3(2.,1.,2.),vec3(0.,0.2,-1.3), 1, 0, 0, 0)) return temp;
        
    // create a ray - origin / code    
   if( createSlideData(2,0,4,0,1,TITLE_DELAY, vec3(2.,1.,2.),vec3(0.,0.2,-1.3), 1, 1, 3, 0)) return temp;
    
    // place screen
   if( createSlideData(2,0,5,TITLE_DELAY,0,0, vec3(2.,1.,2.),vec3(0.,0.2,-1.3), 2, 0, 0, 0)) return temp;
    
    // create rd
   if( createSlideData(2,0,6,TITLE_DELAY,0,0, vec3(2.5,3.,2.5),vec3(0.,0.2,-1.3), 3, 0, 0, 0)) return temp;

	// create rd / code
   if( createSlideData(2,0,7,0,1,TITLE_DELAY, vec3(2.5,3.,2.5),vec3(0.,0.2,-1.3), 3, 3, 0, 0)) return temp;
   
    // interact with scene
   if( createSlideData(2,0,8,0,0,0, vec3(2.5,3.,2.5),vec3(0.,0.2,-1.3), 3, 3, 0, 0)) return temp;
    
    // distance fields intro
   if( createSlideData(3,TITLE_DELAY,9,BODY_DELAY,0,0, vec3(1.,6.,2.),vec3(0.,0.2,-1.3), 3, 0, 0, 0)) return temp;
    
    // distance fields def
   if( createSlideData(3,0,10,TITLE_DELAY,0,0, vec3(1.,6.,2.),vec3(0.,0.2,-1.3), 3, 0, 0, 0)) return temp;
        
    // distance fields one sphere
   if( createSlideData(3,TITLE_DELAY,11,BODY_DELAY,0,0, vec3(1.,6.,-2.),vec3(-1.,-0.5,-2.), 4, 0, 0, 0)) return temp;
    
     // distance fields one sphere
   if( createSlideData(3,0,11,0,0,0, vec3(1.,6.,-2.),vec3(-1.,-0.5,-2.), 4, 0, 0, 1)) return temp;
      
    // distance fields one sphere - code
   if( createSlideData(3,0,12,0,2,TITLE_DELAY, vec3(1.,6.,-2.),vec3(-1.,-0.5,-2.), 4, 0, 3, 1)) return temp;
    
    // distance fields one three spheres
   if( createSlideData(3,0,13,TITLE_DELAY,0,0, vec3(1.,6.,-2.),vec3(-1.,-0.5,-2.), 2, 0, 5, 2)) return temp;
    
    // distance fields one three spheres - in code
   if( createSlideData(3,0,14,0,2,TITLE_DELAY, vec3(1.,6.,-2.),vec3(-1.,-0.5,-2.), 2, 0, 5, 2)) return temp;
    
    // distance fields one three spheres - full code
   if( createSlideData(3,0,15,TITLE_DELAY,2,BODY_DELAY, vec3(1.,6.,-2.),vec3(-1.,-0.5,-2.), 2, 0, 0, 3)) return temp;
        
    // distance fields one three spheres - march
   if( createSlideData(3,0,16,TITLE_DELAY,0,0, vec3(2.5,3.,1.5),vec3(0.,0.2,-1.3), 5, 0, 0, 4)) return temp;
    
    // distance fields one three spheres - march code
   if( createSlideData(3,0,17,0,3,TITLE_DELAY, vec3(2.5,3.,1.5),vec3(0.,0.2,-1.3), 5, 0, 0, 4)) return temp;
        
    // distance fields one three spheres - interact
   if( createSlideData(3,0,8,TITLE_DELAY,0,0, vec3(.5,2.,2.5),vec3(0.,0.2,-.3), 5, 0, 0, 4)) return temp;

    // lighting - normal intro
   if( createSlideData(4,TITLE_DELAY,18,BODY_DELAY,0,0, vec3(2.5,3.,1.5),vec3(0.,0.2,-1.3), 6, 0, 0, 0)) return temp;

   // lighting - normal full
   if( createSlideData(4,0,19,TITLE_DELAY,4,BODY_DELAY, vec3(4.5,3.,-1.5),vec3(0.,0.2,-1.3), 6, 0, 0, 0)) return temp;

   // lighting - interact
   if( createSlideData(4,0,8,TITLE_DELAY,0,0, vec3(4.5,3.,-1.5),vec3(0.,0.2,-1.3), 6, 0, 0, 0)) return temp;

   // lighting - diffuse
   if( createSlideData(4,0,20,TITLE_DELAY,0,0, vec3(.0,0.,1.),vec3(0.,0.,-.5), 0, 0, 0, 0)) return temp;

   // lighting - diffuse
   if( createSlideData(4,0,21,0,5,TITLE_DELAY, vec3(.0,0.,1.),vec3(0.,0.,-.5), -1, 0, 0, 0)) return temp;
 
   // done
   if( createSlideData(1,TITLE_DELAY,22,BODY_DELAY,0,0, vec3(.0,0.,1.),vec3(0.,0.,-.5), -1, 0, 0, 0)) return temp;
 
    
    return temp;
}
    
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

float sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph ) {
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return 10000.0;
	return -b - sqrt( h );
}

float iPlane(in vec3 ro, in vec3 rd, in float d) {
	// equation of a plane, y=0 = ro.y + t*rd.y
    return -(ro.y+d)/rd.y;
}

vec3 intersectScene( vec3 ro, vec3 ta, vec2 p,  bool intersectPlane ) {    
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = ca * normalize( vec3(p.xy,1.0) );
    
    float d = 1000.;
    // sphere intersections ..
    if( intersectPlane ) {
	    if( rd.y < 0. ) d = min(d, iPlane(ro, rd, 0.));
    } else {
    	d = min( d, sphIntersect( ro, rd, vec4(-1,0,-5,1) ));
   		d = min( d, sphIntersect( ro, rd, vec4(2,0,-3,1) ));
  	  	d = min( d, sphIntersect( ro, rd, vec4(-2,0,-2,1) ));

	    if( rd.y < 0. ) d = min(d, iPlane(ro, rd, 1.));
    }
    
    if( d < 100. ) {
        return ro + d*rd;
    } else {
        return vec3(-1,0,-4);
    }
}
    
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	ivec2 uv = ivec2(fragCoord.xy);
    
    // wait for font-texture to load
    if( iFrame == 0 || texelFetch(iChannel2, ivec2(0,0), 0).b < .1) {
        vec4 ro = vec4(0,0,1,0);
		vec4 ta = vec4(0);
        
		StoreFVec4( ivec2(0,0), vec4(0), fragColor, uv);
		StoreFVec4( ivec2(0,3), ro, fragColor, uv);
		StoreFVec4( ivec2(0,4), ta, fragColor, uv);
    } else if( uv.x < 2 && uv.y < 6) {
        ivec4 slideData = LoadVec4( ivec2(0,0) );
        SLIDE = slideData.x;
        SLIDE_STEPS_VISIBLE = slideData.y;
        SLIDE_STEPS_VISIBLE++;

        if( SLIDE_STEPS_VISIBLE > 16 ) {
            if( KP(KEY_SPACE) || KP(KEY_RIGHT) || KP(KEY_D) ) {
                SLIDE++;
                SLIDE_STEPS_VISIBLE=0;
            }
            if( KP(KEY_LEFT) || KP(KEY_W) ) {
                SLIDE = (SLIDE + NUM_SLIDES - 1);
                SLIDE_STEPS_VISIBLE=0;
            }
            
            SLIDE = SLIDE % NUM_SLIDES; 
        }
        
        SlideDataStruct slide = getSlideData();
        
        // screen resolution
        ivec4 res = LoadVec4( ivec2(1,0) );
        if( res.x != int(iResolution.x) || res.y != int(iResolution.y) ) {
            SLIDE_STEPS_VISIBLE = 0;
        }
        StoreVec4( ivec2(1,0), ivec4(iResolution.xy, 0,0), fragColor, uv );
        
		// slide navigation               
		StoreVec4( ivec2(0,0), ivec4(SLIDE, SLIDE_STEPS_VISIBLE, slide.sceneMode, slide.distMode), fragColor, uv);
        
        // text 
        ivec4 showText1 = ivec4(0);
        ivec4 showText2 = ivec4(0);
        
        if( SLIDE_STEPS_VISIBLE == 0) showText1.x = 1;
        
        if( slide.titleDelay == SLIDE_STEPS_VISIBLE) showText2.x = slide.title;
        if( slide.bodyDelay == SLIDE_STEPS_VISIBLE) showText2.y = slide.body;
        if( slide.codeDelay == SLIDE_STEPS_VISIBLE) showText2.z = slide.code;

        showText1.y = slide.codeS;
        showText1.z = slide.codeE;
        
		StoreVec4( ivec2(0,1), showText1, fragColor, uv);
		StoreVec4( ivec2(0,2), showText2, fragColor, uv);
        
        // camera
        
        vec4 ro = LoadFVec4( ivec2(0,3) );
        vec4 ta = LoadFVec4( ivec2(0,4) );
        
		if(SLIDE_STEPS_VISIBLE > SLIDE_FADE_STEPS) {
            ro.xyz = mix( ro.xyz, slide.ro, 0.055 );
            ta.xyz = mix( ta.xyz, slide.ta, 0.055 );
        }
        
		StoreFVec4( ivec2(0,3), ro, fragColor, uv);
		StoreFVec4( ivec2(0,4), ta, fragColor, uv);
                
        if(iMouse.z > 0.) {
            vec2 q = (iMouse.xy - .5 * iResolution.xy ) / iResolution.y;
			StoreFVec4( ivec2(0,5), vec4(intersectScene(ro.xyz, ta.xyz, q, slide.sceneMode == 5),1), fragColor, uv);
        } else {
			StoreFVec4( ivec2(0,5), vec4(intersectScene(vec3(0,0,1), vec3(1,0,0), vec2(0), slide.sceneMode == 5),1), fragColor, uv);
        }
    } else {  
	    fragColor = vec4(0);
    }
}