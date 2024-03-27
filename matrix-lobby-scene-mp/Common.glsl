#define HIGHQUALITY 1
#define RENDERDEBRIS 1
#define REFLECTIONS 1

#define MARCHSTEPS 90
#define MARCHSTEPSREFLECTION 30
#define DEBRISCOUNT 8

#define BPM             (140.0)
#define STEP            (4.0 * BPM / 60.0)
#define ISTEP           (1./STEP)
#define STT(t)			(t*(60.0/BPM))