// Legend of the Gelatinous Cube. Created by Reinder Nijhoff 2017
// @reindernijhoff
// 
// https://www.shadertoy.com/view/Xs2Bzy
//
// I created this shader in one long night for the Shadertoy Competition 2017
// 

// UI CODE

const int USERACTIONSTEPS = 30;
const int MAXSWORD = 30;
const int REDFLASHSTEPS = 60;

const int NONE = 0;
const int FORWARD = 1;
const int BACK = 2;
const int ROT_LEFT = 3;
const int ROT_RIGHT = 4;
const int ACTION = 5;

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

void StoreIVec4B( in ivec2 vAddr, in ivec4 vValue, inout vec4 fragColor, in ivec2 fragCoord ) {
    fragColor = AtAddress( fragCoord, vAddr ) ? vec4(vValue) : fragColor;
}

ivec4 LoadVec4B( in ivec2 vAddr ) {
    return ivec4( texelFetch( iChannel2, vAddr, 0 ) );
}


// FONT RENDER CODE
//
// copied from https://www.shadertoy.com/view/MtyXDV

vec2 uv = vec2(0.0);  // -1 .. 1

//== font handling ================================================

#define FONT_SPACE 0.5

vec2 tp = vec2(0.0);  // text position
const vec2 vFontSize = vec2(8.0, 15.0);  // multiples of 4x5 work best

//----- access to the image of ascii code characters ------

#define SPACE tp.x-=FONT_SPACE;
#define _     tp.x-=FONT_SPACE;

#define S(a) c+=char(a);  tp.x-=FONT_SPACE;

#define _note  S(10);   //
#define _star  S(28);   // *
#define _smily S(29);   // :-)        
#define _exc   S(33);   // !
#define _add   S(43);   // +
#define _comma S(44);   // ,
#define _sub   S(45);   // -
#define _dot   S(46);   // .
#define _slash S(47);   // /

#define _0 S(48);
#define _1 S(49);
#define _2 S(50);
#define _3 S(51);
#define _4 S(52);
#define _5 S(53);
#define _6 S(54);
#define _7 S(55);
#define _8 S(56);
#define _9 S(57);
#define _ddot S(58);   // :
#define _sc   S(59);   // ;
#define _less S(60);   // <
#define _eq   S(61);   // =
#define _gr   S(62);   // >
#define _qm   S(63);   // ?
#define _at   S(64);   // at sign

#define _A S(65);
#define _B S(66);
#define _C S(67);
#define _D S(68);
#define _E S(69);
#define _F S(70);
#define _G S(71);
#define _H S(72);
#define _I S(73);
#define _J S(74);
#define _K S(75);
#define _L S(76);
#define _M S(77);
#define _N S(78);
#define _O S(79);
#define _P S(80);
#define _Q S(81);
#define _R S(82);
#define _S S(83);
#define _T S(84);
#define _U S(85);
#define _V S(86);
#define _W S(87);
#define _X S(88);
#define _Y S(89);
#define _Z S(90);

#define _a S(97);
#define _b S(98);
#define _c S(99);
#define _d S(100);
#define _e S(101);
#define _f S(102);
#define _g S(103);
#define _h S(104);
#define _i S(105);
#define _j S(106);
#define _k S(107);
#define _l S(108);
#define _m S(109);
#define _n S(110);
#define _o S(111);
#define _p S(112);
#define _q S(113);
#define _r S(114);
#define _s S(115);
#define _t S(116);
#define _u S(117);
#define _v S(118);
#define _w S(119);
#define _x S(120);
#define _y S(121);
#define _z S(122);
   
float char(int ch) {
  vec4 f = any(lessThan(vec4(tp,1,1), vec4(0,0,tp))) 
               ? vec4(0) 
               : texture(iChannel3,0.0625*(tp + vec2(ch - ch/16*16,15 - ch/16)));  
  return f.x;
}

void SetTextPosition(float x, float y)  //
{
  tp = 10.0*uv;
  tp.x = tp.x - x;
  tp.y = tp.y - y;
}
                                                                                                        
