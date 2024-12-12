package;

import flixel.FlxG;

class Mat
{
	public static inline function fpsLerp(base:Float, target:Float, ratio:Float):Float
	{
		var h:Float = -(1 / 60) / logBase(2, 1 - ratio);
		return target + (base - target) * Math.pow(2, -FlxG.elapsed / h);
	}

	public static inline function logBase(base:Float, value:Float):Float
	{
		return Math.log(value) / Math.log(base);
	}
}
