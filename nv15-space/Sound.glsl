
//----------------------------------------------------------------------
// Wind function by Dave Hoskins https://www.shadertoy.com/view/4ssXW2


float hash( float n ) {
    return fract(sin(n)*43758.5453123);
}
vec2 Hash( vec2 p) {
    return vec2( hash(p.x), hash(p.y) );
}

//--------------------------------------------------------------------------
vec2 Noise( in vec2 x ) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 res = mix(mix( Hash(p + 0.0), Hash(p + vec2(1.0, 0.0)),f.x),
                   mix( Hash(p + vec2(0.0, 1.0) ), Hash(p + vec2(1.0, 1.0)),f.x),f.y);
    return res-.5;
}

//--------------------------------------------------------------------------
vec2 FBM( vec2 p ) {
    vec2 f;
	f  = 0.5000	 * Noise(p); p = p * 2.32;
	f += 0.2500  * Noise(p); p = p * 2.23;
	f += 0.1250  * Noise(p); p = p * 2.31;
    f += 0.0625  * Noise(p); p = p * 2.28;
    f += 0.03125 * Noise(p);
    return f;
}

//--------------------------------------------------------------------------
vec2 Wind(float n) {
    vec2 pos = vec2(n * (162.017331), n * (132.066927));
    vec2 vol = Noise(vec2(n*23.131, -n*42.13254))*1.0 + 1.0;
    
    vec2 noise = vec2(FBM(pos*33.313))* vol.x *.5 + vec2(FBM(pos*4.519)) * vol.y;
    
	return noise;
}

//----------------------------------------------------------------------



vec2 mainSound(float time) {
    //16 - 38
 //   time -= 7.5;
    time *= .7;
    float vol = 1.-smoothstep(14.,16.5, time);
    vol += smoothstep(34.5,38., time);
    vol = vol*.8+.2;
    
	return Wind(time*.05) * vol;
}