float drawInt(int value, int minDigits)
{
  float c = 0.;
  if (value < 0) 
  { value = -value;
    if (minDigits < 1) minDigits = 1;
    else minDigits--;
    _sub                   // add minus char
  } 
  int fn = value, digits = 1; // get number of digits 
  for (int ni=0; ni<10; ni++)
  {
    fn /= 10;
    if (fn == 0) break;
    digits++;
  } 
  digits = max(minDigits, digits);
  tp.x -= FONT_SPACE * float(digits);
  for (int ni=1; ni < 11; ni++) 
  { 
    tp.x += FONT_SPACE; // space
    c += char(48 + (value-((value/=10)*10))); // add 0..9 
    if (ni >= digits) break;
  } 
  tp.x -= FONT_SPACE * float(digits);
  return c;
}

float drawInt(int value) {return drawInt(value,1);}


void updateText(  inout vec4 color, vec2 coord ) {
    uv = (2.*coord/iResolution.y-1.);
    if( abs(uv.y) < .2 ) {
        ivec4 data = LoadVec4(ivec2(3,32));
        
        if( data.x > 0 ) {
		   SetTextPosition(2.5,-0.5);   
		   float c = 0.0;
		   _Y _o _u _ _f _o _u _n _d _ 
                
           if( data.x == 6 ) {    
              _a _ _n _e _w _ _s _w _o _r _d _ _add
			    c += drawInt(data.y);  
           } else if( data.x == 10 ) {
                _f _o _o _d _ _add
			    c += drawInt(data.y);  
           } else {
               _a _
               if( data.x == 7 ) {
                   _R _e _d
               }
               else if( data.x == 8 ) {
                   _G _r _e _e _n
               }
               else if( data.x == 9 ) {
                   _B _l _u _e
               }
               _ _K _e _y
           }
		   color = vec4(1,1,1,min(2.,c * 2.));
        } else if( data.x < 0 ) {   
		   SetTextPosition(2.5,-0.5);
		   float c = 0.0;
           _Y _o _u _ _d _i _e _d
		   color = vec4(1,1,1,min(2.,c * 2.));               
        } else {
           color = texelFetch(iChannel2, ivec2(coord),0); 
           color.a = max(0., color.a - 1./60.);
        }         
    }
}


// UI ELEMENTS

vec4 drawSword( vec2 uv, int level ) {
    uv = floor(fract(uv)*32.) - 16.;
        float l = step(abs(uv.y), .5); 
        l = max(l, step(abs(uv.y), 1.5) * step(uv.x, 13.));   
        l = max(l, step(abs(uv.y), 5.5) * step(abs(uv.x+9.), 1.));
                        
	    vec3 col = mix( vec3(.8), vec3(.5,.3,.2), step(uv.x, -11.));
        vec3 scol = mix( vec3(.5,.3,.2), vec3(1.), clamp(float(level) / float(MAXSWORD/2), 0., 1.) );
        scol = mix( scol, vec3(0.,.9, 1.), clamp(float(level-MAXSWORD/2) / float(MAXSWORD/2), 0., 1.) );
        col = mix( scol, col, step(uv.x, -8.));        
        
        return vec4( l * (.75 + .25 * texture(iChannel1, uv/64.).x) * col, l );
}

vec4 drawKey( vec2 uv, int color ) {
    uv = floor(fract(uv)*32.) - 16.;
        float l = step(abs(uv.y), 1.);
        l = max(l, step(length(uv+vec2(8,0)), 7.5));
        l -= step(length(uv+vec2(8,0)), 4.5);
        l = max(l, step(6.,uv.x)*step(uv.x, 7.)*step(0.,uv.y)*step(abs(uv.y), 5.));
        l = max(l, step(10.,uv.x)*step(uv.x, 11.)*step(0.,uv.y)*step(abs(uv.y), 7.));
        l = max(l, step(14.,uv.x)*step(0.,uv.y)*step(abs(uv.y), 6.));
        
	    vec3 col = vec3(0);
    	col[color] = 1.;
        return vec4( l * (.75 + .25 * texture(iChannel1, uv/64.).x) * col, l );

}

