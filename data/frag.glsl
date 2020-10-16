uniform sampler2D[2] velocity;
uniform sampler2D src;
uniform int mode;
uniform float dt;

uniform const vec3 lightDir = normalize(vec3(-1.0,-1.0,0.0));

vec2 wrap(vec2 coord) {
	vec2 res = textureSize(src,0);
	if(coord.x<0) { coord.x+=res.x; } else if(coord.x>=res.x) { coord.x-=res.x; }
	if(coord.y<0) { coord.y+=res.y; } else if(coord.y>=res.y) { coord.y-=res.y; }
	return coord;
}

vec4 getSample(sampler2D src, vec2 coord) {
	//return texelFetch(src,ivec2(wrap(coord)),0);
	return texelFetch(src,ivec2(coord),0);
}

float floatFromSample(sampler2D src, vec2 coord) {
	vec4 value = getSample(src,coord);
	return uintBitsToFloat(
		(uint(value.a*255.)<<(8*3))+
		(uint(value.r*255.)<<(8*2))+
		(uint(value.g*255.)<<(8*1))+
		(uint(value.b*255.)<<(8*0)));
}

float lerpFloatFromSample(sampler2D src, vec2 coord) {
	vec2 icoord = floor(coord);
	vec2 lcoord = coord-icoord;
	vec2 offset = vec2(0.0,1.0);
	return mix(
		mix(floatFromSample(src,coord+offset.xx),
			floatFromSample(src,coord+offset.yx),lcoord.x),
		mix(floatFromSample(src,coord+offset.xy),
			floatFromSample(src,coord+offset.yy),lcoord.x),lcoord.y);
}

vec4 sampleFromFloat(float value) {
	uint bits = floatBitsToUint(value);
	return vec4(
		float((bits>>(8*2))&0xFF)/255.,
		float((bits>>(8*1))&0xFF)/255.,
		float((bits>>(8*0))&0xFF)/255.,
		float((bits>>(8*3))&0xFF)/255.);
}

float getLagrangian(sampler2D src, vec2 coord) {
	float lagrangian = 0.0;
	for(int i=-1;i<=1;i++) {
	for(int j=-1;j<=1;j++) {
		float factor = ((i!=0||j!=0)?(i!=0&&j!=0)?0.05:0.2:-1.0);
		lagrangian += floatFromSample(src,coord+vec2(float(i),float(j)))*factor;
	}
	}
	return lagrangian;
}

vec2 getGradient(sampler2D src, vec2 coord) {
	vec2 gradient = vec2(0.0);
	for(int i=-1;i<=1;i++) {
	for(int j=-1;j<=1;j++) {
		if(i!=0 || j!=0) {
			float factor = (i!=0&&j!=0)?0.05:0.2;
			gradient += floatFromSample(src,coord+vec2(float(i),float(j)))*vec2(i,j)*factor;
		}
	}
	}
	return gradient;
}

vec3 getNormal(sampler2D src, vec2 coord) {
	return normalize(vec3(getGradient(src,coord)*10.0,1.0));
}

