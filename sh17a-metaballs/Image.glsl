// [SH17A] Metaballs. Created by Reinder Nijhoff 2017
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/Ms2fDh
//

void mainImage( out vec4 f, vec2 g ) {
	vec3 n=iResolution,r=vec3(g,1)/n-.5,p=n-n;
	p.z -= 4.;   
	for(int i=64;i-->0;){ 
		float s=1.,j=0.,b=p.y+2.,h; 
		for(;++j<7.;) 
            h=clamp(.5+.5*(b-s),0.,1.),
            s=mix(b,s,h)-h*(1.-h),
            b=length(p-1.3*sin(j*99.*n+iTime))-.4; 
		p+=r*s;
		}   
	f=texture(iChannel0,p)*2./dot(p,p);	
}