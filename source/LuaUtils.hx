package;

import Type.ValueType;
import flixel.FlxCamera;
import openfl.display.BlendMode;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween.FlxTweenType;

using StringTools;

class LuaUtils {
	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any {
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1) {
			var target:Dynamic = null;
			if (PlayState.instance.variables.exists(splitProps[0])) {
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if (retVal != null)
					target = retVal;
			} else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}

		if (allowMaps && isMap(instance)) {
			// trace(instance);
			return instance.get(variable);
		}

		if (PlayState.instance.variables.exists(variable)) {
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if (retVal != null)
				return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length - 1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	public static function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length - 1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			switch (Type.typeof(coverMeInPiss)) {
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return coverMeInPiss.get(killMe[killMe.length - 1]);
				default:
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
			};
		}
		switch (Type.typeof(leArray)) {
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return leArray.get(variable);
			default:
				return Reflect.getProperty(leArray, variable);
		};
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any {
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1) {
			var target:Dynamic = null;
			if (PlayState.instance.variables.exists(splitProps[0])) {
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if (retVal != null)
					target = retVal;
			} else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if (i >= splitProps.length - 1) // Last array
					target[j] = value;
				else // Anything else
					target = target[j];
			}
			return target;
		}

		if (allowMaps && isMap(instance)) {
			// trace(instance);
			instance.set(variable, value);
			return value;
		}

		if (PlayState.instance.variables.exists(variable)) {
			PlayState.instance.variables.set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function isMap(variable:Dynamic) {
		// trace(variable);
		if (variable.exists != null && variable.keyValueIterator != null)
			return true;
		return false;
	}

	public static inline function getTargetInstance() {
		return PlayState.instance;
	}

	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic {
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		var end = split.length;
		if (getProperty)
			end = split.length - 1;

		for (i in 1...end)
			obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic {
		switch (objectName) {
			case 'this' | 'instance' | 'game':
				return PlayState.instance;

			default:
				var obj:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
				if (obj == null)
					obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				return obj;
		}
	}

	public static function getBuildTarget():String {
		#if windows
		return 'windows';
		#elseif linux
		return 'linux';
		#elseif mac
		return 'mac';
		#elseif html5
		return 'browser';
		#elseif android
		return 'android';
		#elseif switch
		return 'switch';
		#else
		return 'unknown';
		#end
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>) {
		for (type in types) {
			if (Std.isOfType(value, type))
				return true;
		}
		return false;
	}

	// buncho string stuffs
	public static function getTweenTypeByString(?type:String = '') {
		switch (type.toLowerCase().trim()) {
			case 'backward':
				return FlxTweenType.BACKWARD;
			case 'looping' | 'loop':
				return FlxTweenType.LOOPING;
			case 'persist':
				return FlxTweenType.PERSIST;
			case 'pingpong':
				return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.ONESHOT;
	}

	public static function getTweenEaseByString(?ease:String = '') {
		switch (ease.toLowerCase().trim()) {
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static function blendModeFromString(blend:String):BlendMode {
		switch (blend.toLowerCase().trim()) {
			case 'add':
				return ADD;
			case 'alpha':
				return ALPHA;
			case 'darken':
				return DARKEN;
			case 'difference':
				return DIFFERENCE;
			case 'erase':
				return ERASE;
			case 'hardlight':
				return HARDLIGHT;
			case 'invert':
				return INVERT;
			case 'layer':
				return LAYER;
			case 'lighten':
				return LIGHTEN;
			case 'multiply':
				return MULTIPLY;
			case 'overlay':
				return OVERLAY;
			case 'screen':
				return SCREEN;
			case 'shader':
				return SHADER;
			case 'subtract':
				return SUBTRACT;
		}
		return NORMAL;
	}

	public static function cameraFromString(cam:String):FlxCamera {
		switch (cam.toLowerCase()) {
			case 'camhud' | 'hud':
				return PlayState.instance.camHUD;
		}
		return PlayState.instance.camera;
	}
}
