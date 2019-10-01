// Paratrooper. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XsyfD3
//
// I made this shader because I wanted to try  to create a simple 
// but complete game in Shadertoy.
//
// Buffer A: Game logic. As usual this code started nice, but in the
//           end I added a lot of if-statements and it became a mess.
//

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
	return texelFetch( iChannel0, ivec2(key, 0), 0 ).x > 0.0;
}

bool KT(int key) {
	return texelFetch( iChannel0, ivec2(key, 2), 0 ).x > 0.0;
}

float sBox( in vec2 ro, in vec2 rd, in vec2 rad ) {
    if(rd.x == 0.) rd.x = 0.001;
    vec2 m = 1./rd;
    vec2 n = m*ro;
    vec2 k = abs(m)*rad;
	
    vec2 t1 = -n - k;
    vec2 t2 = -n + k;

	float tN = max( t1.x, t1.y );
	float tF = min( t2.x, t2.y );
    if( tN > tF || tF < 0.0) {
        return -1.0;
    } else {
		return tN;
    }
}

bool shoot(float time) {
    if (gLastShot + SHOT_COOLDOWN < time) {
        gLastShot = time;
        return true;
    }
    return false;
}

void paratrooperLand(float x, inout vec4 data) {
    if(data.x <= 0.) data.x = x;
    else if(data.y <= 0.) data.y = x;
    else if(data.z <= 0.) data.z = x;
    else if(data.w <= 0.) data.w = x;
}

void killParatrooperAtPos(float x, inout vec4 data) {
    if(data.x == x) data.x = 0.;
    if(data.y == x) data.y = 0.;
    if(data.z == x) data.z = 0.;
    if(data.w == x) data.w = 0.;
}

void deadParatrooper(float x, float time) {
    float visibleUntil = time + DEAD_PARATROOPER_DT;
    if (gDeadParatroopers.y < visibleUntil) {
        gDeadParatroopers.x = x;
        gDeadParatroopers.y = visibleUntil;
    } else {
        gDeadParatroopers.z = x;
        gDeadParatroopers.w = visibleUntil;
    }
    if (x < 160.) {
        killParatrooperAtPos(x, gParatroopersLeft);
    } else {
        killParatrooperAtPos(x, gParatroopersRight);
    }
}

void initExplosion(vec2 pos, float time, float type) {
    if (gExplosion1.z < time - EXPLOSION_DURATION) {
        gExplosion1 = vec4(pos, time, type);
    } else {
        gExplosion2 = vec4(pos, time, type);
    }
}

void initNewBullet(int index) {
    float a = gCanonAngle;
    gBulletData[index].z = a;
    gBulletData[index].xy = vec2(CANON_CENTER) + vec2(sin(a),-cos(a)) * 20.;
}

void initAircraft(int index, float time, bool direct) {
    float h = direct ? 0. : hash11(float(index)+time);
    gLastAircraft += mix(MIN_AIRCRAFT_DT, MAX_AIRCRAFT_DT, h*h*h*h);
    if (gLastAircraft < gEndRoundTime) {
        float d = hash11(float(index)+time+.5)-.4 > 0. ? 1. : -1.;
        float ph = hash11(float(index)+time+.75);
        float p = gMode > GAME_HELICOPTER + .5 ?  
           (ph > .25 ? gLastAircraft + BOMB_DT : INF) : MAX_PARATROOP_DT * ph + gLastAircraft;
        gAircraftData[index] = vec2(gLastAircraft * d, p);
    } else {
        gAircraftData[index] = vec2(-20);
    }
}

void initAircrafts(float time) {
    gLastAircraft = time;
    for (int i=0; i<MAX_AIRCRAFTS; i++) {
        initAircraft(i, time, i == 0);
    }
}

bool fourParatroopersLanded(vec4 d) {
    return d.x > 0. && d.y > 0. && d.z > 0. && d.w > 0.;
}

void initNewRound(float mode, float time) {
    gMode = mode;
    gEndRoundTime = time + 
        ((gMode < GAME_HELICOPTER + .5) ? ROUND_HELICOPTER_TIME : ROUND_JET_TIME);
    
    initAircrafts(time);
}

void initNewGame(float time) {
    gParatroopersLeft = vec4(0);
    gParatroopersRight = vec4(0);
    gScore = 0.;
    gLastShot = time;
    gGameOverTime = 0.;
    
    for (int i=0; i<MAX_BULLETS; i++) {
    	gBulletData[i].z = -20.;
    }
    for (int i=0; i<MAX_PARATROOPERS; i++) {
    	gParatrooperData[i].x = -20.;
    }
    
    initNewRound(GAME_HELICOPTER, time);
}

