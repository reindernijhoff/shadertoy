// Legend of the Gelatinous Cube. Created by Reinder Nijhoff 2017
// @reindernijhoff
// 
// https://www.shadertoy.com/view/Xs2Bzy
//
// I created this shader in one long night for the Shadertoy Competition 2017
// 

// GAME LOGIC

const int MOVESTEPS = 60;
const int USERMOVESTEPS = 30;
const int USERROTATESTEPS = 30;
const int USERACTIONSTEPS = 30;
const int DOORMOVESTEPS = 30;
const int DOOROPENSTEPS = 300;
const int MAXSWORD = 30;

const ivec2 DIRECTION[] = ivec2[] (
    ivec2(0,1),
    ivec2(1,0),
    ivec2(0,-1),
    ivec2(-1,0)
);

ivec2 USERCOORD = ivec2(0);
ivec2 USERACTIONCOORD = ivec2(0);
int USERDIR = 0;
int USERACTION = 0;
int USERACTIONCOUNT = 0;
ivec4 USERINV = ivec4(0);

const int NONE = 0;
const int FORWARD = 1;
const int BACK = 2;
const int ROT_LEFT = 3;
const int ROT_RIGHT = 4;
const int ACTION = 5;


#define HASHSCALE1 .1031
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// store functions


ivec4 LoadVec4( in ivec2 vAddr ) {
    return ivec4( texelFetch( iChannel0, vAddr, 0 ) );
}

bool AtAddress( ivec2 p, ivec2 c ) { return all( equal( floor(vec2(p)), vec2(c) ) ); }

void StoreVec4( in ivec2 vAddr, in ivec4 vValue, inout vec4 fragColor, in ivec2 fragCoord ) {
    fragColor = AtAddress( fragCoord, vAddr ) ? vec4(vValue) : fragColor;
}

void StoreIVec4( in ivec2 vAddr, in ivec4 vValue, inout ivec4 fragColor, in ivec2 fragCoord ) {
    fragColor = AtAddress( fragCoord, vAddr ) ? ivec4(vValue) : fragColor;
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
	return texelFetch( iChannel2, ivec2(key, 0), 0 ).x > 0.0;
}

bool KT(int key) {
	return texelFetch( iChannel2, ivec2(key, 2), 0 ).x > 0.0;
}


// map functions

ivec4 createStatic(int level, ivec2 coord) {
    ivec4 data = ivec4(0);
    if( coord.x < 32 ) { // static data
        // create walls
  		int wall = 1-int(step(texelFetch(iChannel1, coord, 0).x,.575));
    	if( coord.x % 31 == 0 || coord.y % 31 == 0) wall = 1;
        data = ivec4(wall,0,0,0);

        if( wall == 0 ) {
            float hash = hash12( vec2(coord*9) );
            // swords
            if( hash > .96) {
                data = ivec4( 6, 0, 1 + 
                       int( max(0., .35*( hash12( vec2(coord.yx) ) * 32. + float(coord.x) + float(coord.y)) )), 0 );
            }
            if( hash < .05 ) {
                data = ivec4(10, 0, 8 + (coord.x+coord.y)/10, 0);
            }
        }

        
        // doors
        StoreIVec4( ivec2( 2, 9), ivec4(2,2,0,0), data, coord);
        StoreIVec4( ivec2( 8,16), ivec4(2,2,0,0), data, coord);
        StoreIVec4( ivec2( 9, 8), ivec4(2,2,0,0), data, coord);
        StoreIVec4( ivec2(24, 9), ivec4(2,2,0,0), data, coord);
        StoreIVec4( ivec2(17,15), ivec4(2,2,0,0), data, coord);
        StoreIVec4( ivec2(24,13), ivec4(2,2,0,0), data, coord);
        StoreIVec4( ivec2(14, 3), ivec4(2,2,0,0), data, coord);
        
        StoreIVec4( ivec2(10, 5), ivec4(2,1,0,0), data, coord);
        StoreIVec4( ivec2( 3,13), ivec4(2,1,0,0), data, coord);        
        
        
        StoreIVec4( ivec2( 3,21), ivec4(3,2,0,0), data, coord); // red door
        StoreIVec4( ivec2(17,18), ivec4(4,2,0,0), data, coord); // blue door
        StoreIVec4( ivec2(20,24), ivec4(5,1,0,0), data, coord);
        
        // data
        
        StoreIVec4( ivec2( 2, 2), ivec4(6,0,5,0), data, coord); // sword
        
        StoreIVec4( ivec2( 6,11), ivec4(7,0,1,0), data, coord); // red key
        StoreIVec4( ivec2( 2,26), ivec4(8,0,1,0), data, coord); // blue key
        StoreIVec4( ivec2(29,16), ivec4(9,0,1,0), data, coord); // blue key 
    }
    return data;
}

ivec4 createMonsters(int level, ivec2 coord ) {
    ivec4 data = ivec4(0);
    if (coord.x < 64 ) { // monsters
        coord -= ivec2(32,0);
        
        if( createStatic( level, coord ).x < 1 &&
			hash12( vec2(coord) ) > (1. - float(coord.x) * .005 - float(coord.y) * .005) ) {
            data.x = 1;
            data.w = 5 + (coord.x+coord.y)/2;
        }
    }
    
    return data;
}

