uniform sampler2D src;
uniform vec2 mouse;
uniform float r;
uniform float value;

vec4 getSample(vec2 coord) {
	return texture(src,coord/textureSize(src,0));
}

float floatFromSample(vec2 coord) {
	vec4 value = getSample(coord);
	return intBitsToFloat(
		(int(value.a*255.)<<(8*3))+
		(int(value.r*255.)<<(8*2))+
		(int(value.g*255.)<<(8*1))+
		(int(value.b*255.)<<(8*0)));
}

vec4 sampleFromFloat(float value) {
	int bits = floatBitsToInt(value);
	return vec4(
		float((bits>>(8*2))&0xFF)/255.,
		float((bits>>(8*1))&0xFF)/255.,
		float((bits>>(8*0))&0xFF)/255.,
		float((bits>>(8*3))&0xFF)/255.);
}

void main() {
	vec2 coord = gl_FragCoord.xy;
	if(length(coord-mouse)<=r) {
		gl_FragColor = sampleFromFloat(value);
	} else {
		gl_FragColor = sampleFromFloat(floatFromSample(coord));
	}
}