void recycleBullet(inout vec3 bullet, float score) {
    bullet.z = -20.;
    gScore += score;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    ivec2 uv = ivec2(fragCoord);
    
    // gameloop
    if( uv.y == 0 && uv.x < 100) {
        loadGameStateFull(iTime, iChannel1);
		bool gameOver = false;
     	
        if (gMode < GAME_OVER + .5) {      
            if( KP(KEY_SPACE) ) {
                initNewGame(iTime);       
            }
        } else {
            // user input
            bool wantShot = false;
            if (gGameOverTime < .5) {
                if( KP(KEY_LEFT) || KP(KEY_A) ) {
                    gCanonMovement = -1.;
                }
                if( KP(KEY_RIGHT) || KP(KEY_D) ) {
                    gCanonMovement = 1.;
                }
                if( KP(KEY_UP) || KP(KEY_W) || KP(KEY_SPACE) ) {
                    gCanonMovement = 0.;
                    wantShot = shoot(iTime);
                    if (wantShot) {
                        gScore = max(0., gScore - 1.);
                    }
                }
                gCanonAngle += gCanonMovement * gDT * CANON_ROT_SPEED;
                gCanonAngle = sign(gCanonAngle) * min(abs(gCanonAngle), CANON_MAX_ANGLE);
            }
            
            // save old y-coordinate for collision detection with bullets
            for (int i=0; i<MAX_PARATROOPERS; i++) {
            	gParatrooperData[i].w = gParatrooperData[i].y;
            }
            
            if (gMode < GAME_HELICOPTER + .5) {
                // helicopter mode
                
                // aircrafts
                float wantParatrooper = -20.;
                for (int i=0; i<MAX_AIRCRAFTS FORCE_NO_UNROLL; i++) {
                    ivec2 p = getAircraftPos(gAircraftData[i], iTime);
                    if (p.x < -20 || p.x > int(RES.x) + 20) {
                        initAircraft(i, iTime, false);
                    }
                    if (gAircraftData[i].y < iTime && iTime > gLastParatrooper + MIN_PARATROOP_DT) {
                        // drop paratrooper
                        wantParatrooper = floor(float(p.x)/6.)*6.;
                        gAircraftData[i].y = iTime + MAX_PARATROOP_DT * hash11(float(i)+iTime+.75);
                    }
                }

                // paratroopers
                float paratrooperFrameDist_0 = (gDT * PARATROOPER_SPEED_0);
                float paratrooperFrameDist_1 = (gDT * PARATROOPER_SPEED_1);

                for (int i=0; i<MAX_PARATROOPERS FORCE_NO_UNROLL; i++) {
                    vec4 p = gParatrooperData[i];
                    if (p.x > 0.) {
                        gParatrooperData[i].y += p.z > 0. && p.z < iTime 
                            ? paratrooperFrameDist_1 : paratrooperFrameDist_0;
                        if (p.y > 190.) {
                            float x = p.x;
                            if (p.z < 0.) {
                                deadParatrooper(x, iTime);
                            } else {
                                if (x<160.) {
                                    paratrooperLand(x, gParatroopersLeft );
                                } else {
                                    paratrooperLand(x, gParatroopersRight );
                                }
                            }
                            gParatrooperData[i].x = -20.;
                        }
                    } else if(wantParatrooper > 0.) {
                        float x = abs(wantParatrooper-RES.x*.5);
                        if (x > 30. && x < RES.x*.5 - 5.) {
                            gParatrooperData[i].xyw = vec3(wantParatrooper, 30.,30.);
                            gParatrooperData[i].z = iTime +mix(MIN_PARATROOP_OPEN_DT, MAX_PARATROOP_OPEN_DT, hash11(float(i)+iTime+.25));;
                        }
                        wantParatrooper = -20.;
                        gLastParatrooper = iTime;
                    }
                }
            } else {
                // jet mode
                
                // aircrafts
                float wantBomb = -20.;
                for (int i=0; i<MAX_AIRCRAFTS FORCE_NO_UNROLL; i++) {
                    ivec2 p = getAircraftPos(gAircraftData[i], iTime);
                    if (gAircraftData[i].y < iTime) {
                        // drop bomb
                        if(iTime > gLastParatrooper + BOMBS_DT) {
                        	wantBomb = float(p.x);
                        }
                        gAircraftData[i].y = INF;
                    }
                }
                
                // use paratrooperdata for bombs
                for (int i=0; i<MAX_PARATROOPERS FORCE_NO_UNROLL; i++) {
                    vec4 p = gParatrooperData[i];
                    if (p.x > 0.) {
                        gParatrooperData[i].xy -= normalize(p.xy - vec2(160,175)) * (gDT * BOMB_SPEED);
                        if (p.y > 170.) {
                            gParatrooperData[i].x = -20.;
                            gameOver = true;
                        }
                    } else if(wantBomb > 0.) {
                        gParatrooperData[i].xyw = vec3(wantBomb, 20., 20.);
                        wantBomb = -20.;
                        gLastParatrooper = iTime;
                    }
                }
            }

            // bullets
            float bulletFrameDist = (gDT * BULLET_SPEED);

            for (int i=0; i<MAX_BULLETS FORCE_NO_UNROLL; i++) {
                if (gBulletData[i].z > -10.) {
                    float a = gBulletData[i].z;
                    vec2 ro = gBulletData[i].xy;

                    vec2 newPos = ro + vec2(sin(a),-cos(a)) * bulletFrameDist;
                    if (newPos.x < 0. || newPos.x > RES.x || newPos.y < 0.) {
                        gBulletData[i].z = -20.;
                    }
                    vec2 rd = normalize(newPos - ro);

          			if (gGameOverTime < .5) {
                        if (gBulletData[i].z > -10.) {
                            for (int j=0; j<MAX_AIRCRAFTS FORCE_NO_UNROLL; j++) {
                                ivec2 p = getAircraftPos(gAircraftData[j], iTime);
                                float d = sBox(ro - vec2(p), rd, vec2(12,5));
                                if (d > 0. && d < bulletFrameDist) {
                                    initAircraft(j, iTime, false);
                                    initExplosion(vec2(p), iTime, 4.);
                                    recycleBullet(gBulletData[i], 10.);
                                    break;
                                }
                            }
                        }

                        if (gBulletData[i].z > -10.) {            
                            if (gMode < GAME_HELICOPTER + .5) {
                                for (int j=0; j<MAX_PARATROOPERS FORCE_NO_UNROLL; j++) {
                                    vec2 p = gParatrooperData[j].xy;
                                    float dy = (gParatrooperData[j].y - gParatrooperData[j].w)*.5;
                                    float d = sBox(ro - p + vec2(0,4.-dy), rd, vec2(2,4.+dy));
                                    if (d > 0. && d < bulletFrameDist) {
                                        gParatrooperData[j].x = -20.;
                                        initExplosion(p, iTime, 1.);
                                        recycleBullet(gBulletData[i], 5.);
                                        break;
                                    } else if(gParatrooperData[j].z > 0. && iTime > gParatrooperData[j].z) {
                                        float d = sBox(ro - p + vec2(0,15.-dy), rd, vec2(6,7.+dy));
                                        if (d > 0. && d < bulletFrameDist) {
                                            gParatrooperData[j].z = -20.;
                                            initExplosion(p, iTime, 1.);
                                            recycleBullet(gBulletData[i], 5.);
                                            break;
                                        }
                                    }
                                }
                            } else {
                                // bombs
                                for (int j=0; j<MAX_PARATROOPERS FORCE_NO_UNROLL; j++) {
                                    vec2 p = gParatrooperData[j].xy;
                                    float dy = (gParatrooperData[j].y - gParatrooperData[j].w)*.5;
                                    float d = sBox(ro - p + vec2(0,-dy), rd, vec2(4,2.+dy));
                                    if (d > 0. && d < bulletFrameDist) {
                                        gParatrooperData[j].x = -20.;
                                        initExplosion(p, iTime, 2.);
                                        recycleBullet(gBulletData[i], 30.);
                                        break;
                                    }
                                }
                            }
                        }       
                    }

                    gBulletData[i].xy = newPos;
                } else if(wantShot) {
                    initNewBullet(i);
                    wantShot = false;
                }
               
                for (int i=0; i<MAX_PARATROOPERS FORCE_NO_UNROLL; i++) {
                    if (gParatrooperData[i].x > 0.) {
                        gEndRoundTimeCoolDown = iTime + ROUND_COOL_DOWN_TIME; 
                    }
                }
                float endTime = max(gEndRoundTimeCoolDown, gEndRoundTime + (RES.x/AIRCRAFT_SPEED) + ROUND_COOL_DOWN_TIME);

                if (iTime > endTime) {
                    if (gMode < GAME_HELICOPTER + .5) {
						initNewRound(GAME_JET, iTime);
               		} else {
                    	initNewRound(GAME_HELICOPTER, iTime);
                    }
                }
            }
        }
        
        if (gameOver || 
            fourParatroopersLanded(gParatroopersLeft) || 
            fourParatroopersLanded(gParatroopersRight)) {
            
            if (gGameOverTime < .5) {
                gGameOverTime = iTime + GAME_OVER_DURATION;
                gHighScore = max(gHighScore, gScore);
                initExplosion(vec2(CANON_CENTER), iTime, 3.);
            }
        }

        if (gGameOverTime > .5 && iTime > gGameOverTime) {
            initNewGame(iTime);
            gMode = GAME_OVER;
        }
        
        // save state
        saveGameState(uv, iTime, fragColor);
    }
    
    if (iFrame == 0) {
        fragColor = vec4(0);
    }
}