ivec4 createMap(int level, ivec2 coord) {
    if( coord.x < 32 ) {
    	return createStatic(0, coord);
    } else {
    	return createMonsters(0, coord);
    }
}

ivec4 m(ivec2 uv) {
    return ivec4(texelFetch(iChannel0, uv + ivec2(32,0), 0));
}

ivec4 w(ivec2 uv) {
    return ivec4( texelFetch(iChannel0, uv, 0) );
}

bool isMonster(ivec4 data) {
    return data.x > 0;
}

bool monsterIsMoving(ivec4 data) {
    return abs(data.y) > 0;
}

bool isEmpty(ivec2 coord) {
    // return true;
    ivec4 wall = w(coord);
    ivec4 monster = m(coord);
    
    return !isMonster(monster) &&
        (wall.x < 1 ||  // no wall or
        (wall.x > 1 && wall.z == 1) || // open door
        wall.x > 5) // swords and keys
        && !(coord.x == USERCOORD.x && coord.y == USERCOORD.y);
}

ivec4 updateMap(int level, ivec2 coord) {
    ivec4 data = w(coord);
    if (coord.y > 32 || coord.x > 64 ) return data;
    
    
    ivec4 ud1 = LoadVec4( ivec2(0,32 ) );
    ivec4 ud2 = LoadVec4( ivec2(1,32 ) );
    USERINV = LoadVec4( ivec2(2,32 ) );
        
    USERCOORD = ud1.xy;
    USERDIR = ud1.z;
	USERACTIONCOUNT = ud1.w;
    
    USERACTIONCOORD = USERCOORD + DIRECTION[USERDIR];
	USERACTION = ud2.x;
        
    int SWORD = USERINV[0];
    
    bool tryaction = USERACTIONCOUNT == USERACTIONSTEPS &&
                  USERACTION == ACTION;
    
    if (coord.x < 32 ) { // static data
        bool action = tryaction &&
                      coord.x == USERACTIONCOORD.x && coord.y == USERACTIONCOORD.y;
        
        if( data.x == 1 ) {
            // wall
        } else if( data.x > 1 && data.x < 6 ) { // door
            if( action ) {
                // try to open door
                if( data.x == 2 || USERINV[data.x-2] > 0) {                
                	data.z = 1;
               	 	data.w == 0;
                }
            }
            if( data.z > 0 ) {
                data.w ++;
                if( data.w > DOOROPENSTEPS ) {
                    // try to close the door
                    if( isEmpty(coord) ) {
                        data.z = 0;
                        data.w = DOORMOVESTEPS;
                    }
                }
            } else {
                data.w = max(data.w-1, 0);
            }
        } else if( data.x > 5 && coord.x == USERCOORD.x && coord.y == USERCOORD.y) { // item - pick up
            data = ivec4(0);
        }
    } else { // monsters
        coord -= ivec2(32,0);
        bool action = tryaction &&
                      coord.x == USERACTIONCOORD.x && coord.y == USERACTIONCOORD.y;
        
        if( isMonster(data) ) { // monster, move if possible
            if( action ) {
                data.w -= int(hash12( vec2(iTime) ) * float(SWORD) + 1.);
                if( data.w < 0 ) {
                    data = ivec4(0);
                }
            } if( monsterIsMoving(data) ) {
                if( data.y > 1 ) {
                    ivec4 check = m(coord + DIRECTION[data.z-1]);
                    if( check.z == data.z ) {
                        data.y ++;
                        if( data.y > MOVESTEPS ) {
                            data = ivec4(0);
                        }
                    } else {
                        data.y = 0;
                        data.z = 0;
                    }
                } else {
                   data.y ++;
                }
            } else if( abs(coord.x-USERCOORD.x)+abs(coord.y-USERCOORD.y) == 1 ) {
                // attack!
            } else {
                // try to move - multiple times
                float userDistance = distance( vec2(coord), vec2(USERCOORD));
                for(int i=0; i<4; i++) {
                    int d = int(hash12(vec2(coord) + iTime + float(i)) * 4.);
                    ivec2 dir = DIRECTION[d];
                    if( isEmpty( coord + dir ) ) {
                        data.z = d + 1;
                        data.y = 1;
                        
                        if( userDistance < 5. &&
                            distance( vec2(coord+dir),vec2(USERCOORD)) < userDistance ) {
                            i=100;
                        }
                    }
                }
            }
        } else { // check if a monster moves to this spot
            for(int i=0; i<4; i++) {
                ivec4 check = m( coord - DIRECTION[i] );
                if(check.z == i + 1 && check.y > 0) {
                    data.x = check.x;
                    data.y = -MOVESTEPS;
                    data.z = check.z;
                    data.w = check.w;
                }
            }
        }
    }
    
    return data;
}

// game logic

