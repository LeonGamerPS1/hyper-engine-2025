package ume.internal.shaders;

import flixel.system.FlxAssets.FlxShader;

class OutlineShader extends FlxShader
{
	@:glFragmentSource("
    // Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform)
	{
		return color;
	}
	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}
	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables which is empty, they need just to avoid crashing shader
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;


void mainImage(out vec4 result, in vec2 fragCoord)
{
    float r = min(iResolution.x, iResolution.y);
    
	vec2 uv = fragCoord / r;
    uv.x /= 8.0;
    uv.y = 1.0 - uv.y;
    
    vec3 c = texture(iChannel0, uv).rgb;
    
    float a = texture(iChannel0, uv).a;
    bool i = bool(step(0.5, a) == 1.0);
    
    const int md = 20;
    const int h_md = md / 2;
    
    float d = float(md);
    
    for (int x = -h_md; x != h_md; ++x)
    {
        for (int y = -h_md; y != h_md; ++y)
        {
            vec2 o = vec2(float(x), float(y));
            vec2 s = (fragCoord + o) / r;
    		s.x /= 8.0;
    		s.y = 1.0 - s.y;
            
            float o_a = texture(iChannel0, s).a;
            bool o_i = bool(step(0.5, o_a) == 1.0);
            
            if (!i && o_i || i && !o_i)
                d = min(d, length(o));
        }
    }
    
    d = clamp(d, 0.0, float(md)) / float(md);
    
    if (i)
        d = -d;
    
    d = d * 0.5 + 0.5;
    d = 1.0 - d;
    
    
    float border_fade_outer = 0.1;
    float border_fade_inner = 0.01;
    float border_width = 0.25;
    vec3 border_color = vec3(1.0, 0.0, 0.0);
    
    float outer = smoothstep(0.5 - (border_width + border_fade_outer), 0.5, d);
    
    vec3 temp = vec3(0.0, 0.0, 0.0);
    vec4 border = mix(vec4(temp, 0.0), vec4(border_color, 1.0), outer);
    
    float inner = smoothstep(0.5, 0.5 + border_fade_inner, d);
    
    vec4 color = mix(border, vec4(c, 1.0), inner);
    
    result = color;
}


void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}
    ")
	public function new()
	{
		super();
	}
}