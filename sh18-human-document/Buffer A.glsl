﻿// [SH18] Human Document. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/XtcyW4
//
//   * Created for the Shadertoy Competition 2018 *
// 
// Buffer A: I have preprocessed a (motion captured) animation by taking the Fourier 
//           transform of the position of all bones (14 bones, 760 frames). Only a fraction 
//           of all calculated coefficients are stored in this shader: the first 
//           coefficients with 16 bit precision, later coefficients with 8 bit. The positions
//           of the bones are reconstructed each frame by taking the inverse Fourier
//           transform of this data.
//
//           I have used (part of) an animation from the Carnegie Mellon University Motion 
//           Capture Database. The animations of this database are free to use:
//
//           - http://mocap.cs.cmu.edu/
// 
//           Íñigo Quílez has created some excellent shaders that show the properties of 
//           Fourier transforms, for example: 
//
//           - https://www.shadertoy.com/view/4lGSDw
//           - https://www.shadertoy.com/view/ltKSWD
//


#define HQ 10
#define LQ 13

vec2 cmul(vec2 a, vec2 b) { return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x); }
#define S(q,s,c) (float((q >> s) & 0xFFU)*c.x-c.y)
#define SH(q,s,c) (float((q >> s) & 0xFFFFU)*c.x-c.y)

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    if(int(fragCoord.x) > 0 || int(fragCoord.y) > NUM_BONES) {      
        return;
    }
    
    initAnimation(iTime);
    
	int y = int(fragCoord.y);  
    float s1 = (6.28318530718/FRAMES)*frame;
    vec2 pos = vec2(0);
    vec2 posy = vec2(0);
    
    uint[HQ] hqd;
    uint[LQ] lqd;

    uint[HQ] hqyd;
    uint[LQ] lqyd;
    
    uint[HQ] hqdB;
    uint[LQ] lqdB;
    
    uint[HQ] hqydB;
    uint[LQ] lqydB;

    // scale 
    const vec3 scale = vec3(0.012353025376796722, 0.011576368473470211, 0.025544768199324608); 

    // scale, offset - first coeffs 
    const vec2 ch = vec2(0.014635691419243813, 636.2047119140625); 
    const vec2 cl = vec2(0.39385828375816345, 42.45376205444336); 

    // scale, offset - last coeffs 
    const vec2 chb = vec2(0.003957926761358976, 118.40463256835938);
    const vec2 clb = vec2(0.520740270614624, 58.412567138671875);


    if (y==0) { hqd = uint[10] (0x7f2d8b92U,0xc4f2beaeU,0xbbeaad0eU,0xd070a2e9U,0xb266a557U,0xb19fa162U,0xad6ca7edU,0xb0f7ac1fU,0xb104ac21U,0xb2439bbfU); lqd = uint[13] (0x928a893cU,0x537c793cU,0x6792965bU,0x6466c17aU,0x7748a244U,0x9f628b6bU,0x995b7167U,0x825a6c62U,0x727c6767U,0x84687269U,0x7d709262U,0x74638d50U,0x7b697e68U);}
    if (y==0 || y==1) { hqyd = uint[10] (0x45960000U,0xb649b0efU,0xb91aa98aU,0xafbaa34dU,0xa830a08fU,0xac65a40cU,0xaa63a1d7U,0xa37ca7edU,0xac25a239U,0xaf63ad31U); lqyd = uint[13] (0x1505b2cU,0xac01194U,0xbaae51f4U,0xbe3a7385U,0x953f9568U,0x58757b42U,0x807b6578U,0x26549d61U,0x4e5b634dU,0x646d4f74U,0x7f86567aU,0x9670756fU,0x6770546dU);}
    if (y==1) { hqd = uint[10] (0x6f4585cbU,0xc4a3bce4U,0xb9f2b155U,0xcbc89e17U,0xacdba615U,0xabb69dd9U,0xb168ab59U,0xac9ea649U,0xb314a969U,0xafe2a327U); lqd = uint[13] (0x9e7c8c46U,0x7d645c57U,0x6f636f51U,0x765d9b5cU,0x8e566451U,0x78638e62U,0x705e7169U,0x76697177U,0x7a637c68U,0x7f607767U,0x78607353U,0x736b6f71U,0x7d637f69U);}
    if (y==2) { hqd = uint[10] (0x813a9626U,0xc801c2d1U,0xbf42abe8U,0xcd90a65fU,0xb0e1a15eU,0xaeba9cecU,0xab0fa953U,0xb28fa809U,0xafd4a45bU,0xb0b8a7dbU); lqd = uint[13] (0x90588c2bU,0x6b696944U,0x7c6e7a51U,0x675d995dU,0x7e667b54U,0x6c5e8266U,0x78587967U,0x74607b6fU,0x845c7f68U,0x7d5b7964U,0x775e685cU,0x77676d67U,0x7764706aU);}
    if (y==2 || y==3) { hqyd = uint[10] (0x4838601U,0xaf02a4f0U,0xaba0a4e7U,0xa16a9a56U,0xa0379c04U,0xa68ba99aU,0xa63aab86U,0xa4aca392U,0xa689ab22U,0xa152ac96U); lqyd = uint[13] (0x2150385cU,0x73ff21e2U,0xdaa1b4a2U,0x9e28de0cU,0x37763c06U,0x4e452891U,0x698a7850U,0x2ca4724dU,0x7f9c507cU,0xa15d8184U,0x73599e63U,0x565b504aU,0x5d68695cU);}
    if (y==3) { hqd = uint[10] (0x819db6f2U,0xc5abcc7eU,0xc384a773U,0xc844aa35U,0xb0709d74U,0xa6009fbbU,0xaf9aa9b4U,0xa9f3a8b2U,0xb3a09bf7U,0xafc3ae57U); lqd = uint[13] (0x65464a2bU,0x645c6a55U,0x6e5a8865U,0x5f5db08bU,0x75618131U,0x894c4847U,0x7c577b73U,0x5876615fU,0x6e614d46U,0x92916657U,0x8c6e5a79U,0x785f5d5aU,0x61657e4cU);}
    if (y==4) { hqd = uint[10] (0x7057b74bU,0xc6e5c8f3U,0xc22aab06U,0xc861a366U,0xb0759fd9U,0xa4229de0U,0xb5c7aa1cU,0xa44ba815U,0xb622a03cU,0xad9da952U); lqd = uint[13] (0x7d51642dU,0x77575d78U,0x844c8977U,0x71468a6aU,0x73566a49U,0x7c6c6c59U,0x69767452U,0x6967665eU,0x64526d67U,0x6767846aU,0x636d786aU,0x74677e65U,0x74617163U);}
    if (y==4 || y==5) { hqyd = uint[10] (0x88cd4a5aU,0xb2b7b0e6U,0xb9dbb24eU,0xad0fa4fbU,0xa6ffa074U,0xaca2a79aU,0xa64ea955U,0xa11aac9cU,0xa83dacd4U,0xb306a50dU); lqyd = uint[13] (0xa5a374cU,0x45dc1c98U,0xafb77cb9U,0x8c57db72U,0x81576b48U,0x616a7758U,0x75666467U,0x584e7b6fU,0x69526b59U,0x5a7b4e75U,0x74806075U,0x6f676d7eU,0x66677b6cU);}
    if (y==5) { hqd = uint[10] (0x7fe7b48aU,0xc7f3c61dU,0xc09ba88dU,0xca11a71dU,0xb12fa099U,0xab6da034U,0xad91a571U,0xae72ac1cU,0xb16fa17fU,0xad92a90bU); lqd = uint[13] (0x8454932aU,0x625d7559U,0x7b5b8d64U,0x644e9769U,0x735e765fU,0x6e5a7f6eU,0x775b7465U,0x7263776cU,0x7f637f69U,0x78607e63U,0x70616e57U,0x726a6f66U,0x7566706aU);}
    if (y==6) { hqd = uint[10] (0x797e765dU,0xc9f7c05aU,0xbe9db1b6U,0xd26fa3bcU,0xaad3a0dcU,0xb02297ceU,0xaaa6b166U,0xae69a0b9U,0xaec4a95fU,0xb373a6efU); lqd = uint[13] (0x9a3f535fU,0x82676760U,0x6d7d6f40U,0x6b846236U,0x726b9d59U,0x6252786aU,0x716d7f75U,0x7c797d63U,0x7a667b66U,0x6f647c51U,0x76677467U,0x6f687461U,0x746a735fU);}
    if (y==6 || y==7) { hqyd = uint[10] (0x9ddebb01U,0x9494a957U,0xa223bdd6U,0x9412bad1U,0xa162aebcU,0xc209b52bU,0xb339a79dU,0x9acfa754U,0xa47aaeceU,0xbccab927U); lqyd = uint[13] (0xd876bb65U,0x670ec504U,0x2b333400U,0x2a756964U,0x849f2a9aU,0x6241be66U,0x5583345cU,0x63326785U,0x5d78555eU,0x7aa84298U,0x886ba57dU,0x635b7a4eU,0x6871646eU);}
    if (y==7) { hqd = uint[10] (0x707c816cU,0xc8a2bd56U,0xb894b447U,0xd02e9e32U,0xabe4a20bU,0xad239781U,0xb11aaef1U,0xa637a0c8U,0xb385a979U,0xb4a8a648U); lqd = uint[13] (0x812a6680U,0x9888687aU,0x7263a24fU,0x63886354U,0x7971aa4aU,0x76387a75U,0x76688f7aU,0x6b8d7264U,0x7c638455U,0x8c74784dU,0x88746f6cU,0x7a69785bU,0x7a706b54U);}
    if (y==8) { hqd = uint[10] (0x786185abU,0xccd4c4f2U,0xc299b1a7U,0xd1bda151U,0xacdf9d39U,0xaf0b9a6eU,0xad3caec2U,0xadf1a0ccU,0xb039a7c0U,0xb536a45cU); lqd = uint[13] (0x8f47594aU,0x80576b5cU,0x76696550U,0x85636754U,0x795f8161U,0x71687458U,0x6a72745fU,0x75617e59U,0x76647e67U,0x64627f5bU,0x6c647a61U,0x6e65735fU,0x6b627863U);}
    if (y==8 || y==9) { hqyd = uint[10] (0xffffe30eU,0x8aa3afebU,0x9ac1c8c4U,0x99f2c288U,0xab85b26dU,0xba8eb5d5U,0xadcbae25U,0x9a80a928U,0xa56ab508U,0xbc84b8dcU); lqyd = uint[13] (0xae54b088U,0x752dc82aU,0x27564815U,0x4c7c5e81U,0x85895a8dU,0x5d588573U,0x70755469U,0x595b6a79U,0x7f6a7481U,0x6f6d7173U,0x67687862U,0x666c5f6bU,0x62697471U);}
    if (y==9) { hqd = uint[10] (0x6de79f16U,0xcf64c883U,0xc5c3b1fcU,0xcd459d56U,0xab069cd0U,0xaa239e3eU,0xb50cac41U,0xa4f5a0bcU,0xb25ea61fU,0xb427a28eU); lqd = uint[13] (0x7651566aU,0x8c557a75U,0x855a685fU,0x8f555769U,0x7d587361U,0x84686b50U,0x6c7d6c61U,0x7367745aU,0x70688060U,0x6d6e7d55U,0x706a785fU,0x6b64735eU,0x6d677b61U);}
    if (y==10) { hqd = uint[10] (0x6d23bfd6U,0xd03ec43eU,0xcdc8ad1eU,0xc2ef9dffU,0xaac8a3f1U,0xa63fa2a7U,0xb9e0a3daU,0x9dd2a9d2U,0xb0f1a249U,0xab98a746U); lqd = uint[13] (0x2c5aa46bU,0x768b8969U,0xcd66826fU,0x73586b52U,0x80a36844U,0x775b7f52U,0x6f618e72U,0x9f5e8172U,0x86545463U,0x7f5e6858U,0x846d5d78U,0x85637471U,0x805e6c5cU);}
    if (y==10 || y==11) { hqyd = uint[10] (0xc58eb64bU,0x8e4ca00aU,0x9b52b3b3U,0x9b6fb009U,0xac4bb06bU,0xb4f1b9abU,0xae25aa6dU,0x9eb5a6e5U,0xa7f2b1a6U,0xa99cbbe2U); lqyd = uint[13] (0xc75fc2d3U,0xa51bdd72U,0x6a209613U,0x21596f19U,0x55ac2689U,0xa34aa596U,0x66522a5eU,0xa52b4393U,0x5b499654U,0x299c2b50U,0x788a6991U,0x775b8582U,0x64716960U);}
    if (y==11) { hqd = uint[10] (0x77dcd005U,0xcc81c841U,0xcb2da829U,0xc4b6a5b9U,0xaf569dcaU,0xaa0aa4ceU,0xb38fa1edU,0xa494af97U,0xb1a5a091U,0xadb6a755U); lqd = uint[13] (0x3c74a346U,0x8a729868U,0xab5f956bU,0x7f498158U,0x747f745fU,0x8058715eU,0x72568062U,0x936a836bU,0x82616961U,0x7b546d58U,0x7c606b6aU,0x8263716cU,0x79606958U);}
    if (y==12) { hqd = uint[10] (0x786cc344U,0xcd32cb3fU,0xc7edab4cU,0xca48a2fcU,0xaec49c6cU,0xaad2a2daU,0xb1d2a555U,0xa6fdab44U,0xb231a20fU,0xb0aca64aU); lqd = uint[13] (0x635c7d45U,0x805a8a68U,0x89508165U,0x804e786aU,0x6f5c6f6dU,0x805e6964U,0x776c6d5fU,0x7e687860U,0x7b6d7f67U,0x78627558U,0x73636f60U,0x71656f64U,0x7165755fU);}
    if (y==12 || y==13) { hqyd = uint[10] (0xda14e8ccU,0x92d8a694U,0x9c9cbe57U,0x9be6b744U,0xa953af96U,0xb301b328U,0xabf7ab5fU,0x9bb4a744U,0xa507b50aU,0xb300b446U); lqyd = uint[13] (0x934d939aU,0x85578f73U,0x695a6241U,0x4c647e64U,0x7f8f3e7bU,0x6b627d7aU,0x6e71515fU,0x6d5e6c7bU,0x885c7d7aU,0x58656a61U,0x5d766363U,0x70715e7bU,0x60657d6fU);}
    if (y==13) { hqd = uint[10] (0x7a6fa42aU,0xcbc2c779U,0xc430ad87U,0xcd35a2ebU,0xae879dadU,0xad4b9f22U,0xaee0a953U,0xabdca6b5U,0xb0f2a473U,0xb243a62aU); lqd = uint[13] (0x7f527640U,0x7b577b5bU,0x7e5b7358U,0x7d58745fU,0x735f7767U,0x75617362U,0x736b7060U,0x7a607c61U,0x79668068U,0x715f7b5cU,0x7061725fU,0x70667062U,0x70627664U);}


    if (y==0) { hqdB = uint[10] (0xe21c2f6cU, 0xcb15b85bU, 0x82ac80dbU, 0x84cdc8ffU, 0x4e019d8dU, 0x5248950eU, 0x5fe371bcU, 0x54dd8336U, 0x76639b92U, 0x73ec992eU); lqdB = uint[13] (0x4e9360b6U, 0x428c5087U, 0x64494d75U, 0x4f7d6c6dU, 0x62907478U, 0x7d855a7fU, 0x76845c70U, 0x72847583U, 0x5d8d6986U, 0x5180527dU, 0x5c6c6074U, 0x61767378U, 0x697a647cU);}
    if (y==0 || y==1) { hqydB = uint[10] (0x6546a12eU, 0x54dd93fcU, 0x466e7ab9U, 0x55946828U, 0x67a35c96U, 0x6a6c5743U, 0x6d876a60U, 0x5a9e61f3U, 0x6857718cU, 0x5c81503dU); lqydB = uint[13] (0xb93d7f38U, 0xc1b8dd63U, 0x80b58db8U, 0x407f2a84U, 0x5d534354U, 0x62706571U, 0x4a696289U, 0x6d537247U, 0x87649163U, 0x777f7c6cU, 0x5b696277U, 0x88695c6fU, 0x756e696aU);}
    if (y==1) { hqdB = uint[10] (0xdcf8220dU, 0xecc6cbddU, 0x82ac7569U, 0x8dbdd346U, 0x66a98e0bU, 0x4c3f8cc0U, 0x63777618U, 0x5e0e6fd8U, 0x78309a7dU, 0x6c3f8e24U); lqdB = uint[13] (0x647c41acU, 0x57765776U, 0x8f7b7a6cU, 0x5d846c79U, 0x637b6a76U, 0x6a87697cU, 0x707d647dU, 0x6e7b728fU, 0x6e7e6c7cU, 0x627b6577U, 0x6d7a5f78U, 0x63796b78U, 0x6b7c677bU);}
    if (y==2) { hqdB = uint[10] (0xd64634daU, 0xbc8ebdacU, 0x77979c0cU, 0x7e3fc25dU, 0x5a7a817fU, 0x5de396eaU, 0x5b2b8102U, 0x609b758eU, 0x6f3e8e74U, 0x6fc68268U); lqdB = uint[13] (0x60865b97U, 0x5a804f85U, 0x607a637dU, 0x5e7a6979U, 0x6b7f647aU, 0x617e6774U, 0x65745f74U, 0x6f716d67U, 0x787f7375U, 0x69816d80U, 0x637a617aU, 0x6e736672U, 0x6d766a75U);}
    if (y==2 || y==3) { hqydB = uint[10] (0x98968b51U, 0x980fc32cU, 0x5e4a9a87U, 0x444e89d2U, 0x623f8d16U, 0x721464daU, 0x8076588eU, 0x889173a0U, 0x4daf9a2aU, 0x59886316U); lqydB = uint[13] (0x8613432cU, 0xc260cc23U, 0x94ffc189U, 0x57937a90U, 0x3d72528aU, 0x85745777U, 0x7c98616bU, 0x44773638U, 0x79444851U, 0x9b58a256U, 0x7987967bU, 0x678c6a88U, 0x70616869U);}
    if (y==3) { hqdB = uint[10] (0xdcc13d0dU, 0xcacd9445U, 0x71aab82fU, 0x8208ca49U, 0x62037a7cU, 0x51ada2d7U, 0x5e548418U, 0x619f638eU, 0x77919dd4U, 0x79407ee0U); lqdB = uint[13] (0x487236b7U, 0x515d254eU, 0x4c846f3bU, 0x9658a077U, 0x7775678aU, 0x54904955U, 0x77868677U, 0x6f75796bU, 0x606e4f76U, 0x6f70586dU, 0x716a7761U, 0x73687d6fU, 0x6e757178U);}
    if (y==4) { hqdB = uint[10] (0xce06441eU, 0xec54ad8fU, 0x63909693U, 0x87a2be3bU, 0x6b877b00U, 0x3f1a984bU, 0x69387c8cU, 0x59756896U, 0x80189390U, 0x70cc7fb0U); lqdB = uint[13] (0x54793798U, 0x5a5f494dU, 0x7c7c864dU, 0x737b8a7dU, 0x6f80787dU, 0x60705b6fU, 0x77777a94U, 0x6d7a707cU, 0x69746c6dU, 0x62776e73U, 0x6d72727bU, 0x74716d74U, 0x6e7c6e73U);}
    if (y==4 || y==5) { hqydB = uint[10] (0x5b8386e7U, 0x76897e06U, 0x50de6100U, 0x5ae0634aU, 0x79736ee5U, 0x775566d9U, 0x5e1d6035U, 0x7fdb6206U, 0x7cb3671dU, 0x74826a90U); lqydB = uint[13] (0xb7336153U, 0x9490b86fU, 0x60b983b9U, 0x3e483d7bU, 0x7f5e775dU, 0x64686971U, 0x72687b75U, 0x80787658U, 0x6f817c8fU, 0x56755b78U, 0x6f61655eU, 0x7676765fU, 0x6c696f6aU);}
    if (y==5) { hqdB = uint[10] (0xd9254951U, 0xc9bdab08U, 0x71b8a56fU, 0x7edfbc56U, 0x5d2383acU, 0x531c9957U, 0x622d8062U, 0x5b8b7440U, 0x6ec2925bU, 0x6c9c81abU); lqdB = uint[13] (0x51825b97U, 0x577d526eU, 0x68766a6cU, 0x5f7f6f79U, 0x68836776U, 0x637a6d72U, 0x66716476U, 0x6b706f6aU, 0x757a7375U, 0x687e7081U, 0x6578657dU, 0x6c736771U, 0x6c756a74U);}
    if (y==6) { hqdB = uint[10] (0xca6b28fdU, 0xb3f3e380U, 0x5e268261U, 0x7d6ac7fbU, 0x5b256665U, 0x647084b1U, 0x5aca7efbU, 0x566b6f80U, 0x79807681U, 0x6bef74a6U); lqdB = uint[13] (0x968c7777U, 0x819a6e97U, 0x3d7b659dU, 0x67685c91U, 0x7182615eU, 0x5287796eU, 0x5d7a7385U, 0x657b6882U, 0x616c627cU, 0x666d6472U, 0x6d756f6cU, 0x6b727079U, 0x6c756475U);}
    if (y==6 || y==7) { hqydB = uint[10] (0x78e823f5U, 0xcb574bf4U, 0x9df829c2U, 0x7ea36d07U, 0xb9cabeb4U, 0x8c5ba051U, 0x61ca36beU, 0x95b3623fU, 0xa5ffb714U, 0x8dc78f7aU); lqydB = uint[13] (0x3eba8198U, 0x674fa5U, 0x63824f68U, 0x7f435f34U, 0x86a09b7fU, 0x5c4d567eU, 0x916f5a5aU, 0x5f874278U, 0x704a6559U, 0x907d9a55U, 0x65877f82U, 0x686f6b70U, 0x78747163U);}
    if (y==7) { hqdB = uint[10] (0xd0f0389cU, 0xc476ffffU, 0x503a811dU, 0x8635c0a0U, 0x515f5d9dU, 0x4b9d7a68U, 0x65e99171U, 0x41a670f6U, 0x6f0f6693U, 0x6f227946U); lqdB = uint[13] (0x9a937586U, 0x789f6b98U, 0x45a06e8eU, 0x68554e97U, 0x72975158U, 0x46947668U, 0x64797b84U, 0x5f7e7b8eU, 0x5172537bU, 0x636e4a76U, 0x736d7069U, 0x6874747eU, 0x6d715e77U);}
    if (y==8) { hqdB = uint[10] (0xcdab3b0fU, 0xb0e9e0cbU, 0x5d967edeU, 0x7b2fbe56U, 0x5af771e0U, 0x5db1872aU, 0x63157226U, 0x59d0764fU, 0x6aae7b15U, 0x70a07044U); lqdB = uint[13] (0x8e848362U, 0x74a27aa0U, 0x458458a0U, 0x646e547aU, 0x6e756a6fU, 0x6078717bU, 0x6076697eU, 0x6a75607aU, 0x696c6f71U, 0x6c787571U, 0x6b756b79U, 0x68726a7aU, 0x71767170U);}
    if (y==8 || y==9) { hqydB = uint[10] (0x6f010000U, 0xced82a4cU, 0xbe5a2044U, 0x99176edaU, 0xa2b9a673U, 0x80ef7e7cU, 0x689b382fU, 0x9b015de0U, 0xa7e8ae68U, 0x8462822fU); lqydB = uint[13] (0x58aa6d94U, 0x2e5c5091U, 0x6c6c524fU, 0x8e4f7b4cU, 0x6e818888U, 0x705a6465U, 0x7c797672U, 0x76745e68U, 0x756b697aU, 0x7075746cU, 0x6d686f71U, 0x73766e70U, 0x6f6b6968U);}
    if (y==9) { hqdB = uint[10] (0xd13b5941U, 0xc2a8eb07U, 0x54027d5bU, 0x7d97ba2fU, 0x5b9c76b6U, 0x445e82dbU, 0x72af634dU, 0x576f75f2U, 0x5eed7cf5U, 0x722e734eU); lqdB = uint[13] (0x86778f56U, 0x7ea68b95U, 0x5791559eU, 0x61684d74U, 0x716e6a6eU, 0x6d7f6a7dU, 0x6b786c7eU, 0x68756582U, 0x616c6a72U, 0x6f776b72U, 0x6f706b79U, 0x67747077U, 0x70747273U);}
    if (y==10) { hqdB = uint[10] (0xc1698c0bU, 0xcee6dcf5U, 0x404796ddU, 0x7729a2e4U, 0x6dcb8a98U, 0x37c18ed1U, 0x722c611fU, 0x5a5a7130U, 0x5f637d59U, 0x74488186U); lqdB = uint[13] (0x73639361U, 0x9d8a9590U, 0x5b9c62abU, 0x61625384U, 0x766d648aU, 0x7893617dU, 0x6b8b6f76U, 0x72895d64U, 0x5b846d88U, 0x676a5186U, 0x72756564U, 0x6b737179U, 0x72766077U);}
    if (y==10 || y==11) { hqydB = uint[10] (0x67661516U, 0xbe6c2d80U, 0x912c3a36U, 0x805b74e8U, 0xa63a9d88U, 0x6ffe8b06U, 0x52834533U, 0x9d7666f6U, 0xacfd8459U, 0xa25ca36dU); lqydB = uint[13] (0x689a31ccU, 0x10582c87U, 0x42515167U, 0x893f772cU, 0x7e9ab670U, 0x7547458aU, 0x9775764dU, 0x626c3a81U, 0x7d506d5aU, 0x83809f62U, 0x6782857eU, 0x70716970U, 0x7374766cU);}
    if (y==11) { hqdB = uint[10] (0xdc8676d5U, 0xc979b6c9U, 0x59229fb7U, 0x66a2a433U, 0x604083bcU, 0x48138e95U, 0x663c6e72U, 0x5be26d01U, 0x5fb18baaU, 0x67bb72a2U); lqdB = uint[13] (0x666f9861U, 0x828c8680U, 0x67875ba2U, 0x5c6a4e85U, 0x75696d8cU, 0x7f855e83U, 0x65826971U, 0x65765966U, 0x6a7a6985U, 0x6e6f6586U, 0x6a74686aU, 0x74726971U, 0x6e736777U);}
    if (y==12) { hqdB = uint[10] (0xdb39683aU, 0xc027c3c0U, 0x572d921aU, 0x7407ae55U, 0x5af47e28U, 0x4c4c8c83U, 0x69c56ebdU, 0x59cb72f2U, 0x60a78b90U, 0x6fc76f04U); lqdB = uint[13] (0x6d768a5fU, 0x75987f81U, 0x61815991U, 0x5e75557cU, 0x6e757078U, 0x79796b81U, 0x66746377U, 0x65735f77U, 0x6d726b77U, 0x72796d7bU, 0x6b726777U, 0x6a746b73U, 0x6f747074U);}
    if (y==12 || y==13) { hqydB = uint[10] (0x7be41564U, 0xcdff469dU, 0xaa7d4594U, 0x840175e5U, 0x994c9f4cU, 0x76d57938U, 0x6e8e404eU, 0x98496b63U, 0xa8e69a38U, 0x7c728fceU); lqydB = uint[13] (0x6897478bU, 0x485b536eU, 0x7476635dU, 0x7f53725aU, 0x7b7f8a82U, 0x6d585e6fU, 0x7d6f7a72U, 0x7b7f6164U, 0x6a706c8aU, 0x656f6c6bU, 0x74657367U, 0x7379736dU, 0x6b6b6e6aU);}
    if (y==13) { hqdB = uint[10] (0xd6a64e47U, 0xba4cce43U, 0x61188e48U, 0x790fb85bU, 0x5a347c04U, 0x56098e06U, 0x65667411U, 0x5b6d760fU, 0x65e28647U, 0x6f6c72c9U); lqdB = uint[13] (0x747c7c6bU, 0x7297748bU, 0x57825c93U, 0x5f75567bU, 0x6c796c74U, 0x6a786e7dU, 0x61736379U, 0x69726073U, 0x70727172U, 0x6f7d7379U, 0x6974667aU, 0x6a736975U, 0x70757171U);}

    // first coeffs
    float w1 = 0.;
    
    for( int i=0; i<HQ; i++) {
        uint q = hqd[i];
    	pos+=cmul(vec2(SH(q,0,ch),SH(q,16,ch)),vec2(cos(w1),sin(w1)));w1+=s1; 
    }
    for( int i=0; i<LQ; i++) {
        uint q = lqd[i];
    	pos+=cmul(vec2(S(q,0,cl),S(q,8,cl)),vec2(cos(w1),sin(w1)));w1+=s1; 
        pos+=cmul(vec2(S(q,16,cl),S(q,24,cl)),vec2(cos(w1),sin(w1)));w1+=s1; 
    }  
    
    // and y
    w1 = 0.;
    for( int i=0; i<HQ; i++) {
        uint q = hqyd[i];
        posy+=cmul(vec2(SH(q,0,ch),SH(q,16,ch)),vec2(cos(w1),sin(w1)));w1+=s1; 
    }
    for( int i=0; i<LQ; i++) {
        uint q = lqyd[i];
        posy+=cmul(vec2(S(q,0,cl),S(q,8,cl)),vec2(cos(w1),sin(w1)));w1+=s1; 
        posy+=cmul(vec2(S(q,16,cl),S(q,24,cl)),vec2(cos(w1),sin(w1)));w1+=s1; 
    }  
    
    // last coeffs
    float w2 = (FRAMES-1.)*s1;
    
    for( int i=0; i<HQ; i++) {
        uint q = hqdB[i];
        pos+=cmul(vec2(SH(q,0,chb),SH(q,16,chb)),vec2(cos(w2),sin(w2)));w2-=s1; 
    }
    for( int i=0; i<LQ; i++) {
        uint q = lqdB[i];
        pos+=cmul(vec2(S(q,0,clb),S(q,8,clb)),vec2(cos(w2),sin(w2)));w2-=s1; 
        pos+=cmul(vec2(S(q,16,clb),S(q,24,clb)),vec2(cos(w2),sin(w2)));w2-=s1; 
    }  
    
    // and y
    w2 = (FRAMES-1.)*s1;
    for( int i=0; i<HQ; i++) {
        uint q = hqydB[i];
        posy+=cmul(vec2(SH(q,0,chb),SH(q,16,chb)),vec2(cos(w2),sin(w2)));w2-=s1; 
    }
    for( int i=0; i<LQ; i++) {
        uint q = lqydB[i];
        posy+=cmul(vec2(S(q,0,clb),S(q,8,clb)),vec2(cos(w2),sin(w2)));w2-=s1; 
        posy+=cmul(vec2(S(q,16,clb),S(q,24,clb)),vec2(cos(w2),sin(w2)));w2-=s1; 
    }  
    
    float py = (int(fragCoord.y) & 0x1) == 0 ?  posy.x : posy.y;
    vec3 p = vec3(pos.x, py, pos.y);
    
    if(iFrame == 0) {
        fragColor = vec4(p * scale,1.0);
    } else {	    
    	fragColor = mix(vec4(p * scale,1.0), texelFetch(iChannel0, ivec2(fragCoord),0),.75);
    }
}