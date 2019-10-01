// Created by Reinder Nijhoff 2015
// @reindernijhoff
//
// https://www.shadertoy.com/view/MtsXzf
//

#define HIGHQUALITY 1

#define N(a) if(t>b)x=b;b+=a;
#define NF(a,c,g) if(t>b){x=b;f=c;v=g;d=a;}b+=a;

//----------------------------------------------------------------------------------------

#define BPM             (140.0)
#define STEP            (4.0 * BPM / 60.0)
#define ISTEP           (1./STEP)
#define LOOPCOUNT		(16.)
#define STT(t)			(t*(60.0/BPM))

#define PI2 6.283185307179586476925286766559

#define D 36.71
#define A 55.00	
#define B 61.74
#define C 65.41

//-----------------------------------------------------
// noise functions

#define MOD2 vec2(.16632,.17369)
float hash(const in float p) { // by Dave Hoskins
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}

float sine(const in float x) {
    return sin(PI2 * x);
}

float loop(const in float t, const in float steps) {
    return mod(t, steps * ISTEP);
}

float distortion(const in float s, const in float d) {
	return clamp(s * d, -1.0, 1.0);
}

float quan(const in float s, const in float c) {
	return floor(s / c) * c;
}

bool inLoop( float time, float s, float e ) {
    float t = (time * (STEP / LOOPCOUNT));
    return ( t >= s && t < e );
}

//-----------------------------------------------------
// instruments by iq and And

float snare(const in float t, const in float f0) {
    float op3 = sine((t * f0) * 2.8020) * exp(-t * 1.0);
    float op2 = sine((t * f0) * 2.5000 + op3 * 1.00);
    float op1 = sine((t * f0) * 18.000 + op2 * 0.72);

    return op1 * exp(-t * 5.5);
}

float kick(float tb) {
	const float aa = 5.0;
	tb = sqrt(tb * aa) / aa;
	
	float amp = exp(max(tb - 0.015, 0.0) * -5.0);
	float v = sine(tb * 100.0) * amp;
	v += distortion(v, 4.0) * amp;
	return v;
}

float bass(const in float time, const in float freq, const in float duration) {
    float ph = 1.0;
    ph *= sin(6.2831*freq*time);
    ph *= 0.1+0.9*max(0.0,6.0-0.01*freq);
    ph *= exp(-time*freq*0.3);
    
    
    float y = 0.;
    y += 0.70*sin(1.00*PI2*freq*time+ph);//*exp(-0.07*time);
    y += 0.90*sin(2.01*PI2*freq*time+ph);//*exp(-0.11*time);

    y += 0.145*y*y*y;   

    y *= 1.-smoothstep( duration*0.9, duration, time * STEP );

    return y;
}

float bell(const in float t, const in float f0) {
    float op3 = sine((f0 * t) * 6.0000             ) * exp(-t * 5.0);
    float op2 = sine((f0 * t) * 7.2364 + op3 * 0.20);
    float op1 = sine((f0 * t) * 2.0000 + op2 * 0.13) * exp(-t * 2.0);

    return op1;
}

float lift(float time) {
    return sin(PI2*D*32.*time)*exp(-6.0*time) + bell(time, D*32.);
}

float gun(float time, float f, const in float d) {
    return distortion( textureLod( iChannel0, vec2(time*5.7864, time*6.9732)*f, 0. ).x *exp(-10.0*time)
                       * smoothstep(0.,0.1,time) * (1.-smoothstep(0.5,.6,time)), d);
}

//-----------------------------------------------------
// loops

float loopBass(const in float t, const in float m) {
    float x = 0., b = 0., f = 0., v = 0., d;
                
    NF(2.,D,0.9);NF(2.,D,1.);NF(1.,D,0.5);NF(1.,D,0.6);NF(1.,D,0.5);
    NF(2.,A,1.05);NF(1.,D,0.5);NF(2.,B,0.9);NF(1.,D,0.5); NF(3.,C,1.);
    f *= m;
    
    return v * bass( (t-x)*ISTEP, f, d );

}
    
float loopBassIntro(const in float t) {
    float x = 0., b = 0., f = 0., v = 0., d;
    NF(4.,A,.5);NF(2.,D,.8);NF(8.,D,1.);NF(2.,D,.25);
    
    return v * bass( (t-x)*ISTEP, f*.5, d );
}

