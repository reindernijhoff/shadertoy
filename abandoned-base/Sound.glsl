//----------------------------------------------------------------------
// noises

float hash( float n ) {
    return fract(sin(n)*43758.5453123);
}

float noise( in vec2 x ) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*157.0;
    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+157.0), hash(n+158.0),f.x),f.y);
}

const mat2 m2 = mat2( 0.80, -0.60, 0.60, 0.80 );

float fbm( vec2 p ) {
    float f = 0.0;
    f += 0.5000*noise( p ); p = m2*p*2.32;
    f += 0.2500*noise( p ); p = m2*p*2.23;
    f += 0.1250*noise( p ); p = m2*p*2.31;
    f += 0.0625*noise( p ); p = m2*p*2.21;
    f += 0.03125*noise( p );
  
    return f;
}

//----------------------------------------------------------------------
// Wind function by Dave Hoskins https://www.shadertoy.com/view/4ssXW2

vec2 Hash( vec2 n)
{
	vec4 p = texture( iChannel0, n*vec2(.78271, .32837), -100.0 );
    return (p.xy + p.zw) * .5; 
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

vec2 getSectorId( float z ) {
    float id = floor( (z+6.)/12.);
    return vec2( id, hash(id) );
}

float soundLampExist(in float z) {
    vec2 id = getSectorId(z);
    if( hash(id.x+234.) < 0.15 && id.y < 0.75) return 1.;
	return 0.;
}

float soundCeilExist(in float z) { 
    vec2 id = getSectorId(z);
    if( id.y < 0.75) return 0.;
	return 1.;
}

vec2 soundLamp(in float t) {
    float l = 1. - clamp(2.*fbm( vec2(t*10., 2.) ), 0., 1.);
	return 0.1*vec2( hash(t*0.001), hash(t*0.001+0.1) ) * l;
}

vec2 soundCeil(in float t) {
	return (Wind(t*0.025) + Wind(t*4.)*0.15) * (0.75+0.2*sin(t*8.));
}

vec2 soundStep(in float t) {
    float o = 0.2*noise(vec2(t,0.));
    float i = fract(t*1.23+o);
    
    return Wind(t*0.025) * clamp(i*10.,0.,1.) * clamp(1.-i*6., 0., 1.);
}

vec2 getSound(in vec2 sl, in vec2 sc, in float z) {
    return 0.9*soundLampExist(z)*sl + 0.2*soundCeilExist(z)*sc;
}

vec2 mixSounds(in float t, in float z) {
    float zm = floor( (z+6.)/12. ) * 12.;
    
    vec2 sound = vec2(0.);
    vec2 sl = soundLamp(t);
    vec2 sc = soundCeil(t);
    
    sound += getSound(sl, sc, zm-24.) * pow( mix(1., 0., clamp( abs(zm-24. - z)/24., 0., 1. ) ), 2.);
    sound += getSound(sl, sc, zm+24.) * pow( mix(1., 0., clamp( abs(zm+24. - z)/24., 0., 1. ) ), 2.);
    sound += getSound(sl, sc, zm-12.) * pow( mix(1., 0., clamp( abs(zm-12. - z)/24., 0., 1. ) ), 2.);
    sound += getSound(sl, sc, zm+12.) * pow( mix(1., 0., clamp( abs(zm+12. - z)/24., 0., 1. ) ), 2.);
    sound += getSound(sl, sc, zm)     * pow( mix(1., 0., clamp( abs(zm - z)/24., 0., 1. ) ), 2.);
    
    return sound + soundStep(t);    
}

vec2 getSounds(in float t, in float z) {
    vec2 m2 = mixSounds(t, z); 
    
    return 6.*m2;
}

vec2 mainSound( in int samp,float time) {
    float z = time*2.;
	return getSounds(time, z);
}