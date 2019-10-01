// Portal - iOS AR. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/lldcR8
//
// This is an experiment to create an "AR shader" by implementing the mainVR-function and 
// using the WebCam texture as background. If you view this shader with the Shadertoy iOS 
// app[1], you can walk around and enter the portal.
//
// If you don't have an iOS device (or if you don't have the app installed) you can have a 
// look at this screen capture to see the shader in action: https://youtu.be/IzeeoD0e6Ow.
//

#define PI 3.14159265359
#define PORTAL_POS vec3(0.05,0.9, 0.02)
#define PORTAL_SIZE vec3(0.45,0.75, 0.)
#define START_OFFSET vec3(0.,0.4,1.2)
#define PORTAL_BORDER vec3(0.15,0.15, 0.)
#define PILLAR_WIDTH_HALF .15
#define PILLAR_SPACING 2.1
#define CEILING_HEIGHT 2.5

const int N = 30;

#define NUM_VERTS 4
const vec3[] verts = vec3[] (
        vec3(PORTAL_SIZE.x, -PORTAL_SIZE.y, 0) + PORTAL_POS,
        vec3(-PORTAL_SIZE.x, -PORTAL_SIZE.y, 0) + PORTAL_POS,
        vec3(-PORTAL_SIZE.x, PORTAL_SIZE.y, 0) + PORTAL_POS,
        vec3(PORTAL_SIZE.x, PORTAL_SIZE.y, 0) + PORTAL_POS);

float cosine_sine_power_integral_sum(float theta, float cos_theta, float sin_theta,
	int n, float a, float b) {
	float f = a*a + b*b;
	float g = a*cos_theta + b*sin_theta;
	float gsq = g*g;
	float asq = a*a;
	float h = a*sin_theta - b*cos_theta;
	float T = theta, Tsum;
	float l = g*h, l2 = b*a;
	int start = 0;

	Tsum = T;
	for (int i = 2; i <= N - 1; i += 2) {
		T = (l + l2 + f*(float(i) - 1.)*T) * (1. / float(i));
		l *= gsq;
		l2 *= asq;
		Tsum += T;
	}
	return Tsum;
}

float P(float theta, float a) {
	return 1.0 / (1.0 + a * theta * theta);
}

float I_org(float theta, float c, float n) {
	float cCos = c * cos(theta);
	return (pow(cCos, n + 2.) - 1.0) / (cCos * cCos - 1.);
}

float evaluateXW(float c, float n) {
	return PI / 4. * pow(1. - pow(c - c / (n - 1.), 2.5), 0.45);
}

float shd_edge_contribution(vec3 v0, vec3 v1, vec3 n, int e) {
	float f;
	float cos_theta, sin_theta;
	vec3 q = cross(v0, v1); //ni
	sin_theta = length(q);
	q = normalize(q);
	cos_theta = dot(v0, v1);

	if (e == 1) {
		f = acos(cos_theta);
	} else {
		vec3 w;
		float theta;
		theta = acos(cos_theta);
		w = cross(q, v0);
		f = cosine_sine_power_integral_sum(theta, cos_theta, sin_theta, e - 1, dot(v0, n), dot(w, n));
	}
	return f * dot(q, n);
}


void seg_plane_intersection(vec3 v0, vec3 v1, vec3 n, out vec3 q) {
	vec3 vd;
	float t;
	vd = v1 - v0;
	t = -dot(v0, n) / (dot(vd, n));
	q = v0 + t * vd;
}

float shd_polygonal(vec3 p, vec3 n, bool spc) {
	int i, i1;
	int J = 0;
	float sum = 0.;
	vec3 ui0, ui1;
	vec3 vi0, vi1;
	int belowi0 = 1, belowi1 = 1;
    
	for (int j = 0; j < NUM_VERTS; j++) {
		vec3 u;
		u = verts[j] - p;
		if (dot(u, n) >= 0.0) {
			ui0 = u;
			vi0 = u;
			vi0 = normalize(vi0);
			belowi0 = 0;
			J = j;
			break;
		}
	}

    if (J >= NUM_VERTS) {
        return 0.;
    } else {
        i1 = J;
        for (int i = 0; i < NUM_VERTS; i++) {
            i1++;
            if (i1 >= NUM_VERTS) i1 = 0;

            ui1 = verts[i1] - p;
            belowi1 = int(dot(ui1, n) < 0.);

            if (belowi1 == 0) {
                vi1 = ui1;
                vi1 = normalize(vi1);
            }

            if (belowi0 != 0 && belowi1 == 0) {
                vec3 vinter;
                seg_plane_intersection(ui0, ui1, n, vinter);
                vinter = normalize(vinter + 0.01);
                sum += shd_edge_contribution(vi0, vinter, n, 1);
                vi0 = vinter;
            }
            else if (belowi0 == 0 && belowi1 != 0) {
                seg_plane_intersection(ui0, ui1, n, vi1);
                vi1 = normalize(vi1);
            }
            int K = spc ? N : 1;

            if (belowi0 == 0 || belowi1 == 0) sum += shd_edge_contribution(vi0, vi1, n, K);


            ui0 = ui1;
            vi0 = vi1;
            belowi0 = belowi1;
        }
	}
	return abs(sum) / (2. * PI);
}
