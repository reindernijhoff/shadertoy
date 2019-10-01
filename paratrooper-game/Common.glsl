// Paratrooper. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XsyfD3
//
// I made this shader because I wanted to try  to create a simple 
// but complete game in Shadertoy.
//

#define FIXED_TIME_STEP
#define FORCE_NO_UNROLL +min(0,int(iFrame))

#define RES vec2(320,200)
#define CANON_CENTER ivec2(160,157)

#define COL_WHITE vec3(1)
#define COL_BLACK vec3(0)
#define COL_MAGENTA (vec3(253,93,252)/255.)
#define COL_CYAN (vec3(95,255,254)/255.)

#define INF 1e10

// game defines

#define GAME_OVER 0.
#define GAME_HELICOPTER 1.
#define GAME_JET 2.

#define EXPLOSION_DURATION 1.
#define GAME_OVER_DURATION 3.

#define ROUND_HELICOPTER_TIME 20.
#define ROUND_JET_TIME 5.
#define ROUND_COOL_DOWN_TIME 1.

#define CANON_ROT_SPEED 2.3
#define CANON_MAX_ANGLE 1.4

#define MAX_BULLETS 8
#define BULLET_SPEED 125.
#define SHOT_COOLDOWN .21


#define MAX_AIRCRAFTS 6
#define MIN_AIRCRAFT_DT .75
#define MAX_AIRCRAFT_DT 5.5
#define AIRCRAFT_SPEED 70.

#define MAX_PARATROOPERS 5
#define MIN_PARATROOP_DT 1.25
#define MAX_PARATROOP_DT 6.

#define PARATROOPER_SPEED_0 92.
#define PARATROOPER_SPEED_1 47.5
#define MIN_PARATROOP_OPEN_DT .2
#define MAX_PARATROOP_OPEN_DT .8

#define BOMB_DT 0.5
#define BOMBS_DT 2.
#define BOMB_SPEED 105.

#define DEAD_PARATROOPER_DT 1.

#define BULLET_DATA_OFFSET 10
#define AIRCRAFT_DATA_OFFSET 20
#define PARATROOPER_DATA_OFFSET 30

// global game variables

float gDT;
float gCanonMovement;
float gCanonAngle;
float gMode;

float gScore;
float gHighScore;
float gEndRoundTime;
float gEndRoundTimeCoolDown;
float gGameOverTime;

float gLastShot;
vec3 gBulletData[MAX_BULLETS];
    
float gLastAircraft;
vec2 gAircraftData[MAX_AIRCRAFTS];

float gLastParatrooper;
vec4 gParatrooperData[MAX_PARATROOPERS];

vec4 gDeadParatroopers;
vec4 gParatroopersLeft;
vec4 gParatroopersRight;

vec4 gExplosion1;
vec4 gExplosion2;

void saveGameState(ivec2 uv, float time, inout vec4 f) {
    if(uv.x == 0) f = vec4(time, gCanonMovement, gCanonAngle, gMode);
    if(uv.x == 1) f = vec4(gLastShot, gLastAircraft, gScore, gHighScore);
    if(uv.x == 2) f = vec4(gLastParatrooper,gEndRoundTime,gEndRoundTimeCoolDown,gGameOverTime);
    if(uv.x == 3) f = gDeadParatroopers;
    if(uv.x == 4) f = gParatroopersLeft;
    if(uv.x == 5) f = gParatroopersRight;
    if(uv.x == 6) f = gExplosion1;
    if(uv.x == 7) f = gExplosion2;
    
    for (int i=0; i<MAX_BULLETS; i++) {
        if(uv.x == i+BULLET_DATA_OFFSET) f = vec4(gBulletData[i],0);
    }
    for (int i=0; i<MAX_AIRCRAFTS/2; i++) {
        if(uv.x == i+AIRCRAFT_DATA_OFFSET) f = vec4(gAircraftData[i*2+0], gAircraftData[i*2+1]);
    }
    for (int i=0; i<MAX_PARATROOPERS; i++) {
        if(uv.x == i+PARATROOPER_DATA_OFFSET) f = gParatrooperData[i];
    }
}

void loadGameStateMinimal(float time, sampler2D storage) {
    vec4 f;

    f = texelFetch(storage, ivec2(0,0), 0);
#ifdef FIXED_TIME_STEP
    gDT = (1./60.);
#else
    gDT = time - f.x;
#endif
    gCanonMovement = f.y;
    gCanonAngle = f.z;
    gMode = f.w;
    
    f = texelFetch(storage, ivec2(1,0), 0);
    gLastShot = f.x;
    gLastAircraft = f.y;
    gScore = f.z;
    gHighScore = f.w;
    
    f = texelFetch(storage, ivec2(2,0), 0);
    gLastParatrooper = f.x;
    gEndRoundTime = f.y;
    gEndRoundTimeCoolDown = f.z;
    gGameOverTime = f.w;
    
    gDeadParatroopers = texelFetch(storage, ivec2(3,0), 0);
    gParatroopersLeft = texelFetch(storage, ivec2(4,0), 0);
    gParatroopersRight = texelFetch(storage, ivec2(5,0), 0);
    
    gExplosion1 = texelFetch(storage, ivec2(6,0), 0);
    gExplosion2 = texelFetch(storage, ivec2(7,0), 0);
}

void loadGameStateFull(float time, sampler2D storage) {
    loadGameStateMinimal(time, storage);
        
    for (int i=0; i<MAX_BULLETS; i++) {
    	gBulletData[i] = texelFetch(storage, ivec2(i+BULLET_DATA_OFFSET,0), 0).xyz;
    }
    
    for (int i=0; i<MAX_AIRCRAFTS/2; i++) {
        vec4 f = texelFetch(storage, ivec2(i+AIRCRAFT_DATA_OFFSET,0), 0);
        gAircraftData[i*2+0] = f.xy;
        gAircraftData[i*2+1] = f.zw;
    } 
    
    for (int i=0; i<MAX_PARATROOPERS; i++) {
    	gParatrooperData[i] = texelFetch(storage, ivec2(i+PARATROOPER_DATA_OFFSET,0), 0);
    }
}

//
// Hash functions
//
// Hash without Sine by Dave_Hoskins
//
// https://www.shadertoy.com/view/4djSRW
//

#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)

float hash11(float p) {
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

// game functions
ivec2 getAircraftPos(vec2 data, float time) {
    float t = (time-abs(data.x));
    if (t > 0.) {
        int p = int(t * AIRCRAFT_SPEED) - 10;
        bool ltr = data.x > 0.;
    	return ivec2(ltr ? p : int(RES.x) - p, ltr ? 18 : 6);
    } else {
        return ivec2(-1);
    }
}

// draw functions

bool inBox(const ivec2 uv, const ivec2 lt, const ivec2 rb) {
    return (uv.y >= lt.y && uv.y < rb.y && uv.x >= lt.x && uv.x < rb.x);
}

void drawBox(const ivec2 uv, const ivec2 lt, const ivec2 rb, const vec3 color, inout vec3 f) {
	if (inBox(uv, lt, rb)) f = color;    
}

void drawSprite(const ivec2 uv, const ivec2 lt, const ivec2 rb, const ivec2 offset, const in sampler2D d, const bool flip, inout vec3 f) {
    if (inBox(uv, lt, rb)) {
        ivec2 c = uv - lt;
    	c.x = flip ? (rb.x-lt.x)-c.x-1 : c.x;
    
        vec3 col = texelFetch(d, offset + c, 0).rgb;    
        f = col.r > 0. ? col : f;
    }
}