float loopDrums(const in float t) {
    float x = 0., b = 0., r;
    
    // base
    N(3.);N(7.);N(1.);N(5.);
	r = kick( (t-x)*ISTEP*1.2 );
    
    // bell
    x = b = 0.;
    N(4.);N(4.);N(4.);N(2.);N(2.);
    r += .25 * bell( (t-x)*ISTEP*8., 100. );
    
    // hihat
    x = b = 0.;
    N(3.);N(3.);N(2.);N(2.);N(4.);
    r += .35 * snare( (t-x)*ISTEP*2., 200.+t );
    
    // snare
    x = b = 0.;
    N(4.);N(3.);N(2.);N(3.);N(1.);N(3.);
    r += .75 * snare( (t-x)*ISTEP*8., 10. );

    return r;
}

float loopDrumsIntro(const in float t) {
    float x = 0., b = 0.;
    
    // snare
    N(1.);N(3.);N(3.);N(2.);N(1.);N(1.);N(1.);N(1.);N(1.);N(1.);N(1.);
    return (t/24.) * snare( (t-x)*ISTEP*8., 10. ) + kick(  (t)*ISTEP*1.2 );
}

float loopGun( const in float time, const in float interval, const in float numshots, 
               const in float shotdelay, const in float minf, const in float maxf ) {
    float it = mod( time, interval );

#if HIGHQUALITY
    float m = 0.;
    for( float sh = 0.; sh<2.5; sh+=1.) {
        if( sh < numshots ) {
            float g = (0.5+0.5*hash(sh+.5))*gun( it - sh*shotdelay - .5*shotdelay*hash(sh), mix(minf, maxf, hash(sh+.25)), 1.5 );
    		m = m+g - abs(m)*g;
        }
    }
 
    return m;
#else
    float sh = floor( it/shotdelay );
    if( sh < numshots ) {
        return (0.5+0.5*hash(sh+.5))*gun( it - sh*shotdelay - .5*shotdelay*hash(sh), mix(minf, maxf, hash(sh+.25)), 1.5 );
    }
    return 0.;
#endif
}



//-----------------------------------------------------
// music

float loopMusic(const in float time) {
	float mtime = loop( time, 16. );
    float t = mtime * STEP;
    float m = 1.;
    
    float d = 0.;
    float b = 0.;
    
    if( inLoop( time, 2., 36. ) && !inLoop( time, 6., 8. ) && !inLoop( time, 15., 16. )  ) {
        d = loopDrums( t );
    }
    
    if( inLoop( time, 1., 2. ) || inLoop( time, 7., 8. ) || inLoop( time, 11., 12. ) ) {
        d += loopDrumsIntro( t );
    }
    
    if( inLoop( time, 10., 12. ) ) {
        m = B/D;
    }

    return loopBass( t, m ) + .5*d;
}

float loopIntro(const in float time) {
	float mtime = loop( time, 16. );
    float t = mtime * STEP;
    
	if( inLoop( time, .74, 5.25 ) ) {
        return loopBassIntro( t );
    }
    return 0.;
}
    
float loopBackground( const in float time ) {
    float m = 0., g = 0.;
    g = .5 * loopGun( time, 2., 3., .21, 1., 1.5 );
    m = m+g - abs(m)*g;
    
    g = .95 * loopGun( time-4.123, 3., 1., 1.5, 1., 1.5 );
    m = m+g - abs(m)*g;
    
    g = .7 * loopGun( time-3., 3.2, 2., .41, 1., 1.5 );
    m = m+g - abs(m)*g;
    
    return m;
}

void initExplosions( in float time );
float exTime1, exTime2;

//-----------------------------------------------------
// main
    
vec2 mainSound(float time) {
        
    initExplosions(time);
    // align with music
    exTime1 = floor( exTime1 / ISTEP * 2.)*ISTEP*.5;
    exTime2 = floor( exTime2 / ISTEP * 2.)*ISTEP*.5;
    
    float m = 0., music = 0., gun1 = 0., gun2 = 0., bg = 0.;
    
    if( time < STT(34.) ) {
        music = loopIntro( time );
    } else if( time < STT(98.) ){
        music = loopMusic( time-STT(34.) );
    }
    music *= .25;
    
    gun1 = gun( time-exTime1, mix(1.,1.5,hash(exTime1)), 3. );
    gun2 = gun( time-exTime2, mix(1.,1.5,hash(exTime2)), 3. );
    
    if( time > STT(34.) && time < STT(84.)  ) {
        bg = loopBackground(time);
    }
    
    m = m+bg - abs(m)*bg;
    m = m+music - abs(m)*music;
    
    m = m+gun1 - abs(m)*gun1;
    m = m+gun2 - abs(m)*gun2;
    
    m *= 1.5;
    
    if( time > 44.5 ) m += .0625*lift( time-44.5);
    
    return vec2( clamp(m, -1., 1.) );
}


