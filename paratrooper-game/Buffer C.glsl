// Paratrooper. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XsyfD3
//
// I made this shader because I wanted to try  to create a simple 
// but complete game in Shadertoy.
//
// Buffer C: Encoding and decoding of bitmaps used.
//
//
// Knarkowicz created a lot of nice shaders that uses encoded bitmaps. 
// See for example: 
//
// https://www.shadertoy.com/view/Xs2fWD [SH17B] Pixel Shader Dungeon	
// https://www.shadertoy.com/view/XtlSD7 [SIG15] Mario World 1-1
// https://www.shadertoy.com/view/ll2BWz Sprite Rendering 
//

//unpack sprites
vec3 unpackCol(uint x, uint d) {
	uint v = (d >> ((x & 0xfU) << 1)) & 0x3U;
    
    return v == 0x0U ? vec3(0) : 
    	   v == 0x2U ? COL_CYAN : 
    	   v == 0x3U ? COL_MAGENTA : COL_WHITE;
}

vec3 unpackBW(uint x, uint d) {
    return vec3((d >> (x & 0x1fU)) & 0x1U);
}

bool resolutionChanged() {
    return floor(texelFetch(iChannel0, ivec2(iResolution.xy-1.), 0).r) != floor(iResolution.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec3 col = vec3(iResolution.xy,0);
    
    if (resolutionChanged()) {
        ivec2 c = ivec2(fragCoord);   	    
        uint d = 0x0U;
        const int ycol = 73;

        if(c.y < ycol) {
            d = (c.y==0) ? c.x < 16 ? 0x1555555U : c.x < 32 ? 0x5540000U : c.x < 48 ? 0x55550000U : c.x < 64 ? 0x55000155U : c.x < 80 ? 0x155555U : c.x < 96 ? 0x55400U : c.x < 112 ? 0x55555500U : c.x < 128 ? 0x15U : d : d;
			d = (c.y==1) ? c.x < 16 ? 0x6aaaaa5U : c.x < 32 ? 0x1a990000U : c.x < 48 ? 0xaaa50000U : c.x < 64 ? 0xa50006aaU : c.x < 80 ? 0x6aaaaaU : c.x < 96 ? 0x1a9900U : c.x < 112 ? 0xaaaaa500U : c.x < 128 ? 0x6aU : d : d;
            d = (c.y==2) ? c.x < 16 ? 0x1aaaaa99U : c.x < 32 ? 0x6a6a4000U : c.x < 48 ? 0xaa990000U : c.x < 64 ? 0x99001aaaU : c.x < 80 ? 0x1aaaaaaU : c.x < 96 ? 0x6a6a40U : c.x < 112 ? 0xaaaa9900U : c.x < 128 ? 0x1aaU : d : d;
            d = (c.y==3) ? c.x < 16 ? 0xffffffe9U : c.x < 32 ? 0xffaa9000U : c.x < 48 ? 0xffe90003U : c.x < 64 ? 0xe400ffffU : c.x < 80 ? 0xfffffffU : c.x < 96 ? 0x3ffaa90U : c.x < 112 ? 0xffffe900U : c.x < 128 ? 0xfffU : d : d;
            d = (c.y==4) ? c.x < 16 ? 0xffffffe9U : c.x < 32 ? 0xffeaa403U : c.x < 48 ? 0xffe9000fU : c.x < 64 ? 0xd003ffffU : c.x < 80 ? 0xfffffffU : c.x < 96 ? 0xfffeaa4U : c.x < 112 ? 0xffffe900U : c.x < 128 ? 0xfffU : d : d;
            d = (c.y==5) ? c.x < 16 ? 0xffffffe9U : c.x < 32 ? 0xfffaa90fU : c.x < 48 ? 0xffe9003fU : c.x < 64 ? 0xc00fffffU : c.x < 80 ? 0xfffffffU : c.x < 96 ? 0x3ffffaa9U : c.x < 112 ? 0xffffe900U : c.x < 128 ? 0xfffU : d : d;
            d = (c.y==6) ? c.x < 16 ? 0xe9000fe9U : c.x < 32 ? 0x3fea50fU : c.x < 48 ? 0xfe900ffU : c.x < 64 ? 0xfe900U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xff03fea5U : c.x < 112 ? 0xfe900U : c.x < 128 ? 0x0U : d : d;
            d = (c.y==7) ? c.x < 16 ? 0xe9000fe9U : c.x < 32 ? 0xff990fU : c.x < 48 ? 0xfe903fdU : c.x < 64 ? 0xfe900U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xfd00ff99U : c.x < 112 ? 0xfe903U : c.x < 128 ? 0x0U : d : d;
            d = (c.y==8) ? c.x < 16 ? 0xe9000fe9U : c.x < 32 ? 0x3fe90fU : c.x < 48 ? 0xfe90ff9U : c.x < 64 ? 0xfe900U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xf9003fe9U : c.x < 112 ? 0xfe90fU : c.x < 128 ? 0x0U : d : d;
            d = (c.y==9) ? c.x < 16 ? 0xe9555fe9U : c.x < 32 ? 0x555fe90fU : c.x < 48 ? 0x5fe90fe9U : c.x < 64 ? 0xfe955U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe9000fe9U : c.x < 112 ? 0x555fe90fU : c.x < 128 ? 0x0U : d : d;
            d = (c.y==10) ? c.x < 16 ? 0xe6aaafe9U : c.x < 32 ? 0xaaafe90fU : c.x < 48 ? 0xafe90fe6U : c.x < 64 ? 0xfe6aaU : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe9000fe9U : c.x < 112 ? 0xaaafe90fU : c.x < 128 ? 0x1U : d : d;
            d = (c.y==11) ? c.x < 16 ? 0xdaaaafe9U : c.x < 32 ? 0xaaafe90fU : c.x < 48 ? 0xafe90fdaU : c.x < 64 ? 0xfdaaaU : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe9000fe9U : c.x < 112 ? 0xaaafe90fU : c.x < 128 ? 0x6U : d : d;
            d = (c.y==12) ? c.x < 16 ? 0xffffffe9U : c.x < 32 ? 0xffffe90fU : c.x < 48 ? 0xffe90fffU : c.x < 64 ? 0xfffffU : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe9000fe9U : c.x < 112 ? 0xffffe90fU : c.x < 128 ? 0x3fU : d : d;
            d = (c.y==13) ? c.x < 16 ? 0xffffffe9U : c.x < 32 ? 0xffffe903U : c.x < 48 ? 0xffe90fffU : c.x < 64 ? 0x3ffffU : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe9000fe9U : c.x < 112 ? 0xffffe90fU : c.x < 128 ? 0x3fU : d : d;
            d = (c.y==14) ? c.x < 16 ? 0xffffffe9U : c.x < 32 ? 0xffffe900U : c.x < 48 ? 0xffe90fffU : c.x < 64 ? 0xffffU : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe9000fe9U : c.x < 112 ? 0xffffe90fU : c.x < 128 ? 0x3fU : d : d;
            d = (c.y==15) ? c.x < 16 ? 0xfe9U : c.x < 32 ? 0xfe900U : c.x < 48 ? 0xfe90fe9U : c.x < 64 ? 0x3fcU : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe9000fe9U : c.x < 112 ? 0xfe90fU : c.x < 128 ? 0x0U : d : d;
            d = (c.y==16) ? c.x < 16 ? 0xfe9U : c.x < 32 ? 0xfe900U : c.x < 48 ? 0xfe90fe9U : c.x < 64 ? 0xff0U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xe6400fe4U : c.x < 112 ? 0xfe90fU : c.x < 128 ? 0x0U : d : d;
            d = (c.y==17) ? c.x < 16 ? 0xfe9U : c.x < 32 ? 0xfe900U : c.x < 48 ? 0xfe90fe9U : c.x < 64 ? 0x3fc0U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xda900fd0U : c.x < 112 ? 0xfe90fU : c.x < 128 ? 0x0U : d : d;
            d = (c.y==18) ? c.x < 16 ? 0xfe9U : c.x < 32 ? 0xfe900U : c.x < 48 ? 0xfe90fe9U : c.x < 64 ? 0xff00U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xfaa57fc0U : c.x < 112 ? 0x555fe90fU : c.x < 128 ? 0x15U : d : d;
            d = (c.y==19) ? c.x < 16 ? 0xfe9U : c.x < 32 ? 0xfe900U : c.x < 48 ? 0xfe90fe9U : c.x < 64 ? 0x3fd00U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xfe9aff00U : c.x < 112 ? 0xaaafe903U : c.x < 128 ? 0x6aU : d : d;
            d = (c.y==20) ? c.x < 16 ? 0xfe9U : c.x < 32 ? 0xfe900U : c.x < 48 ? 0xfe90fe9U : c.x < 64 ? 0xff900U : c.x < 80 ? 0xfe90U : c.x < 96 ? 0xff6bfc00U : c.x < 112 ? 0xaaafe900U : c.x < 128 ? 0x1aaU : d : d;
            d = (c.y==21) ? c.x < 16 ? 0xfe4U : c.x < 32 ? 0xfe400U : c.x < 48 ? 0xfe40fe4U : c.x < 64 ? 0xfe400U : c.x < 80 ? 0xfe40U : c.x < 96 ? 0x3ffff000U : c.x < 112 ? 0xffffe400U : c.x < 128 ? 0xfffU : d : d;
            d = (c.y==22) ? c.x < 16 ? 0xfd0U : c.x < 32 ? 0xfd000U : c.x < 48 ? 0xfd00fd0U : c.x < 64 ? 0xfd000U : c.x < 80 ? 0xfd00U : c.x < 96 ? 0xfffc000U : c.x < 112 ? 0xffffd000U : c.x < 128 ? 0xfffU : d : d;
            d = (c.y==23) ? c.x < 16 ? 0xfc0U : c.x < 32 ? 0xfc000U : c.x < 48 ? 0xfc00fc0U : c.x < 64 ? 0xfc000U : c.x < 80 ? 0xfc00U : c.x < 96 ? 0x3ff0000U : c.x < 112 ? 0xffffc000U : c.x < 128 ? 0xfffU : d : d;
            c.y -= 24;	

            d = (c.y==0) ? c.x < 16 ? 0xfff00000U : c.x < 32 ? 0xfffU : c.x < 48 ? 0xffffffffU : c.x < 64 ? 0xfff00000U : c.x < 80 ? 0xfffU : c.x < 96 ? 0x3c000U : d : d;
            d = (c.y==1) ? c.x < 16 ? 0x40000000U : c.x < 32 ? 0x1U : c.x < 48 ? 0x14000U : c.x < 64 ? 0x40000000U : c.x < 80 ? 0x1U : c.x < 96 ? 0x14000U : d : d;
            d = (c.y==2) ? c.x < 16 ? 0x55000000U : c.x < 32 ? 0x30055U : c.x < 48 ? 0x555500U : c.x < 64 ? 0x5500000cU : c.x < 80 ? 0x300055U : c.x < 96 ? 0x555500U : d : d;
            d = (c.y==3) ? c.x < 16 ? 0x55557fU : c.x < 32 ? 0x555c0155U : c.x < 48 ? 0x1550055U : c.x < 64 ? 0x55555cU : c.x < 80 ? 0x555c0155U : c.x < 96 ? 0x1550055U : d : d;
            d = (c.y==4) ? c.x < 16 ? 0x55400U : c.x < 32 ? 0x54300554U : c.x < 48 ? 0x5540005U : c.x < 64 ? 0x5540cU : c.x < 80 ? 0x54030554U : c.x < 96 ? 0x5540005U : d : d;
            d = (c.y==5) ? c.x < 16 ? 0x100000U : c.x < 32 ? 0x400U : c.x < 48 ? 0x4000010U : c.x < 64 ? 0x100000U : c.x < 80 ? 0x400U : c.x < 96 ? 0x4000010U : d : d;
            d = (c.y==6) ? c.x < 16 ? 0x400000U : c.x < 32 ? 0x100U : c.x < 48 ? 0x1000040U : c.x < 64 ? 0x400000U : c.x < 80 ? 0x100U : c.x < 96 ? 0x1000040U : d : d;
            d = (c.y==7) ? c.x < 16 ? 0x55000000U : c.x < 32 ? 0x55U : c.x < 48 ? 0x555500U : c.x < 64 ? 0x55000000U : c.x < 80 ? 0x55U : c.x < 96 ? 0x555500U : d : d;
            d = (c.y==8) ? c.x < 16 ? 0x8000000U : c.x < 32 ? 0x8020U : c.x < 48 ? 0x80200800U : c.x < 64 ? 0x8000000U : c.x < 80 ? 0x8020U : c.x < 96 ? 0x80200800U : d : d;
            d = (c.y==9) ? c.x < 16 ? 0xaaaa0000U : c.x < 32 ? 0x2aaaU : c.x < 48 ? 0x2aaaaaaaU : c.x < 64 ? 0xaaaa0000U : c.x < 80 ? 0x2aaaU : c.x < 96 ? 0x2aaaaaaaU : d : d;
            c.y -= 10;

            d = (c.y==0) ? c.x < 16 ? 0xaa00U : d : d;
            d = (c.y==1) ? c.x < 16 ? 0xaaaa0U : d : d;
            d = (c.y==2) ? c.x < 16 ? 0x2aaaa8U : d : d;
            d = (c.y==3) ? c.x < 16 ? 0xaaaaaaU : d : d;
            d = (c.y==4) ? c.x < 16 ? 0xaaaaaaU : d : d;
            d = (c.y==5) ? c.x < 16 ? 0x14aaaaaaU : d : d;
            d = (c.y==6) ? c.x < 16 ? 0x14c00003U : d : d;
            d = (c.y==7) ? c.x < 16 ? 0xaa30000cU : d : d;
            d = (c.y==8) ? c.x < 16 ? 0x2830000cU : d : d;
            d = (c.y==9) ? c.x < 16 ? 0x280c0030U : d : d;
            d = (c.y==10) ? c.x < 16 ? 0x820c0030U : d : d;
            d = (c.y==11) ? c.x < 16 ? 0x820300c0U : d : d;
            d = (c.y==12) ? c.x < 16 ? 0x820300c0U : d : d;
            d = (c.y==13) ? c.x < 16 ? 0x8200c300U : d : d;
            c.y -= 14;

            d = (c.y==0) ? c.x < 16 ? 0x5500U : d : d;
            d = (c.y==1) ? c.x < 16 ? 0x15540U : d : d;
            d = (c.y==2) ? c.x < 16 ? 0x55550U : d : d;
            d = (c.y==3) ? c.x < 16 ? 0x7d7d0U : d : d;
            d = (c.y==4) ? c.x < 16 ? 0x55550U : d : d;
            d = (c.y==5) ? c.x < 16 ? 0x115544U : d : d;
            d = (c.y==6) ? c.x < 16 ? 0x505505U : d : d;
            d = (c.y==7) ? c.x < 16 ? 0x46910U : d : d;
            d = (c.y==8) ? c.x < 16 ? 0x11440U : d : d;
            d = (c.y==9) ? c.x < 16 ? 0x4100U : d : d;
            d = (c.y==10) ? c.x < 16 ? 0x1400U : d : d;
            d = (c.y==11) ? c.x < 16 ? 0x1400U : d : d;
            d = (c.y==12) ? c.x < 16 ? 0x4100U : d : d;
            d = (c.y==13) ? c.x < 16 ? 0x50050U : d : d;
            d = (c.y==14) ? c.x < 16 ? 0x10040U : d : d;
            c.y -= 15;

            d = (c.y==0) ? c.x < 16 ? 0x2aU : c.x < 32 ? 0x2a0000U : c.x < 48 ? 0x0U : d : d;
            d = (c.y==1) ? c.x < 16 ? 0x82U : c.x < 32 ? 0x820000U : c.x < 48 ? 0x0U : d : d;
            d = (c.y==2) ? c.x < 16 ? 0x202U : c.x < 32 ? 0x2020000U : c.x < 48 ? 0x0U : d : d;
            d = (c.y==3) ? c.x < 16 ? 0x808U : c.x < 32 ? 0x8080000U : c.x < 48 ? 0x0U : d : d;
            d = (c.y==4) ? c.x < 16 ? 0xaaaaa008U : c.x < 32 ? 0xa0080156U : c.x < 48 ? 0x156aaaaU : d : d;
            d = (c.y==5) ? c.x < 16 ? 0x20U : c.x < 32 ? 0x200558U : c.x < 48 ? 0x5580000U : d : d;
            d = (c.y==6) ? c.x < 16 ? 0x20U : c.x < 32 ? 0x201560U : c.x < 48 ? 0x15600000U : d : d;
            d = (c.y==7) ? c.x < 16 ? 0xffff008cU : c.x < 32 ? 0xb0aa80U : c.x < 48 ? 0xaa80ffffU : d : d;
            d = (c.y==8) ? c.x < 16 ? 0x80U : c.x < 32 ? 0x832000U : c.x < 48 ? 0x20000000U : d : d;
            d = (c.y==9) ? c.x < 16 ? 0xaaaaaa33U : c.x < 32 ? 0xaa300aaaU : c.x < 48 ? 0xaaaaaaaU : d : d;
            col = unpackCol(uint(c.x), d);
        } else {
            c.y -= ycol;
            if(c.y==0) d =c.x < 32 ? 0x1e001e33U : c.x < 64 ? 0x7f3f1c3cU : c.x < 96 ? 0x3c183e00U : c.x < 128 ? 0x387e383cU : c.x < 160 ? 0x3c3e3fU : d;
            if(c.y==1) d =c.x < 32 ? 0x33000c33U : c.x < 64 ? 0x46663666U : c.x < 96 ? 0x661c631cU : c.x < 128 ? 0xc063c66U : c.x < 160 ? 0x666333U : d;
            if(c.y==2) d =c.x < 32 ? 0x7000c33U : c.x < 64 ? 0x16666303U : c.x < 96 ? 0x6018731cU : c.x < 128 ? 0x63e3660U : c.x < 160 ? 0x666330U : d;
            if(c.y==3) d =c.x < 32 ? 0xe3f0c3fU : c.x < 64 ? 0x1e3e6303U : c.x < 96 ? 0x38187b00U : c.x < 128 ? 0x3e603338U : c.x < 160 ? 0x7c3e18U : d;
            if(c.y==4) d =c.x < 32 ? 0x38000c33U : c.x < 64 ? 0x16366303U : c.x < 96 ? 0xc186f00U : c.x < 128 ? 0x66607f60U : c.x < 160 ? 0x60630cU : d;
            if(c.y==5) d =c.x < 32 ? 0x33000c33U : c.x < 64 ? 0x46663666U : c.x < 96 ? 0x6618671cU : c.x < 128 ? 0x66663066U : c.x < 160 ? 0x30630cU : d;
            if(c.y==6) d =c.x < 32 ? 0x1e001e33U : c.x < 64 ? 0x7f671c3cU : c.x < 96 ? 0x7e7e3e1cU : c.x < 128 ? 0x3c3c783cU : c.x < 160 ? 0x1c3e0cU : d;
            c.y -= 7;

            if(c.y==0) d =c.x < 32 ? 0x3c7f3f3fU : c.x < 64 ? 0x3cU : c.x < 96 ? 0x0U : c.x < 128 ? 0x7U : c.x < 160 ? 0x3f3e7fU : c.x < 192 ? 0x3f667f67U : c.x < 224 ? 0x1f3f1c3eU : c.x < 256 ? 0x1c0f3f00U : c.x < 288 ? 0x66U : d;
            if(c.y==1) d =c.x < 32 ? 0x66466666U : c.x < 64 ? 0x66U : c.x < 96 ? 0x0U : c.x < 128 ? 0x6U : c.x < 160 ? 0x666346U : c.x < 192 ? 0x66664666U : c.x < 224 ? 0x36663663U : c.x < 256 ? 0x36066600U : c.x < 288 ? 0x66U : d;
            if(c.y==2) d =c.x < 32 ? 0xc166666U : c.x < 64 ? 0x3b7e000cU : c.x < 96 ? 0x3e3e1eU : c.x < 128 ? 0x3b1e3eU : c.x < 160 ? 0x666316U : c.x < 192 ? 0x66661636U : c.x < 224 ? 0x66666363U : c.x < 256 ? 0x63066600U : c.x < 288 ? 0x66U : d;
            if(c.y==3) d =c.x < 32 ? 0x181e3e3eU : c.x < 64 ? 0x66030018U : c.x < 96 ? 0x636330U : c.x < 128 ? 0x6e3066U : c.x < 160 ? 0x3e631eU : c.x < 192 ? 0x3e3c1e1eU : c.x < 224 ? 0x663e7f63U : c.x < 256 ? 0x7f063e00U : c.x < 288 ? 0x3cU : d;
            if(c.y==4) d =c.x < 32 ? 0x30163606U : c.x < 64 ? 0x3e3e0030U : c.x < 96 ? 0x7f033eU : c.x < 128 ? 0x63e66U : c.x < 160 ? 0x366316U : c.x < 192 ? 0x66181636U : c.x < 224 ? 0x66366363U : c.x < 256 ? 0x63460600U : c.x < 288 ? 0x18U : d;
            if(c.y==5) d =c.x < 32 ? 0x66466606U : c.x < 64 ? 0x6600066U : c.x < 96 ? 0x36333U : c.x < 128 ? 0x63366U : c.x < 160 ? 0x666306U : c.x < 192 ? 0x66184666U : c.x < 224 ? 0x36666363U : c.x < 256 ? 0x63660600U : c.x < 288 ? 0x18U : d;
            if(c.y==6) d =c.x < 32 ? 0x3c7f670fU : c.x < 64 ? 0xf3f003cU : c.x < 96 ? 0x3e3e6eU : c.x < 128 ? 0xf6e3bU : c.x < 160 ? 0x673e0fU : c.x < 192 ? 0x3f3c7f67U : c.x < 224 ? 0x1f67633eU : c.x < 256 ? 0x637f0f00U : c.x < 288 ? 0x3cU : d;
            col = unpackBW(uint(c.x), d);
        }
    }
    
    fragColor = vec4(col,1.0);
}