// from "sam hocevar" off stackoverflow
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
	vec2 coord = gl_FragCoord.xy-vec2(0.5);
	switch(mode) {
		case 0: { // diffuse
			gl_FragColor = sampleFromFloat(floatFromSample(src,coord)+getLagrangian(src,coord)*dt);
		} break;
		case 1: { // advect
			vec2 out_coord = coord-dt*vec2(
				floatFromSample(velocity[0],coord),
				floatFromSample(velocity[1],coord));
			gl_FragColor = sampleFromFloat(lerpFloatFromSample(src,out_coord));
		} break;
		case 2: { // calculate pressure
			float pressure = 0.0;
			pressure += (floatFromSample(velocity[0],coord+vec2(1.0,0.0))-
						 floatFromSample(velocity[0],coord-vec2(1.0,0.0)));
			pressure += (floatFromSample(velocity[1],coord+vec2(0.0,1.0))-
						 floatFromSample(velocity[1],coord-vec2(0.0,1.0)));
			gl_FragColor = sampleFromFloat((floatFromSample(src,coord)+pressure*dt));
		} break;
		case 3: { // subtract pressure gradient x
			float force = (floatFromSample(src,coord+vec2(1.0,0.0))-
						   floatFromSample(src,coord-vec2(1.0,0.0)));
			gl_FragColor = sampleFromFloat(floatFromSample(velocity[0],coord)+force*dt);
		} break;
		case 4: { // subtract pressure gradient y
			float force = (floatFromSample(src,coord+vec2(0.0,1.0))-
						   floatFromSample(src,coord-vec2(0.0,1.0)));
			gl_FragColor = sampleFromFloat(floatFromSample(velocity[1],coord)+force*dt);
		} break;
		case 5: { // calculate vorticity
			float vorticity = 0.0;
			vorticity += (floatFromSample(velocity[1],coord+vec2(1.0,0.0))-
						 floatFromSample(velocity[1],coord-vec2(1.0,0.0)));
			vorticity -= (floatFromSample(velocity[0],coord+vec2(0.0,1.0))-
						 floatFromSample(velocity[0],coord-vec2(0.0,1.0)));
			gl_FragColor = sampleFromFloat(floatFromSample(src,coord)+vorticity*dt);
		} break;
		case 6: { // apply vorticity x
			/*
			float force = (floatFromSample(src,coord+vec2(0.0,1.0))-
						   floatFromSample(src,coord-vec2(0.0,1.0)));
			gl_FragColor = sampleFromFloat(floatFromSample(velocity[0],coord)+force*dt);
			*/
			gl_FragColor = getSample(velocity[0],coord);
			/*
			vec2 force = textureSize(src,0).xy/2.0-coord+vec2(0.5);
			force = (0.2*force+vec2(force.y,-force.x))/(dot(force,force)/100.0+1.0)*floatFromSample(src,coord);
			gl_FragColor = sampleFromFloat(floatFromSample(velocity[0],coord)+force.x*dt);
			*/
		} break;
		case 7: { // apply vorticity y
			/*
			float force = (floatFromSample(src,coord+vec2(1.0,0.0))-
						   floatFromSample(src,coord-vec2(1.0,0.0)));
			gl_FragColor = sampleFromFloat(floatFromSample(velocity[1],coord)-force*dt);
			*/
			//float buoyancy = max(0.0,getLagrangian(src,coord));
			float buoyancy = floatFromSample(src,coord);
			gl_FragColor = sampleFromFloat(floatFromSample(velocity[1],coord)+buoyancy*dt);
			/*
			vec2 force = textureSize(src,0).xy/2.0-coord+vec2(0.5);
			force = (0.2*force+vec2(force.y,-force.x))/(dot(force,force)/100.0+1.0)*floatFromSample(src,coord);
			gl_FragColor = sampleFromFloat(floatFromSample(velocity[1],coord)+force.y*dt);
			*/
		} break;
		case 8: { // render
			/*
			vec3 velocityContribution = abs(vec3(
				floatFromSample(velocity[0],coord),0.0,
				floatFromSample(velocity[1],coord)))*0.1;
			gl_FragColor = vec4(velocityContribution+vec3(floatFromSample(src,coord)),1.0);
			*/
			
			vec3 lightReflect = -vec3(1.0,0.0,1.0)*abs(dot(getNormal(src,coord),lightDir));
			gl_FragColor = vec4(abs(vec3(
				floatFromSample(velocity[0],coord),
				floatFromSample(src,coord),
				floatFromSample(velocity[1],coord)))*vec3(0.02,1.0,0.02)+lightReflect,1.0);
			
			/*
			float value = floatFromSample(src,coord)*0.1;
			gl_FragColor = vec4(hsv2rgb(vec3(value*0.1,1.0,value)),1.0);
			*/
		} break;
		case 9: { // clear
			gl_FragColor = sampleFromFloat(0.0);
		} break;
	}
}
