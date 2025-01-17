package modding;

import util.MathWrapper;
import openfl.utils.Assets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;
import hscript.Parser;
import hscript.Interp;

class HScriptRuntime
{
	public static var parser:Parser = new Parser();

	public var interp:Interp;
	public var scriptName:String = "_script";

	public function get_variables()
	{
		return interp.variables;
	}

	public function new(path:String)
	{
		scriptName = path;
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);
		interp.variables.set('math', MathWrapper);
		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if (PlayState.instance.variables.exists(name))
				result = PlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if (PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});

		execute(Assets.getText(path));
		Log.info("successfully loaded script " + path);
	}

	public function call(name:String, ?args:Array<Any>)
	{
		args ??= [];
		var func = interp.variables.get(name);
		var obj = {func: func};
		if (func != null)
			try
			{
				Reflect.callMethod(obj, obj.func, args);
			}
			catch (e:Dynamic)
			{
				Log.error('$e');
			}
	}

	public function set(field:String, value:Dynamic)
	{
		interp.variables.set(field, value);
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		parser.line = 1;
		parser.allowTypes = true;
		parser.resumeErrors = true;
		parser.allowJSON = true;
		parser.allowMetadata = true;
		
		return interp.execute(parser.parseString(codeToRun));
	}
}
