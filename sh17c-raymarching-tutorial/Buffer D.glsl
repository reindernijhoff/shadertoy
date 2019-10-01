// [SH17C] Raymarching tutorial. Created by Reinder Nijhoff 2017
// @reindernijhoff
// 
// https://www.shadertoy.com/view/4dSfRc
//
// In this tutorial you will learn how to render a 3d-scene in Shadertoy
// using distance fields.
//
// The tutorial itself is created in Shadertoy, and is rendered
// using ray marching a distance field.
//
// The shader studied in the tutorial can be found here: 
//     https://www.shadertoy.com/view/4dSBz3
//
// Created for the Shadertoy Competition 2017 
//
// Most of the render code is taken from: 'Raymarching - Primitives' by Inigo Quilez.
//
// You can find this shader here:
//     https://www.shadertoy.com/view/Xds3zN
//

// FONT RENDERING

#define FONT_UV_WIDTH 160.

ivec4 LoadVec4( in ivec2 vAddr ) {
    return ivec4( texelFetch( iChannel0, vAddr, 0 ) );
}

void drawStr(const uint str, const ivec2 c, const vec2 uv, const vec2 caret, const float size, const vec3 fontCol, inout vec4 outCol) {    
    if( !(str == 0x0U || c.y < 0 || c.x < 0) ) {
        int x = c.x % 4;
        uint xy = (str >> ((3 - x) * 8)) % 256U;

        if( xy > 0x0aU ) {
            vec2 K = fract((uv - caret) / vec2(size * .45, size));
            K.x = K.x * .6 + .2;
            K.y = K.y * .95 - .05;
            float d = textureLod(iChannel2, (K + vec2( xy & 0xFU, 0xFU - (xy >> 4))) / 16.,0.).a;

            outCol.rgb = mix( fontCol, vec3(0) , smoothstep(.0,1.,smoothstep(.47,.53,d)) * .9 );
            outCol.a = smoothstep(1.,0., smoothstep(.53,.59,d));
        } 
    }
}