//----------------------------------------------------------------------
// explosions

#define E1(a,b,c,d) t+=a;if( time >= t ){exTime2=exTime1;exTime1=t;}
#define E2(a,b,c,d) t+=a;if( time >= t ){exTime2=exTime1;exTime1=t;}
#define E3(a,b,c,d) t+=a;if( time >= t ){exTime2=exTime1;exTime1=t;}
#define E4(a,b,c,d) t+=a;if( time >= t ){exTime2=exTime1;exTime1=t;}
#define E5(a,b,c,d) t+=a;if( time >= t ){exTime2=exTime1;exTime1=t;}

void initExplosions( in float time ) {
	exTime1 = exTime2 = -1000.;
    
    float t = 0.;    
    E1(STT(21.), 16., 3.9, 8.2 );
    E2(.7, 16., 5.4, 6.1 );
    E3(.3, 16., 6.3, 7.7 );
    E4(1., 16., 4.8, 8.2 );
    E5(.7, 16., 5.7, 7.3 );
    
    t = 0.;
    E1(STT(34.), -16., 3.9, 5.2 );
    E2(.5, -16., 5.4, 5.1 );
    E3(.7, -16., 6.3, 6.7 );
    E4(.5, -16., 4.8, 7.2 );
    E5(.4, -16., 5.7, 6.3 );
        
    t = 0.;
    E1(STT(42.), -19.1, 3.9, -4.5 );
    E2(1.3, -17.4, 5.4, -4.5 );
    E3(.3, -18.2, 6.3, -4.5 );
    E4(.4, -17.7, 4.8, -4.5 );
    E5(.3, -16.7, 5.7, -4.5 );
  
    E3(.3, -18.2, 6.3, -4.5 );
    E2(.2, -17.4, 5.4, -4.5 );
    E3(.1, -18.2, 6.3, -4.5 );
    E4(.2, -17.7, 4.8, -4.5 );
    E5(.1, -16.7, 5.7, -4.5 );
    
    E1(.9, -16., 3.9, -5.2 );
    E2(.5, -16., 5.4, -5.1 );
    E3(.3, -16., 6.3, -6.7 );
    E4(.5, -16., 4.8, -7.2 );
    E5(.4, -16., 5.7, -6.3 );    
    
    t = 0.;    
    E1(STT(58.), 16., 3.9, 2.2 );
    E2(.2, 16., 5.4, 4.1 );
    E3(.3, 24., 6.3, 3.7 );
    E4(.5, 16., 4.8, 8.2 );
    E5(.7, 24., 5.7, 4.3 );
    E1(.1, 16., 1.9, 8.2 );
    E2(.2, 24., 5.4, -2.1 );
    
    t = 0.;
    E1(STT(66.), 16., 3.9, 6.5 );
    E2(.2, 16., 5.4, 6.1 );
    E5(.3, 16., 6.7, 7.3 );
    E3(.3, 16., 6.3, 5.7 );
    E4(.2, 16., 7.8, 6.2 );
        
    E5(.1, 16., 5.7, 4.7 );
    E1(.2, 16., 3.9, -6.2 );
    E2(.3, 17., 6.4, -4.5 );
    E3(.3, 16., 6.3, -5.7 );
    E4(.5, 16., 7.8, -6.2 );    
    E5(.3, 16., 5.7, -7.7 );
    E1(.2, 16., 3.9, -6.2 );
    E2(.3, 16., 6.4, -4.5 );
   
    t = 0.;
    E1(STT(78.), -17.1, 3.9, -4.5 );
    E2(.3, -17.4, 5.4, -4.5 );
    E3(.3, -18.2, 6.3, -4.5 );
    E4(.4, -17.7, 4.8, -4.5 );
    E5(.3, -16.7, 5.7, -4.5 );
  
    E3(1.3, -18.2, 6.3, -4.5 );
    E2(.2, -17.4, 5.4, -4.5 );
    E3(.1, -18.2, 6.3, -4.5 );
    E4(.2, -17.7, 4.8, -4.5 );
    E5(.1, -16.7, 5.7, -4.5 );
    
    E2(.5, -19.6, 5.4, -5.1 );
    E1(.9, -19.6, 3.9, -5.2 );
    E3(.3, -19.6, 6.3, -6.7 );
    E4(.5, -19.6, 4.8, -7.2 );
    E5(.4, -19.6, 5.7, -6.3 );
}

