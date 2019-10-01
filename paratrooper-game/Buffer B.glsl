// Paratrooper. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XsyfD3
//
// I made this shader because I wanted to try  to create a simple 
// but complete game in Shadertoy.
//
// Buffer B: Rendering of the screen (320x200).
//

mat2 rotMatrix(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

void drawHLine(ivec2 uv, const int y, const int height, vec3 color, inout vec3 f) {
	if (uv.y >= y && uv.y < y + height) f = color;
}

void drawTitle(ivec2 uv, const in sampler2D d, inout vec3 f) {
    if (inBox(uv, ivec2(51,40), ivec2(51+218,64))) {
	    int i = (uv.x-51)/20;
        if (i * 16 < iFrame) {
            int o = int[](0,1,2,1,3,2,4,4,0,5,2)[i] * 20;                    
            drawSprite(uv, ivec2(51+i*20,40), ivec2(51+i*20+20,64), ivec2(o,0), iChannel1, false, f);
        }
    }
}

vec3 spriteCanon(ivec2 uv) {
    vec3 col = COL_BLACK;
    
    ivec2 uvRot = ivec2(rotMatrix(gCanonAngle) * vec2(uv));
    
    drawBox(uvRot, ivec2(-1,-12), ivec2(1,0), COL_CYAN, col);
    drawBox(uvRot, ivec2(-2,-11), ivec2(2,0), COL_CYAN, col);
    
    drawBox(uv, ivec2(-2,-4), ivec2(2,-3), COL_MAGENTA, col);
    drawBox(uv, ivec2(-4,-3), ivec2(4,-1), COL_MAGENTA, col);
    drawBox(uv, ivec2(-5,-1), ivec2(5,9), COL_MAGENTA, col);
    drawBox(uv, ivec2(-1,-1), ivec2(1,1), COL_CYAN, col);
    return col;
}

void drawCanon(ivec2 uv, inout vec3 f) {
    vec3 col = spriteCanon(uv - CANON_CENTER);
    if (col.x > 0.) f = col;
}

void drawHelicopter(ivec2 uv, ivec2 heliPos, int si, const in sampler2D d, inout vec3 f) {
    if (heliPos.y > 0) {
        drawSprite(uv, heliPos - ivec2(12,5), heliPos + ivec2(12,5), ivec2(24 * si, 24), d, heliPos.y < 8, f);
    }
}

void drawJet(ivec2 uv, ivec2 jetPos, int si, const in sampler2D d, inout vec3 f) {
    if (jetPos.y > 0) {
        drawSprite(uv, jetPos - ivec2(12,5), jetPos + ivec2(12,5), ivec2(24 * si, 63), d, jetPos.y < 8, f);
    }
}

void drawBomb(ivec2 uv, vec3 paratrooperData, float time, const in sampler2D d, inout vec3 f) {
    if (paratrooperData.x > 0. ) {
        ivec2 pos = ivec2(paratrooperData.xy);
    	drawBox(uv - pos, ivec2(-1,-2), ivec2(1,2), COL_WHITE, f);
    	drawBox(uv - pos, ivec2(-2,-1), ivec2(2,1), COL_WHITE, f);
    }
}

void drawParatrooper(ivec2 uv, vec3 paratrooperData, float time, const in sampler2D d, inout vec3 f) {
    if (paratrooperData.x > 0. ) {
        ivec2 pos = ivec2(paratrooperData.xy);
        drawSprite(uv, pos - ivec2(2,8), pos + ivec2(2,0), ivec2(12,39), d, false, f);
        if (paratrooperData.z > 0. && paratrooperData.z < time) {
        	drawSprite(uv, pos - ivec2(6,22), pos + ivec2(6,-8), ivec2(0,34), d, false, f);            
        }
    }
}

void drawExplosion(ivec2 uv, vec4 d, float time, const sampler2D tex, inout vec3 f) {
    if (time < d.z + EXPLOSION_DURATION && uv.y < 190) {
    	float t = (d.z - time) * (1. / EXPLOSION_DURATION);
        vec2 p = vec2(uv)-d.xy;
        float h = hash12(p*.3);
        if (h*h*h > t) {
            vec2 r = normalize(2. * hash22(p) - 1.) * hash12(p);
            vec2 delta = r * vec2(-t, 1.-t) + vec2(0., t*6.);

            float speed = .5 * (d.x-160.);
            if (d.w > 3.5) {
                speed = d.y > 8. ? AIRCRAFT_SPEED : -AIRCRAFT_SPEED;
                speed *= (1. / EXPLOSION_DURATION);
            } else if (d.w > 2.5) {
                speed = 0.;
                delta *= 10.;
                p.y -= t * 500.;
            }
            p.x += speed * t;
            p -= 20.*delta*t;
            
            uv = ivec2(d.xy + p);

            if (d.w < 1.5) {
                drawSprite(uv, ivec2(d.xy) - ivec2(6,22), ivec2(d.xy) + ivec2(6,-8), ivec2(0,34), tex, false, f); 
            } else if (d.w < 2.5) {
                drawBomb(uv, vec3(d.xyz), time, tex, f);
            } else if (d.w < 3.5) {
            	drawCanon(uv, f);
            } else if (d.w < 4.5) { 
                if (gMode > GAME_HELICOPTER + .5) {
                    drawJet(uv, ivec2(d.xy), 0, tex, f);
                } else {
                    drawHelicopter(uv, ivec2(d.xy), 0, tex, f);
                }
            }
        }
    }
}

void drawScore( ivec2 uv, ivec2 rt, float score, inout vec3 col ) {
    for (int i=0; i<6; i++) {
        if (score > 0. || i == 0) {
            float s = mod(score, 10.);
            drawSprite(uv, rt, rt+ivec2(8,7), ivec2(72,73) + ivec2(s*8.,0), iChannel1, false, col);
            rt.x -= 8;
            score = floor(score * .1);
        }
    }
}

void drawDeadParatrooper( ivec2 uv, vec2 d, float time, inout vec3 col ) {
    if (d.y > time) {
        drawSprite(uv, ivec2(d.x-6.,170), ivec2(d.x+6.,185), ivec2(0,48), iChannel1, false, col);
    }
}

void drawLandedParatrooper( ivec2 uv, float x, float y, inout vec3 col ) {
    if (x > 0.) {
        drawSprite(uv, ivec2(x-2.,182.-y), ivec2(x+2.,190.-y), ivec2(12,39), iChannel1, false, col);
    }
}

void drawLandedParatroopers( ivec2 uv, vec4 d, inout vec3 col ) {
	drawLandedParatrooper(uv, d.x, 0., col);
	drawLandedParatrooper(uv, d.y, d.y==d.x?8.:0., col);
	drawLandedParatrooper(uv, d.z, (d.z==d.x?8.:0.) + (d.z==d.y?8.:0.), col);
	drawLandedParatrooper(uv, d.w, (d.w==d.x?8.:0.) + (d.w==d.y?8.:0.) + (d.w==d.z?8.:0.), col);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    ivec2 uv = ivec2(fragCoord);
    
    if (iResolution.x < 320.) uv *= 2;
    
    if (fragCoord.x < RES.x && fragCoord.y < RES.y ) {
		uv.y = int(RES.y) - uv.y;
        
        loadGameStateMinimal(iTime, iChannel0);

        vec3 col = COL_BLACK;

        // canon
        if (gGameOverTime < .5) {
	        drawCanon(uv, col);
        }
        
        if (gMode > GAME_OVER + .5) {
            // bullets
            for (int i=0; i<MAX_BULLETS FORCE_NO_UNROLL; i++) {
                vec3 b = texelFetch(iChannel0, ivec2(i+BULLET_DATA_OFFSET,0), 0).xyz;
                if (b.z > -10.) {
                    if(uv.x == int(b.x) && uv.y == int(b.y)) {
                        col = COL_WHITE;
                    }
                }
            }

            // aircrafts
            for (int i=0; i<MAX_AIRCRAFTS/2 FORCE_NO_UNROLL; i++) {
                vec4 b = texelFetch(iChannel0, ivec2(i+AIRCRAFT_DATA_OFFSET,0), 0);
                ivec2 p1 = getAircraftPos(b.xy, iTime);
                ivec2 p2 = getAircraftPos(b.zw, iTime);
                if (gMode > GAME_HELICOPTER + .5) {
	                drawJet(uv, p1, (i + int(iTime * 8.)) & 1, iChannel1, col);
    	            drawJet(uv, p2, (i + int(iTime * 8.)) & 1, iChannel1, col);
                } else {
	                drawHelicopter(uv, p1, (i + int(iTime * 16.)) & 3, iChannel1, col);
    	            drawHelicopter(uv, p2, (i + int(iTime * 16.)) & 3, iChannel1, col);
                }
            }

            // paratroopers
            for (int i=0; i<MAX_PARATROOPERS FORCE_NO_UNROLL; i++) {
                vec3 b = texelFetch(iChannel0, ivec2(i+PARATROOPER_DATA_OFFSET,0), 0).xyz;
                if (gMode < GAME_HELICOPTER + .5) {
                	drawParatrooper(uv, b, iTime, iChannel1, col);
                } else {
	                drawBomb(uv, b, iTime, iChannel1, col);
                }
            }
            
            // landed paratroopers
            drawLandedParatroopers(uv, gParatroopersLeft, col);
            drawLandedParatroopers(uv, gParatroopersRight, col);
            
            // deadParatroopers
            drawDeadParatrooper(uv, gDeadParatroopers.xy, iTime, col);
            drawDeadParatrooper(uv, gDeadParatroopers.zw, iTime, col);
        } else {
            drawTitle(uv, iChannel1, col);
            if (iResolution.x > 320.) {
            	drawSprite(uv, ivec2(28,80), ivec2(291,87), ivec2(0,80), iChannel1, false, col);
            }
        }
        
        drawExplosion(uv, gExplosion1, iTime, iChannel1, col);
        drawExplosion(uv, gExplosion2, iTime, iChannel1, col);
        
        drawHLine(uv, 190, 1, COL_CYAN, col);
        drawBox(uv, ivec2(145,166), ivec2(176,190), COL_WHITE, col);

        // score
        if (uv.y > 190) {
            drawSprite(uv, ivec2(0,192), ivec2(46,199), ivec2(24,73), iChannel1, false, col); 
            drawScore(uv, ivec2(100,192), gScore, col);
            drawSprite(uv, ivec2(200,192), ivec2(269,199), ivec2(0,73), iChannel1, false, col); 
            drawScore(uv, ivec2(308,192), gHighScore, col);
        }
            
        fragColor = vec4(col, 1.0);
    } else {
        fragColor = vec4(0,0,0,1);
    }
}