void mainImage( out vec4 outCol, in vec2 fragCoord ) {
    ivec4 slideData = LoadVec4( ivec2(0,0) );
    ivec4 text1 = LoadVec4(ivec2(0,1));
    ivec4 text2 = LoadVec4(ivec2(0,2));

    if( text1.x == 1 ) {
        outCol = vec4(0);
    } else {
        outCol = texelFetch(iChannel1, ivec2(fragCoord), 0);    
    }

    vec2 uv = ((fragCoord-iResolution.xy*.5)/iResolution.y) * FONT_UV_WIDTH;

    if(text2.x > 0) { // title
        int i = text2.x;
		uint f = 0x0U;
		if( i == 1 ) {
			ivec2 c = ivec2( (uv - vec2(-79, 60)) * (1./vec2(5.85, -13)) + vec2(1,2)) - 1;
			if(c.y == 0) f = c.x < 4 ? 0x5261796dU : c.x < 8 ? 0x61726368U : c.x < 12 ? 0x696e6720U : c.x < 16 ? 0x64697374U : c.x < 20 ? 0x616e6365U : c.x < 24 ? 0x20666965U : c.x < 28 ? 0x6c647320U : f;
			drawStr( f, c, uv, vec2(-79, 60), 13., vec3(255./255., 208./255., 128./255.), outCol );		}
		else if( i == 2 ) {
			ivec2 c = ivec2( (uv - vec2(-35.1, 60)) * (1./vec2(5.85, -13)) + vec2(1,2)) - 1;
			if(c.y == 0) f = c.x < 4 ? 0x43726561U : c.x < 8 ? 0x74652061U : c.x < 12 ? 0x20726179U : f;
			drawStr( f, c, uv, vec2(-35.1, 60), 13., vec3(255./255., 208./255., 128./255.), outCol );		}
		else if( i == 3 ) {
			ivec2 c = ivec2( (uv - vec2(-43.9, 60)) * (1./vec2(5.85, -13)) + vec2(1,2)) - 1;
			if(c.y == 0) f = c.x < 4 ? 0x44697374U : c.x < 8 ? 0x616e6365U : c.x < 12 ? 0x20666965U : c.x < 16 ? 0x6c647320U : f;
			drawStr( f, c, uv, vec2(-43.9, 60), 13., vec3(255./255., 208./255., 128./255.), outCol );		}
		else if( i == 4 ) {
			ivec2 c = ivec2( (uv - vec2(-23.4, 60)) * (1./vec2(5.85, -13)) + vec2(1,2)) - 1;
			if(c.y == 0) f = c.x < 4 ? 0x4c696768U : c.x < 8 ? 0x74696e67U : f;
			drawStr( f, c, uv, vec2(-23.4, 60), 13., vec3(255./255., 208./255., 128./255.), outCol );		}

    }
    if(text2.y > 0) { // body
        int i = text2.y;
		ivec2 c = ivec2( (uv - vec2(-120, 40)) * (1./vec2(3.6, -8)) + vec2(1,2)) - 1;
		uint f = 0x0U;
		if( i == 1 || i == 2 ) {
			if(c.y == 0) f = c.x < 4 ? 0x496e2074U : c.x < 8 ? 0x68697320U : c.x < 12 ? 0x7475746fU : c.x < 16 ? 0x7269616cU : c.x < 20 ? 0x20796f75U : c.x < 24 ? 0x2077696cU : c.x < 28 ? 0x6c206c65U : c.x < 32 ? 0x61726e20U : c.x < 36 ? 0x686f7720U : c.x < 40 ? 0x746f2072U : c.x < 44 ? 0x656e6465U : c.x < 48 ? 0x7220200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x61203364U : c.x < 8 ? 0x2d736365U : c.x < 12 ? 0x6e652069U : c.x < 16 ? 0x6e205368U : c.x < 20 ? 0x61646572U : c.x < 24 ? 0x746f7920U : c.x < 28 ? 0x7573696eU : c.x < 32 ? 0x67206469U : c.x < 36 ? 0x7374616eU : c.x < 40 ? 0x63652066U : c.x < 44 ? 0x69656c64U : c.x < 48 ? 0x732e2020U : f;
		}
		if( i == 2 ) {
			if(c.y == 3) f = c.x < 4 ? 0x41732061U : c.x < 8 ? 0x6e206578U : c.x < 12 ? 0x616d706cU : c.x < 16 ? 0x652c2077U : c.x < 20 ? 0x65207769U : c.x < 24 ? 0x6c6c2063U : c.x < 28 ? 0x72656174U : c.x < 32 ? 0x65207468U : c.x < 36 ? 0x69732062U : c.x < 40 ? 0x6c61636bU : c.x < 44 ? 0x20616e64U : c.x < 48 ? 0x2020200aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x77686974U : c.x < 8 ? 0x65207363U : c.x < 12 ? 0x656e6520U : c.x < 16 ? 0x6f662074U : c.x < 20 ? 0x68726565U : c.x < 24 ? 0x20737068U : c.x < 28 ? 0x65726573U : c.x < 32 ? 0x206f6e20U : c.x < 36 ? 0x6120706cU : c.x < 40 ? 0x616e652eU : f;
		}
		else if( i == 3 || i == 4 ) {
			if(c.y == 0) f = c.x < 4 ? 0x46697273U : c.x < 8 ? 0x74207765U : c.x < 12 ? 0x20637265U : c.x < 16 ? 0x61746520U : c.x < 20 ? 0x61207261U : c.x < 24 ? 0x792e200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x54686520U : c.x < 8 ? 0x72617920U : c.x < 12 ? 0x6f726967U : c.x < 16 ? 0x696e2028U : c.x < 20 ? 0x726f2920U : c.x < 24 ? 0x77696c6cU : c.x < 28 ? 0x20626520U : c.x < 32 ? 0x61742028U : c.x < 36 ? 0x302c302cU : c.x < 40 ? 0x31292e20U : f;
		}
		if( i == 4 ) {
			if(c.y == 3) f = c.x < 4 ? 0x496e2063U : c.x < 8 ? 0x6f64653aU : f;
		}
		else if( i == 5 ) {
			if(c.y == 0) f = c.x < 4 ? 0x4e6f7720U : c.x < 8 ? 0x77652070U : c.x < 12 ? 0x6c616365U : c.x < 16 ? 0x20612076U : c.x < 20 ? 0x69727475U : c.x < 24 ? 0x616c2073U : c.x < 28 ? 0x63726565U : c.x < 32 ? 0x6e20696eU : c.x < 36 ? 0x20746865U : c.x < 40 ? 0x20736365U : c.x < 44 ? 0x6e652e0aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x49742069U : c.x < 8 ? 0x73206c6fU : c.x < 12 ? 0x63617465U : c.x < 16 ? 0x64206174U : c.x < 20 ? 0x20746865U : c.x < 24 ? 0x206f7269U : c.x < 28 ? 0x67696e20U : c.x < 32 ? 0x616e6420U : c.x < 36 ? 0x6861730aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x64696d65U : c.x < 8 ? 0x6e73696fU : c.x < 12 ? 0x6e73206fU : c.x < 16 ? 0x66206173U : c.x < 20 ? 0x70656374U : c.x < 24 ? 0x5f726174U : c.x < 28 ? 0x696f2078U : c.x < 32 ? 0x20312e20U : f;
		}
		else if( i == 6 || i == 7 ) {
			if(c.y == 0) f = c.x < 4 ? 0x57652063U : c.x < 8 ? 0x6f6d7075U : c.x < 12 ? 0x74652074U : c.x < 16 ? 0x68652072U : c.x < 20 ? 0x61792064U : c.x < 24 ? 0x69726563U : c.x < 28 ? 0x74696f6eU : c.x < 32 ? 0x20287264U : c.x < 36 ? 0x2920666fU : c.x < 40 ? 0x72206561U : c.x < 44 ? 0x6368200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x70697865U : c.x < 8 ? 0x6c202866U : c.x < 12 ? 0x72616743U : c.x < 16 ? 0x6f6f7264U : c.x < 20 ? 0x2e787929U : c.x < 24 ? 0x206f6620U : c.x < 28 ? 0x6f757220U : c.x < 32 ? 0x76697274U : c.x < 36 ? 0x75616c20U : c.x < 40 ? 0x73637265U : c.x < 44 ? 0x656e2e20U : f;
		}
		if( i == 7 ) {
			if(c.y == 3) f = c.x < 4 ? 0x496e2063U : c.x < 8 ? 0x6f64653aU : f;
		}
		else if( i == 8 ) {
			if(c.y == 0) f = c.x < 4 ? 0x55736520U : c.x < 8 ? 0x796f7572U : c.x < 12 ? 0x206d6f75U : c.x < 16 ? 0x73652074U : c.x < 20 ? 0x6f20696eU : c.x < 24 ? 0x74657261U : c.x < 28 ? 0x63742077U : c.x < 32 ? 0x69746820U : c.x < 36 ? 0x74686520U : c.x < 40 ? 0x7363656eU : c.x < 44 ? 0x652e2020U : f;
		}
		else if( i == 9 ) {
			if(c.y == 0) f = c.x < 4 ? 0x41206469U : c.x < 8 ? 0x7374616eU : c.x < 12 ? 0x63652066U : c.x < 16 ? 0x69656c64U : c.x < 20 ? 0x20697320U : c.x < 24 ? 0x75736564U : c.x < 28 ? 0x20746f20U : c.x < 32 ? 0x66696e64U : c.x < 36 ? 0x20746865U : c.x < 40 ? 0x2020200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x696e7465U : c.x < 8 ? 0x72736563U : c.x < 12 ? 0x74696f6eU : c.x < 16 ? 0x206f6620U : c.x < 20 ? 0x6f757220U : c.x < 24 ? 0x72617920U : c.x < 28 ? 0x28726f2cU : c.x < 32 ? 0x20726429U : c.x < 36 ? 0x20616e64U : c.x < 40 ? 0x20746865U : c.x < 44 ? 0x20737068U : c.x < 48 ? 0x65726573U : c.x < 52 ? 0x2020200aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x616e6420U : c.x < 8 ? 0x706c616eU : c.x < 12 ? 0x65206f66U : c.x < 16 ? 0x20746865U : c.x < 20 ? 0x20736365U : c.x < 24 ? 0x6e652e20U : f;
		}
		else if( i == 10 ) {
			if(c.y == 0) f = c.x < 4 ? 0x41206469U : c.x < 8 ? 0x7374616eU : c.x < 12 ? 0x63652066U : c.x < 16 ? 0x69656c64U : c.x < 20 ? 0x20697320U : c.x < 24 ? 0x61206675U : c.x < 28 ? 0x6e637469U : c.x < 32 ? 0x6f6e2074U : c.x < 36 ? 0x68617420U : c.x < 40 ? 0x67697665U : c.x < 44 ? 0x7320616eU : c.x < 48 ? 0x2020200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x65737469U : c.x < 8 ? 0x6d617465U : c.x < 12 ? 0x20286120U : c.x < 16 ? 0x6c6f7765U : c.x < 20 ? 0x7220626fU : c.x < 24 ? 0x756e6420U : c.x < 28 ? 0x6f662920U : c.x < 32 ? 0x74686520U : c.x < 36 ? 0x64697374U : c.x < 40 ? 0x616e6365U : c.x < 44 ? 0x20746f20U : c.x < 48 ? 0x7468650aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x636c6f73U : c.x < 8 ? 0x65737420U : c.x < 12 ? 0x73757266U : c.x < 16 ? 0x61636520U : c.x < 20 ? 0x61742061U : c.x < 24 ? 0x6e792070U : c.x < 28 ? 0x6f696e74U : c.x < 32 ? 0x20696e20U : c.x < 36 ? 0x73706163U : c.x < 40 ? 0x652e2020U : f;
		}
		else if( i == 11 ) {
			if(c.y == 0) f = c.x < 4 ? 0x54686520U : c.x < 8 ? 0x64697374U : c.x < 12 ? 0x616e6365U : c.x < 16 ? 0x2066756eU : c.x < 20 ? 0x6374696fU : c.x < 24 ? 0x6e20666fU : c.x < 28 ? 0x72206120U : c.x < 32 ? 0x73706865U : c.x < 36 ? 0x72652069U : c.x < 40 ? 0x73207468U : c.x < 44 ? 0x65206469U : c.x < 48 ? 0x7374616eU : c.x < 52 ? 0x63652074U : c.x < 56 ? 0x6f20200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x74686520U : c.x < 8 ? 0x63656e74U : c.x < 12 ? 0x6572206fU : c.x < 16 ? 0x66207468U : c.x < 20 ? 0x65207370U : c.x < 24 ? 0x68657265U : c.x < 28 ? 0x206d696eU : c.x < 32 ? 0x75732074U : c.x < 36 ? 0x68652072U : c.x < 40 ? 0x61646975U : c.x < 44 ? 0x73206f66U : c.x < 48 ? 0x20746865U : c.x < 52 ? 0x20737068U : c.x < 56 ? 0x6572652eU : f;
		}
		else if( i == 12 ) {
			if(c.y == 0) f = c.x < 4 ? 0x54686520U : c.x < 8 ? 0x636f6465U : c.x < 12 ? 0x20666f72U : c.x < 16 ? 0x20612073U : c.x < 20 ? 0x70686572U : c.x < 24 ? 0x65206c6fU : c.x < 28 ? 0x63617465U : c.x < 32 ? 0x64206174U : c.x < 36 ? 0x20282d31U : c.x < 40 ? 0x2c302c2dU : c.x < 44 ? 0x35293a20U : f;
		}
		else if( i == 13 || i == 14 ) {
			if(c.y == 0) f = c.x < 4 ? 0x57652063U : c.x < 8 ? 0x6f6d6269U : c.x < 12 ? 0x6e652064U : c.x < 16 ? 0x69666665U : c.x < 20 ? 0x72656e74U : c.x < 24 ? 0x20646973U : c.x < 28 ? 0x74616e63U : c.x < 32 ? 0x65206675U : c.x < 36 ? 0x6e637469U : c.x < 40 ? 0x6f6e7320U : c.x < 44 ? 0x62792074U : c.x < 48 ? 0x616b696eU : c.x < 52 ? 0x6720200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x74686520U : c.x < 8 ? 0x6d696e69U : c.x < 12 ? 0x6d756d20U : c.x < 16 ? 0x76616c75U : c.x < 20 ? 0x65206f66U : c.x < 24 ? 0x20746865U : c.x < 28 ? 0x73652066U : c.x < 32 ? 0x756e6374U : c.x < 36 ? 0x696f6e73U : c.x < 40 ? 0x2e202020U : f;
		}
		if( i == 14 ) {
			if(c.y == 3) f = c.x < 4 ? 0x496e2063U : c.x < 8 ? 0x6f64653aU : f;
		}
		else if( i == 15 ) {
			if(c.y == 0) f = c.x < 4 ? 0x54686520U : c.x < 8 ? 0x746f7461U : c.x < 12 ? 0x6c206469U : c.x < 16 ? 0x7374616eU : c.x < 20 ? 0x63652066U : c.x < 24 ? 0x756e6374U : c.x < 28 ? 0x696f6e20U : c.x < 32 ? 0x666f7220U : c.x < 36 ? 0x74686973U : c.x < 40 ? 0x20736365U : c.x < 44 ? 0x6e65200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x28696e63U : c.x < 8 ? 0x6c756469U : c.x < 12 ? 0x6e672074U : c.x < 16 ? 0x68652070U : c.x < 20 ? 0x6c616e65U : c.x < 24 ? 0x29206973U : c.x < 28 ? 0x20676976U : c.x < 32 ? 0x656e2062U : c.x < 36 ? 0x793a2020U : f;
		}
		else if( i == 16 || i == 17 ) {
			if(c.y == 0) f = c.x < 4 ? 0x4e6f7720U : c.x < 8 ? 0x77652063U : c.x < 12 ? 0x616e206dU : c.x < 16 ? 0x61726368U : c.x < 20 ? 0x20746865U : c.x < 24 ? 0x20736365U : c.x < 28 ? 0x6e652066U : c.x < 32 ? 0x726f6d20U : c.x < 36 ? 0x726f2069U : c.x < 40 ? 0x6e206469U : c.x < 44 ? 0x72656374U : c.x < 48 ? 0x696f6e20U : c.x < 52 ? 0x72642e0aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x45616368U : c.x < 8 ? 0x20737465U : c.x < 12 ? 0x70207369U : c.x < 16 ? 0x7a652069U : c.x < 20 ? 0x73206769U : c.x < 24 ? 0x76656e20U : c.x < 28 ? 0x62792074U : c.x < 32 ? 0x68652064U : c.x < 36 ? 0x69737461U : c.x < 40 ? 0x6e636520U : c.x < 44 ? 0x6669656cU : c.x < 48 ? 0x642e2020U : f;
		}
		if( i == 17 ) {
			if(c.y == 3) f = c.x < 4 ? 0x57652073U : c.x < 8 ? 0x746f7020U : c.x < 12 ? 0x74686520U : c.x < 16 ? 0x6d617263U : c.x < 20 ? 0x68207768U : c.x < 24 ? 0x656e2077U : c.x < 28 ? 0x65206669U : c.x < 32 ? 0x6e642061U : c.x < 36 ? 0x6e20696eU : c.x < 40 ? 0x74657273U : c.x < 44 ? 0x65637469U : c.x < 48 ? 0x6f6e3a20U : f;
		}
		else if( i == 18 ) {
			if(c.y == 0) f = c.x < 4 ? 0x4e6f7720U : c.x < 8 ? 0x74686174U : c.x < 12 ? 0x20776520U : c.x < 16 ? 0x68617665U : c.x < 20 ? 0x20666f75U : c.x < 24 ? 0x6e642074U : c.x < 28 ? 0x68652069U : c.x < 32 ? 0x6e746572U : c.x < 36 ? 0x73656374U : c.x < 40 ? 0x696f6e20U : c.x < 44 ? 0x2870203dU : c.x < 48 ? 0x20726f20U : c.x < 52 ? 0x2b207264U : c.x < 56 ? 0x202a2074U : c.x < 60 ? 0x2920200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x666f7220U : c.x < 8 ? 0x6f757220U : c.x < 12 ? 0x7261792cU : c.x < 16 ? 0x20776520U : c.x < 20 ? 0x63616e20U : c.x < 24 ? 0x67697665U : c.x < 28 ? 0x20746865U : c.x < 32 ? 0x20736365U : c.x < 36 ? 0x6e652073U : c.x < 40 ? 0x6f6d6520U : c.x < 44 ? 0x6c696768U : c.x < 48 ? 0x74696e67U : c.x < 52 ? 0x2e20200aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x2020200aU : f;
			if(c.y == 3) f = c.x < 4 ? 0x546f2061U : c.x < 8 ? 0x70706c79U : c.x < 12 ? 0x20646966U : c.x < 16 ? 0x66757365U : c.x < 20 ? 0x206c6967U : c.x < 24 ? 0x6874696eU : c.x < 28 ? 0x67207765U : c.x < 32 ? 0x20686176U : c.x < 36 ? 0x6520746fU : c.x < 40 ? 0x2063616cU : c.x < 44 ? 0x63756c61U : c.x < 48 ? 0x7465200aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x74686520U : c.x < 8 ? 0x6e6f726dU : c.x < 12 ? 0x616c206fU : c.x < 16 ? 0x66207368U : c.x < 20 ? 0x6164696eU : c.x < 24 ? 0x6720706fU : c.x < 28 ? 0x696e7420U : c.x < 32 ? 0x702e2020U : f;
		}
		else if( i == 19 ) {
			if(c.y == 0) f = c.x < 4 ? 0x54686520U : c.x < 8 ? 0x6e6f726dU : c.x < 12 ? 0x616c2063U : c.x < 16 ? 0x616e2062U : c.x < 20 ? 0x65206361U : c.x < 24 ? 0x6c63756cU : c.x < 28 ? 0x61746564U : c.x < 32 ? 0x20627920U : c.x < 36 ? 0x74616b69U : c.x < 40 ? 0x6e672074U : c.x < 44 ? 0x68652063U : c.x < 48 ? 0x656e7472U : c.x < 52 ? 0x616c200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x64696666U : c.x < 8 ? 0x6572656eU : c.x < 12 ? 0x63657320U : c.x < 16 ? 0x6f6e2074U : c.x < 20 ? 0x68652064U : c.x < 24 ? 0x69737461U : c.x < 28 ? 0x6e636520U : c.x < 32 ? 0x6669656cU : c.x < 36 ? 0x643a2020U : f;
		}
		else if( i == 20 || i == 21 ) {
			if(c.y == 0) f = c.x < 4 ? 0x57652063U : c.x < 8 ? 0x616c6375U : c.x < 12 ? 0x6c617465U : c.x < 16 ? 0x20746865U : c.x < 20 ? 0x20646966U : c.x < 24 ? 0x66757365U : c.x < 28 ? 0x206c6967U : c.x < 32 ? 0x6874696eU : c.x < 36 ? 0x6720666fU : c.x < 40 ? 0x7220610aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x706f696eU : c.x < 8 ? 0x74206c69U : c.x < 12 ? 0x67687420U : c.x < 16 ? 0x61742070U : c.x < 20 ? 0x6f736974U : c.x < 24 ? 0x696f6e20U : c.x < 28 ? 0x28302c32U : c.x < 32 ? 0x2c30292eU : f;
		}
		if( i == 21 ) {
			if(c.y == 3) f = c.x < 4 ? 0x496e2063U : c.x < 8 ? 0x6f64653aU : f;
		}
		else if( i == 22 ) {
			if(c.y == 0) f = c.x < 4 ? 0x416e6420U : c.x < 8 ? 0x77652061U : c.x < 12 ? 0x72652064U : c.x < 16 ? 0x6f6e6521U : c.x < 20 ? 0x2020200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x2020200aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x41646469U : c.x < 8 ? 0x6e672061U : c.x < 12 ? 0x6d626965U : c.x < 16 ? 0x6e74206fU : c.x < 20 ? 0x63636c75U : c.x < 24 ? 0x73696f6eU : c.x < 28 ? 0x2c202866U : c.x < 32 ? 0x616b6529U : c.x < 36 ? 0x20726566U : c.x < 40 ? 0x6c656374U : c.x < 44 ? 0x696f6e73U : c.x < 48 ? 0x2c20200aU : f;
			if(c.y == 3) f = c.x < 4 ? 0x736f6674U : c.x < 8 ? 0x20736861U : c.x < 12 ? 0x646f7773U : c.x < 16 ? 0x2c20666fU : c.x < 20 ? 0x672c2061U : c.x < 24 ? 0x6d626965U : c.x < 28 ? 0x6e74206cU : c.x < 32 ? 0x69676874U : c.x < 36 ? 0x696e6720U : c.x < 40 ? 0x616e6420U : c.x < 44 ? 0x73706563U : c.x < 48 ? 0x756c6172U : c.x < 52 ? 0x206c6967U : c.x < 56 ? 0x6874696eU : c.x < 60 ? 0x6720200aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x6973206cU : c.x < 8 ? 0x65667420U : c.x < 12 ? 0x61732061U : c.x < 16 ? 0x6e206578U : c.x < 20 ? 0x65726369U : c.x < 24 ? 0x73652066U : c.x < 28 ? 0x6f722074U : c.x < 32 ? 0x68652072U : c.x < 36 ? 0x65616465U : c.x < 40 ? 0x722e2020U : f;
		}
		drawStr( f, c, uv, vec2(-120, 40), 8., vec3(1), outCol );
    }
    if(text2.z > 0) { // code
        int i = text2.z;
		ivec2 c = ivec2( (uv - vec2(-120, 0)) * (1./vec2(3.6, -8)) + vec2(1,2)) - 1;
		uint f = 0x0U;
		if( i == 1 ) {
			if(c.y == 0) f = c.x < 4 ? 0x766f6964U : c.x < 8 ? 0x206d6169U : c.x < 12 ? 0x6e496d61U : c.x < 16 ? 0x6765286fU : c.x < 20 ? 0x75742076U : c.x < 24 ? 0x65633420U : c.x < 28 ? 0x66726167U : c.x < 32 ? 0x436f6c6fU : c.x < 36 ? 0x722c2069U : c.x < 40 ? 0x6e207665U : c.x < 44 ? 0x63322066U : c.x < 48 ? 0x72616743U : c.x < 52 ? 0x6f6f7264U : c.x < 56 ? 0x29207b0aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x76656333U : c.x < 12 ? 0x20726f20U : c.x < 16 ? 0x3d207665U : c.x < 20 ? 0x63332830U : c.x < 24 ? 0x2c20302cU : c.x < 28 ? 0x2031293bU : c.x < 32 ? 0x2020200aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x2020200aU : f;
			if(c.y == 3) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x76656332U : c.x < 12 ? 0x2071203dU : c.x < 16 ? 0x20286672U : c.x < 20 ? 0x6167436fU : c.x < 24 ? 0x6f72642eU : c.x < 28 ? 0x7879202dU : c.x < 32 ? 0x202e3520U : c.x < 36 ? 0x2a206952U : c.x < 40 ? 0x65736f6cU : c.x < 44 ? 0x7574696fU : c.x < 48 ? 0x6e2e7879U : c.x < 52 ? 0x2029202fU : c.x < 56 ? 0x20695265U : c.x < 60 ? 0x736f6c75U : c.x < 64 ? 0x74696f6eU : c.x < 68 ? 0x2e793b0aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x76656333U : c.x < 12 ? 0x20726420U : c.x < 16 ? 0x3d206e6fU : c.x < 20 ? 0x726d616cU : c.x < 24 ? 0x697a6528U : c.x < 28 ? 0x76656333U : c.x < 32 ? 0x28712c20U : c.x < 36 ? 0x302e2920U : c.x < 40 ? 0x2d20726fU : c.x < 44 ? 0x293b200aU : f;
		}
		else if( i == 2 ) {
			if(c.y == 0) f = c.x < 4 ? 0x666c6f61U : c.x < 8 ? 0x74206d61U : c.x < 12 ? 0x70287665U : c.x < 16 ? 0x63332070U : c.x < 20 ? 0x29207b0aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x666c6f61U : c.x < 12 ? 0x74206420U : c.x < 16 ? 0x3d206469U : c.x < 20 ? 0x7374616eU : c.x < 24 ? 0x63652870U : c.x < 28 ? 0x2c207665U : c.x < 32 ? 0x6333282dU : c.x < 36 ? 0x312c2030U : c.x < 40 ? 0x2c202d35U : c.x < 44 ? 0x2929202dU : c.x < 48 ? 0x20312e3bU : c.x < 52 ? 0x2020200aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x64203d20U : c.x < 12 ? 0x6d696e28U : c.x < 16 ? 0x642c2064U : c.x < 20 ? 0x69737461U : c.x < 24 ? 0x6e636528U : c.x < 28 ? 0x702c2076U : c.x < 32 ? 0x65633328U : c.x < 36 ? 0x322c2030U : c.x < 40 ? 0x2c202d33U : c.x < 44 ? 0x2929202dU : c.x < 48 ? 0x20312e29U : c.x < 52 ? 0x3b20200aU : f;
			if(c.y == 3) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x64203d20U : c.x < 12 ? 0x6d696e28U : c.x < 16 ? 0x642c2064U : c.x < 20 ? 0x69737461U : c.x < 24 ? 0x6e636528U : c.x < 28 ? 0x702c2076U : c.x < 32 ? 0x65633328U : c.x < 36 ? 0x2d322c20U : c.x < 40 ? 0x302c202dU : c.x < 44 ? 0x32292920U : c.x < 48 ? 0x2d20312eU : c.x < 52 ? 0x293b200aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x64203d20U : c.x < 12 ? 0x6d696e28U : c.x < 16 ? 0x642c2070U : c.x < 20 ? 0x2e79202bU : c.x < 24 ? 0x20312e29U : c.x < 28 ? 0x3b20200aU : f;
			if(c.y == 5) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x72657475U : c.x < 12 ? 0x726e2064U : c.x < 16 ? 0x3b20200aU : f;
			if(c.y == 6) f = c.x < 4 ? 0x7d202020U : f;
		}
		else if( i == 3 ) {
			if(c.y == 0) f = c.x < 4 ? 0x666c6f61U : c.x < 8 ? 0x7420682cU : c.x < 12 ? 0x2074203dU : c.x < 16 ? 0x20312e3bU : c.x < 20 ? 0x2020200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x666f7220U : c.x < 8 ? 0x28696e74U : c.x < 12 ? 0x2069203dU : c.x < 16 ? 0x20303b20U : c.x < 20 ? 0x69203c20U : c.x < 24 ? 0x3235363bU : c.x < 28 ? 0x20692b2bU : c.x < 32 ? 0x29207b0aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x68203d20U : c.x < 12 ? 0x6d617028U : c.x < 16 ? 0x726f202bU : c.x < 20 ? 0x20726420U : c.x < 24 ? 0x2a207429U : c.x < 28 ? 0x3b20200aU : f;
			if(c.y == 3) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x74202b3dU : c.x < 12 ? 0x20683b0aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x69662028U : c.x < 12 ? 0x68203c20U : c.x < 16 ? 0x302e3031U : c.x < 20 ? 0x29206272U : c.x < 24 ? 0x65616b3bU : c.x < 28 ? 0x2020200aU : f;
			if(c.y == 5) f = c.x < 4 ? 0x7d202020U : f;
		}
		else if( i == 4 ) {
			if(c.y == 0) f = c.x < 4 ? 0x76656333U : c.x < 8 ? 0x2063616cU : c.x < 12 ? 0x634e6f72U : c.x < 16 ? 0x6d616c28U : c.x < 20 ? 0x696e2076U : c.x < 24 ? 0x65633320U : c.x < 28 ? 0x7029207bU : c.x < 32 ? 0x2020200aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x76656332U : c.x < 12 ? 0x2065203dU : c.x < 16 ? 0x20766563U : c.x < 20 ? 0x3228312eU : c.x < 24 ? 0x302c202dU : c.x < 28 ? 0x312e3029U : c.x < 32 ? 0x202a2030U : c.x < 36 ? 0x2e303030U : c.x < 40 ? 0x353b200aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x72657475U : c.x < 12 ? 0x726e206eU : c.x < 16 ? 0x6f726d61U : c.x < 20 ? 0x6c697a65U : c.x < 24 ? 0x2820200aU : f;
			if(c.y == 3) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x20202020U : c.x < 12 ? 0x652e7879U : c.x < 16 ? 0x79202a20U : c.x < 20 ? 0x6d617028U : c.x < 24 ? 0x70202b20U : c.x < 28 ? 0x652e7879U : c.x < 32 ? 0x7929202bU : c.x < 36 ? 0x2020200aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x20202020U : c.x < 12 ? 0x652e7979U : c.x < 16 ? 0x78202a20U : c.x < 20 ? 0x6d617028U : c.x < 24 ? 0x70202b20U : c.x < 28 ? 0x652e7979U : c.x < 32 ? 0x7829202bU : c.x < 36 ? 0x2020200aU : f;
			if(c.y == 5) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x20202020U : c.x < 12 ? 0x652e7978U : c.x < 16 ? 0x79202a20U : c.x < 20 ? 0x6d617028U : c.x < 24 ? 0x70202b20U : c.x < 28 ? 0x652e7978U : c.x < 32 ? 0x7929202bU : c.x < 36 ? 0x2020200aU : f;
			if(c.y == 6) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x20202020U : c.x < 12 ? 0x652e7878U : c.x < 16 ? 0x78202a20U : c.x < 20 ? 0x6d617028U : c.x < 24 ? 0x70202b20U : c.x < 28 ? 0x652e7878U : c.x < 32 ? 0x7829293bU : c.x < 36 ? 0x2020200aU : f;
			if(c.y == 7) f = c.x < 4 ? 0x7d202020U : f;
		}
		else if( i == 5 ) {
			if(c.y == 0) f = c.x < 4 ? 0x69662028U : c.x < 8 ? 0x68203c20U : c.x < 12 ? 0x302e3031U : c.x < 16 ? 0x29207b0aU : f;
			if(c.y == 1) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x76656333U : c.x < 12 ? 0x2070203dU : c.x < 16 ? 0x20726f20U : c.x < 20 ? 0x2b207264U : c.x < 24 ? 0x202a2074U : c.x < 28 ? 0x3b20200aU : f;
			if(c.y == 2) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x76656333U : c.x < 12 ? 0x206e6f72U : c.x < 16 ? 0x6d616c20U : c.x < 20 ? 0x3d206361U : c.x < 24 ? 0x6c634e6fU : c.x < 28 ? 0x726d616cU : c.x < 32 ? 0x2870293bU : c.x < 36 ? 0x2020200aU : f;
			if(c.y == 3) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x76656333U : c.x < 12 ? 0x206c6967U : c.x < 16 ? 0x6874203dU : c.x < 20 ? 0x20766563U : c.x < 24 ? 0x3328302cU : c.x < 28 ? 0x20322c20U : c.x < 32 ? 0x30293b0aU : f;
			if(c.y == 4) f = c.x < 4 ? 0x2020200aU : f;
			if(c.y == 5) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x666c6f61U : c.x < 12 ? 0x74206469U : c.x < 16 ? 0x66203d20U : c.x < 20 ? 0x636c616dU : c.x < 24 ? 0x7028646fU : c.x < 28 ? 0x74286e6fU : c.x < 32 ? 0x726d616cU : c.x < 36 ? 0x2c206e6fU : c.x < 40 ? 0x726d616cU : c.x < 44 ? 0x697a6528U : c.x < 48 ? 0x6c696768U : c.x < 52 ? 0x74202d20U : c.x < 56 ? 0x7029292cU : c.x < 60 ? 0x20302e2cU : c.x < 64 ? 0x20312e29U : c.x < 68 ? 0x3b20200aU : f;
			if(c.y == 6) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x64696620U : c.x < 12 ? 0x2a3d2035U : c.x < 16 ? 0x2e202f20U : c.x < 20 ? 0x646f7428U : c.x < 24 ? 0x6c696768U : c.x < 28 ? 0x74202d20U : c.x < 32 ? 0x702c206cU : c.x < 36 ? 0x69676874U : c.x < 40 ? 0x202d2070U : c.x < 44 ? 0x293b200aU : f;
			if(c.y == 7) f = c.x < 4 ? 0x20202020U : c.x < 8 ? 0x66726167U : c.x < 12 ? 0x436f6c6fU : c.x < 16 ? 0x72203d20U : c.x < 20 ? 0x76656334U : c.x < 24 ? 0x28766563U : c.x < 28 ? 0x3328706fU : c.x < 32 ? 0x77286469U : c.x < 36 ? 0x662c2030U : c.x < 40 ? 0x2e343534U : c.x < 44 ? 0x3529292cU : c.x < 48 ? 0x2031293bU : c.x < 52 ? 0x2020200aU : f;
			if(c.y == 8) f = c.x < 4 ? 0x7d202020U : f;
		}
		drawStr( f, c, uv, vec2(-120, 0), 8., vec3(.8,.95,1.), outCol );
        if( text1.y > 0 ) {
           if(uv.y >  - (-1.+float(text1.y))*8. && c.y >= 0 ) {
                outCol *= vec4(.5,.2,.6,.8);
            }
        }
        if( text1.z > 0 ) {
            if(uv.y <  - (-2.+float(text1.z))*8. && c.y >= 0 ) {
                outCol *= vec4(.5,.2,.6,.8);
            }
        }
    }
    if(slideData.y == 120) { // footer
        int i = 1;
		uint f = 0x0U;
		if( i == 1 ) {
			ivec2 c = ivec2( (uv - vec2(-38.8, -78)) * (1./vec2(3.38, -7.5)) + vec2(1,2)) - 1;
			if(c.y == 0) f = c.x < 4 ? 0x50726573U : c.x < 8 ? 0x73207370U : c.x < 12 ? 0x61636520U : c.x < 16 ? 0x746f2063U : c.x < 20 ? 0x6f6e7469U : c.x < 24 ? 0x6e756520U : f;
			drawStr( f, c, uv, vec2(-38.8, -78), 7.5, vec3(.9), outCol );		}

    }
}