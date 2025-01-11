package effects.shaders;

import flixel.system.FlxAssets;
import openfl.Assets;
import flixel.addons.display.FlxRuntimeShader;

class IDK extends FlxAssets.FlxShader {
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

/*
  Written by Alan Wolfe
  http://demofox.org/
  http://blog.demofox.org/

  More info here:
  http://blog.demofox.org/2012/06/18/diy-synth-3-sampling-mixing-and-band-limited-wave-forms/

  There's probably some better ways to do this without so much branching logic, but
  doing it this way for clarity.  If you know of better branchless ways, feel free to
  comment!!
*/

#define PI						3.14159265359
#define TWO_PI 					(2.0 * PI)
#define TWO_OVER_PI     		(2.0 / PI)
#define FOUR_OVER_PI   			(4.0 / PI)
#define EIGHT_OVER_PI_SQUARED 	(8.0 / (PI * PI))

// the frequency of the tone
#define TONE_FREQUENCY 	440.0  //A4

// how long each tone plays, in seconds
#define TONE_LENGTH 2.0

// how long to fade in and out each wave form
#define ENVELOPE_SIZE 0.2

// how many harmonics (sine waves) for each bandlimited wave form
#define NUM_HARMONICS_TRIANGLE	3
#define NUM_HARMONICS_SAW 		9
#define NUM_HARMONICS_SQUARE 	11

//========================= BANDLIMITED WAVE FORMS

float makeTriangleBL(float time)
{
    float value = 0.0;
    
    float signflip = 1.0;
    
    for (int index = 0; index < NUM_HARMONICS_TRIANGLE; ++index) {
        float harmonicIndex = float(index) * 2.0 + 1.0;
        value += sin(TONE_FREQUENCY*TWO_PI*time*harmonicIndex) / (harmonicIndex * harmonicIndex) * signflip;
        signflip *= -1.0;
    }
    
    return value * EIGHT_OVER_PI_SQUARED;
}


float makeSawBL(float time)
{
    float value = 0.0;
    
    for (int index = 1; index <= NUM_HARMONICS_SAW; ++index) {
        float harmonicIndex = float(index);
        value += sin(TONE_FREQUENCY*TWO_PI*time*harmonicIndex) / harmonicIndex;
    }
    
    return value * TWO_OVER_PI;
}

float makeSquareBL(float time)
{
    float value = 0.0;
    
    for (int index = 0; index < NUM_HARMONICS_SQUARE; ++index) {
        float harmonicIndex = float(index) * 2.0 + 1.0;
        value += sin(TONE_FREQUENCY*TWO_PI*time*harmonicIndex) / harmonicIndex;
    }
    
    // the 0.9 shouldn't be needed, but for some reason the amplitude seems wrong
    // without it...
    return value * FOUR_OVER_PI * 0.9;
}

//========================= WAVE FORMS

float makeTriangle(float time)
{
    return abs(fract(time * TONE_FREQUENCY)-.5)*4.0-1.0;
}

float makeSaw(float time)
{
    return 2.0 - (mod(time * TONE_FREQUENCY, 1.0) * 2.0) - 1.0;
}

float makeSquare(float time)
{
    return step(fract(time * TONE_FREQUENCY), 0.5)*2.0-1.0;
}

//========================= DRIVER CODE

float makeSound(float time)
{   
    // figure out how much to scale the volume to account for envelope
    // on the front and back of each wave form    
    float noteTime = mod(iTime, TONE_LENGTH);
    float envelope = 1.0;
    if (noteTime < ENVELOPE_SIZE)
        envelope = noteTime / ENVELOPE_SIZE;
    else if (noteTime > (TONE_LENGTH - ENVELOPE_SIZE))
        envelope = 1.0 - ((noteTime - (TONE_LENGTH - ENVELOPE_SIZE)) / ENVELOPE_SIZE);
    
    // play the apropriate wave form based on time
    float mode = mod(iTime / TONE_LENGTH, 6.0);
    if (mode > 5.0)
        return makeSquareBL(time) * envelope;
    else if (mode > 4.0)
        return makeSquare(time) * envelope;    
    else if (mode > 3.0)
        return makeSawBL(time) * envelope;  
    else if (mode > 2.0)
        return makeSaw(time) * envelope;
    else if (mode > 1.0)
        return makeTriangleBL(time) * envelope;        
    else
        return makeTriangle(time) * envelope;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 percent = (fragCoord.xy / iResolution.xy);
    percent.x /= 256.0;
    percent.y = (percent.y) * 2.2 - 1.1;
    
    // calculate a time offset to show the wave form moving across the screen
    float timeOffset = mod(iTime / 200.0, TONE_LENGTH);
    float value = makeSound(percent.x + timeOffset);

    if (abs(percent.y-value) < 0.01)
        fragColor = vec4(0.0,1.0,0.0,1.0);
    else
    {
        float value2 = makeSound(percent.x + timeOffset - 0.00001);
        
        if ((percent.y > value && percent.y < value2) ||
            (percent.y < value && percent.y > value2))
        	fragColor = vec4(0.0,1.0,0.0,1.0);
       	else
			fragColor = vec4(0.0,0.0,0.0,1.0);
    }
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}
    ")
    public  function new() {
        super();
        iTime.value = [0.0];
    }
    public function update(elapsed:Float) {
        iTime.value[0] += [elapsed][0];
    }
}