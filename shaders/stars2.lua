-- Playground URL
-- http://goo.gl/eNGTQ2

local kernel = {}

kernel.language = 'glsl'
kernel.category = 'generator'
kernel.name = 'stars'

kernel.fragment =
[[
#define iterations 15
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

#define zoom   0.900
#define tile   0.850
#define speed  0.010

#define brightness 0.001
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    //get coords and direction
	//P_UV vec2 uv = fragCoord.xy/iResolution.xy-.5;
    //uv.y *=iResolution.y/iResolution.x;
    P_UV vec2 uv = texCoord.xy;

	P_UV vec3 dir = vec3(uv*zoom, 1.);
	P_UV float time = CoronaTotalTime * speed + .25;

	//mouse rotation
	P_UV float a1=.5;
	P_UV float a2=.8;
	P_UV mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
	P_UV mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
	dir.xz*=rot1;
	dir.xy*=rot2;
	P_UV vec3 from=vec3(1.,.5,0.5);
	from+=vec3(.0,-time,-.0);
	from.xz*=rot1;
	from.xy*=rot2;

	//volumetric rendering
	P_UV float s=0.1,fade=1.;
	P_UV vec3 v=vec3(0.);
	for (int r=0; r<volsteps; r++) {
		P_UV vec3 p=from+s*dir*.5;
		p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
		P_UV float pa,a=pa=0.;
		for (int i=0; i<iterations; i++) {
			p=abs(p)/dot(p,p)-formuparam; // the magic formula
			a+=abs(length(p)-pa); // absolute sum of average change
			pa=length(p);
		}
		P_UV float dm=max(0.,darkmatter-a*a*.001); //dark matter
		a*=a*a; // add contrast
		if (r>6) fade*=1.-dm; // dark matter, don't render near
		//v+=vec3(dm,dm*.5,0.);
		v+=fade;
		v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
		fade*=distfading; // distance fading
		s+=stepsize;
	}
	v=mix(vec3(length(v)),v,saturation); //color adjust
    return CoronaColorScale(vec4(v*.01,1.));
}
]]

return kernel