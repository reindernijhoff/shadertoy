// Portal - iOS AR. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/lldcR8
//
// This is an experiment to create an "AR shader" by implementing the mainVR-function and 
// using the WebCam texture as background. If you view this shader with the Shadertoy iOS 
// app[1], you can walk around and enter the portal.
//
// If you don't have an iOS device (or if you don't have the app installed) you can have a 
// look at this screen capture to see the shader in action: https://youtu.be/IzeeoD0e6Ow.
//

float iPlane( in vec3 ro, in vec3 rd, in vec4 pla ) {
    return (-pla.w - dot(pla.xyz,ro)) / dot( pla.xyz, rd );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = vec4(1);
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 ro, in vec3 rd ) {
    ro += PORTAL_POS + START_OFFSET;
    
    bool inside = false;
    vec3 oldRo = ro;
    
    if (iFrame > 0) {
    	vec4 t = texelFetch(iChannel0, ivec2(0), 0);
        oldRo = t.xyz;
        inside = t.w > .5;
        
        vec3 rd = normalize( ro - oldRo );
        float portalDist = iPlane( oldRo, rd, vec4(0,0,1,-dot(PORTAL_POS,vec3(0,0,1))));
	    if (portalDist > 0. && portalDist <= length( ro - oldRo) ) {
    	    vec3 p = oldRo + rd * portalDist;
        	if(all(lessThan(abs(p.xy-PORTAL_POS.xy),PORTAL_SIZE.xy))) {
                inside = !inside;
            }
        }
    }
    
    fragColor = vec4(ro, inside ? 1. : 0.);
}