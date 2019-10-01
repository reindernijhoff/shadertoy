// Changes:
// Applying P_Malins comment (C *= T*V(1.2,1.02,.66)+(y+N).y*V(1,1.4,2)/8.;) -> 713 char
// I don't know why, but I could remove the max(0.,dot at the lighting equation -> 714 char
// Make all arguments global (inspired by P_Malin)
// Applying FabriceNeyret2's comment (identity in calculation of D)

#define V vec3
#define Q normalize
#define F for(int i=0;i<64;i++)

#define c F{n=y,T=P.y,m=-2;F l=length(q=P-V(i/5-2,s,i-2-i/5*5))-s,i<28&&l<T?T=l,m=i/2,n=Q(q):q,s+=g*=-1.;P+=T*d;}

void mainImage( out vec4 f, vec2 p ) {
	int m; float T, s=.4, g=.15, l,h=.5;
    V C, d, D, N, n, q=iResolution, y = V(0,1,0),
    P = V( .851, 2, -2.8768 );
    
    D = d = mat3( d = Q(cross(N = -Q(.2*y+P),y)),cross(d,N), N ) * Q(V(p-q.xy*h,q.y));
    
    c
    
    N=n,q=mod(ceil(P),2.),C=P*P,
	
    C = m<0?
    	smoothstep( 0.,h,max(C.x,C.z)<2.25?length(fract(P.xz+h)-h):2.)*        
       	V(q.x==q.z?.4:h*texture( iChannel0,.1*P.xz).x) : V(100-8*m,3*m,6*m)*.01;     

	d = Q(V(-6,7,-5));
    P += 0.01*d;
    
    c
    
    T = m<-1?dot(N,d):0.;    
	
    f=sqrt(C*(T*V(1.2,1.02,.66)+(y+N).y*V(1,1.4,2)/8.)+pow(max(0.,dot(reflect( D, N ), d)),16.)*T).xyzz;
}

/*

#define V vec3
#define Q normalize

V C, P, n, q=iResolution, y = V(0,1,0);
float t, m, T, M, s, g=.15, l;

void c( V o, V d ) {
    t=.01,s=.4;
    for( int i=0; i<64; i++ ) {
		P=o+d*t,
	    n = y,
        T = P.y, M = -2.;        
        for( int i=0;i<28;i++) {
            l=length(q = P - V( i/5-2,s, i-2-i/5*5)) - s;
            if( l < T ) 
                T = l, M = float(i/2), n = Q(q);
            s += g*=-1.;
		}
        t += T;
	    m = M;
    }
}

void mainImage( out vec4 f, vec2 p ) {
    V o = V( cos(5.),1,sin(5.) )*3.-y,
        N = -Q(.2*y+o),
        d = Q(cross(N,y)),        
		L = Q(V(-6,7,-5));
    
    c(o,d = mat3( d,cross(d,N), N ) * Q(V((p+p-q.xy)/q.y,2)));  
    
    N=n,q=ceil(P),C=abs(P),
	
    C = m>=0.?V(-8,3,6)*.01*m+y.yxx:
    	smoothstep( 0.,.5,length(fract(P.xz+.5)-.5)+step(1.5,max(C.x,C.z)))*        
       	V(mod(q.x+q.z,2.)<.5?.4:.5*texture( iChannel0,.1*P.xz).x);     
    
    c(P, L);
    
    t = max(0.,dot(N, L)) * step(m,-.5);    
	
    C *= t*V(1.2,1.02,.66)+(1.+N.y)*V(1,1.4,2)/8.;
    
    f=sqrt(C.xyzz+pow(max(0.,dot(reflect( d, N ), L)),16.)*t);
}

*/