void gameSetup( int level, inout vec4 fragColor, in ivec2 coord ) {
    StoreVec4( ivec2(0,32 ), ivec4(4,1,3,0), fragColor, coord );
    StoreVec4( ivec2(1,32 ), ivec4(0,0,60,0), fragColor, coord );
    StoreVec4( ivec2(2,32 ), ivec4(0,0,0,0), fragColor, coord );
    StoreVec4( ivec2(3,32 ), ivec4(0), fragColor, coord );
}

void gameLoop( inout vec4 fragColor, in ivec2 coord ) {
    if( coord.y > 33 || coord.y < 32 ) return;
    if( coord.x > 16 ) return;
    
    ivec4 ud1 = LoadVec4( ivec2(0,32 ) );
    ivec4 ud2 = LoadVec4( ivec2(1,32 ) );
    ivec4 ud3 = LoadVec4( ivec2(2,32 ) );
    
    USERCOORD = ud1.xy;
    USERDIR = ud1.z;
    int actionCount = ud1.w;
    
    int action = ud2.x;
    int newAction = ud2.y;
    int live = ud2.z;
    
    USERINV = ud3;
    
    if( actionCount > 0 ) {
        actionCount --;
    }
    
    if( KP(KEY_UP) || KP(KEY_W) ) {
        newAction = FORWARD;
    }
    if( KP(KEY_DOWN) || KP(KEY_S) ) {
        newAction = BACK;
    }
    if( KP(KEY_LEFT) || KP(KEY_A) ) {
        newAction = ROT_LEFT;
    }
    if( KP(KEY_RIGHT) || KP(KEY_D) ) {
        newAction = ROT_RIGHT;
    }
    if( KP(KEY_SPACE) ) {
        newAction = ACTION;
    }
    
    if( actionCount > 8 ) {
        newAction = NONE;
    }
    
    if( actionCount == 0 ) {
        action = newAction;
        newAction = NONE;
        
        if( action == FORWARD ) {
            if( isEmpty( USERCOORD + DIRECTION[USERDIR] ) ) {
                USERCOORD += DIRECTION[USERDIR];
                actionCount = USERMOVESTEPS;
            }
        }
        if( action == BACK ) {
            if( isEmpty( USERCOORD - DIRECTION[USERDIR] ) ) {
                USERCOORD -= DIRECTION[USERDIR];
                actionCount = USERMOVESTEPS;
            }
        }
        if( action == ROT_RIGHT ) {
            USERDIR = (USERDIR + 1) % 4;
            actionCount = USERROTATESTEPS;
        }
        if( action == ROT_LEFT ) {
            USERDIR = (USERDIR + 3) % 4;
            actionCount = USERROTATESTEPS;
        }
        if( action == ACTION ) {
            actionCount = USERACTIONSTEPS;
        }
    }
    
    // store data
    ud1.xy = USERCOORD;
    ud1.z = USERDIR;
    ud1.w = actionCount;
    
    ud2.x = action;
    ud2.y = newAction;
    
    ivec4 map = w(USERCOORD);
    if( map.x > 9 ) {
        live += map.z;
    	StoreVec4( ivec2(3,32 ), ivec4(map.x,map.z,0,0), fragColor, coord );
    } else if( map.x > 5 ) {
        // item
        USERINV[ map.x-6 ] = max( USERINV[ map.x-6], map.z );
    	StoreVec4( ivec2(3,32 ), ivec4(map.x,map.z,0,0), fragColor, coord );
    } else {
    	StoreVec4( ivec2(3,32 ), ivec4(0), fragColor, coord );
    }        
    
    
    if( live > 120 ) {
        live = 120;
    }
    
    for(int i=0; i<4; i++) {
        ivec2 c = USERCOORD + DIRECTION[i];
        ivec4 mo = m(c);
        if( isMonster(mo) && mo.y == 0 ) {
            if( hash12( vec2(c)+iTime ) > .993 - float(mo.w)*.0007 ) {
                live -= 2+int(hash12( vec2(c)-iTime ) * (float(mo.w) + 5.));
            }
        }
    }
    
    ud2.z = live;
    if( live < 0 ) {
        ud2.w = 1;
    	StoreVec4( ivec2(3,32 ), ivec4(-1), fragColor, coord );
    }
        
    StoreVec4( ivec2(0,32 ), ud1, fragColor, coord );
    StoreVec4( ivec2(1,32 ), ud2, fragColor, coord );
    StoreVec4( ivec2(2,32 ), USERINV, fragColor, coord );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	ivec2 uv = ivec2(fragCoord.xy);
    ivec4 ud2 = LoadVec4( ivec2(1,32 ) );
    
	int wall = 1-int(step(texelFetch(iChannel1, ivec2(2,1), 0).x,.575));
    
    if( ud2.w > 0 || wall != w(ivec2(2,1)).x ) {
    	fragColor = vec4(createMap(0, uv));
        gameSetup(0, fragColor, ivec2(fragCoord) );
    } else {
        fragColor = vec4(updateMap(0, uv));
        gameLoop( fragColor, ivec2(fragCoord) );
    }    
}