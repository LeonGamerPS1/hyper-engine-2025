package util;

import flixel.math.FlxMath;

@:publicFields
class MathWrapper
{
	static var PI(get, null):Float;
	static var NEGATIVE_INFINITY(get, null):Float;
	static var POSITIVE_INFINITY(get, null):Float;
	static var NaN(get, null):Float;

	static function get_NaN():Float
		return Math.NaN;

	static function get_PI():Float
		return Math.PI;

	static function get_NEGATIVE_INFINITY():Float
		return Math.NEGATIVE_INFINITY;

	static function get_POSITIVE_INFINITY():Float
		return Math.POSITIVE_INFINITY;

	static function abs(v:Float):Float
		return Math.abs(v);

	static function min(a:Float, b:Float):Float
		return Math.min(a, b);

	static function max(a:Float, b:Float):Float
		return Math.max(a, b);

	static function sin(v:Float):Float
		return Math.sin(v);

	static function cos(v:Float):Float
		return Math.cos(v);

	static function tan(v:Float):Float
		return Math.tan(v);

	static function asin(v:Float):Float
		return Math.asin(v);

	static function acos(v:Float):Float
		return Math.acos(v);

	static function atan(v:Float):Float
		return Math.atan(v);

	static function atan2(y:Float, x:Float):Float
		return Math.atan2(y, x);

	static function exp(v:Float):Float
		return Math.exp(v);

	static function log(v:Float):Float
		return Math.log(v);

	static function pow(v:Float, exp:Float):Float
		return Math.pow(v, exp);

	static function sqrt(v:Float):Float
		return Math.sqrt(v);

	static function round(v:Float):Int
		return Math.round(v);

	static function floor(v:Float):Int
		return Math.floor(v);

	static function ceil(v:Float):Int
		return Math.ceil(v);

	static function random():Float
		return Math.random();

    static function lerp(a:Float,b:Float,r:Float):Float
		return FlxMath.lerp(a,b,r);

	static function isFinite(f:Float):Bool
		return Math.isFinite(f);


	static function isNaN(f:Float):Bool
		return Math.isNaN(f);
}