void drawKeyIcon( vec2 lt, vec2 size, inout vec4 color, vec2 coord, int keyColor ) {
    coord = (coord-lt) / size;
    if( coord.x >= 0. && coord.x <= 1. && coord.y >= 0. && coord.y <= 1. ) {    
		vec4 col = drawKey(-coord, keyColor);
        color = mix( color, col, col.a );
    }
}


void drawSwordIcon( vec2 lt, vec2 size, inout vec4 color, vec2 coord, int level ) {
    coord = (coord-lt) / size;
    if( coord.x >= 0. && coord.x <= 1. && coord.y >= 0. && coord.y <= 1. ) {    
		vec4 col = drawSword(coord, level);
        color = mix( color, col, col.a );
    }
}


void drawSwordIconLarge( vec2 lt, vec2 size, inout vec4 color, vec2 coord, int level ) {
    coord = (coord-lt) / size;
    if( coord.x >= 0. && coord.x <= 1. && coord.y >= 0. && coord.y <= 1. ) {    
		vec4 col = drawSword(coord.yx, level);
        color = mix( color, col, col.a );
    }
}

void drawLifeBar(  vec2 lt, vec2 size, inout vec4 color, vec2 coord, int level ) {
     coord = (coord-lt) / size;
    if( coord.x >= 0. && coord.x <= 1. && coord.y >= 0. && coord.y <= 1. ) {    
		vec4 col = mix(vec4(.5,0,0,1), vec4(.5,1,0,1), float(level)/60.);  
		col = mix(col, vec4(0,1,0,1), float(level-60)/60.);
        col = mix( vec4(0,0,0,.6), col, step( 120. * coord.x,  float(level) ));
        col.rgb *= (.75 + .5 * texture(iChannel1, coord/vec2(8.,64.)).x);
        color = mix( color, col, col.a );
    }   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 res = iResolution.xy;
    
    ivec4 ud1 = LoadVec4( ivec2(0,32 ) );
    ivec4 ud2 = LoadVec4( ivec2(1,32 ) );
    ivec4 USERINV = LoadVec4( ivec2(2,32 ) );
        
	int USERACTIONCOUNT = ud1.w;
    int USERACTION = ud2.x;
    
    fragColor = vec4(0);

    float iconSize = res.y*.1;
    
    if( USERINV[0] > 0) {
       drawSwordIcon( vec2( res.x - iconSize*1.5, .125*iconSize ), vec2(iconSize), fragColor, fragCoord, USERINV[0] );
    }
    
    for( int i=0; i<3; i++) {
        if( USERINV[i+1] > 0 ) {
            drawKeyIcon( vec2( res.x - (float(i)*1.2+2.7)*iconSize, .125*iconSize  ), vec2(iconSize), fragColor, fragCoord, i);
        }
    }
    if( USERACTION == ACTION && USERACTIONCOUNT > 0 && USERINV[0] > 0) {
       float h = smoothstep(0., 1., abs(float(USERACTIONCOUNT-USERACTIONSTEPS/2-10)/float(USERACTIONSTEPS/2))) + .4;
       float size = res.y * .5; 
        
       drawSwordIconLarge( vec2( res.x * .5 - size*.5, -h*size ), vec2(size), fragColor, fragCoord, USERINV[0] );
    }
    drawLifeBar( vec2(iconSize * .5, .375*iconSize), vec2( iconSize*6., iconSize*.25), fragColor, fragCoord, ud2.z );
    
    updateText( fragColor, fragCoord );
    
    
    ivec4 bd = LoadVec4B( ivec2(0,0) );
    if( bd.x > ud2.z ) {
        bd.y = REDFLASHSTEPS;
    }
    bd.y--;
    if( bd.y < 0 ) bd.y = 0;
    bd.x = ud2.z;
    
    StoreIVec4B( ivec2(0,0), bd, fragColor, ivec2(fragCoord) );
}