package modding;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxSprite;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.Constraints;
import haxe.DynamicAccess;
import haxe.Exception;
import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.Types;
import openfl.Assets as OpenFlAssets;
import lime.app.Application;

typedef State = cpp.RawPointer<Lua_State>;

class LuaScript {
	private static var callbacks:Map<String, Function> = [];


	public var closed:Bool = false;

	private var vm:State;

	public var scriptName:String = "_script";

	public function new(file:String) {
		vm = LuaL.newstate();

		LuaL.openlibs(vm);

		Lua.register(vm, "print", cpp.Function.fromStaticFunction(print));
		this.scriptName = file;
		setVariables();

		final fileName = OpenFlAssets.getPath('$file');

		try {
			if (LuaL.dofile(vm, fileName) != Lua.OK) {
				final error:String = cast(Lua.tostring(vm, -1), String);
				Lua.pop(vm, 1);
				throw error;
			}
		} catch (e:Exception) {
			Application.current.window.alert(e.message, 'Funkin Hyper');
			die();
		}
	
		setFunctions();
	}

	public function set(key:String, val:Dynamic):Void {
		if (vm == null)
			return;

		toLua(vm, val);
		Lua.setglobal(vm, key);
	}

	public function get(key:String):Dynamic {
		if (vm == null)
			return null;

		Lua.getglobal(vm, key);

		final ret:Dynamic = toHaxe(vm, -1);

		if (ret != null)
			Lua.pop(vm, 1);

		return ret;
	}

	public function addCallback(key:String, val:Function):Void {
		if (vm == null || (vm != null && !Reflect.isFunction(val)))
			return;

		callbacks.set(key, val);

		// trace('$key, $val');

		Lua.pushstring(vm, key);
		Lua.pushcclosure(vm, cpp.Function.fromStaticFunction(callback), 1);
		Lua.setglobal(vm, key);
	}

	public function removeCallback(key:String):Void {
		if (vm == null)
			return;

		callbacks.remove(key);

		Lua.pushnil(vm);
		Lua.setglobal(vm, key);
	}

	public function call(name:String, ?args:Array<Dynamic>):Dynamic {
		if (vm == null)
			return null;

		Lua.getglobal(vm, name);

		if (Lua.type(vm, -1) != Lua.TFUNCTION)
			return null;

		if (args != null && args.length > 0)
			for (arg in args)
				toLua(vm, arg);

		try {
			if (Lua.pcall(vm, args != null ? args.length : 0, 1, 0) != Lua.OK) {
				final error:String = cast(Lua.tostring(vm, -1), String);
				Lua.pop(vm, 1);
				throw error;
			}
		} catch (e:Exception) {
			Application.current.window.alert(e.message, 'Funkin Hyper');
			die();
			return null;
		}

		final ret:Dynamic = toHaxe(vm, -1);

		if (ret != null)
			Lua.pop(vm, 1);

		return ret;
	}

	public function die():Void {
		/* cleanup stuff */
		callbacks.clear();

		if (vm != null) {
			/* cleanup Lua */
			Lua.close(vm);
			vm = null;
		}
	}

	private static function toLua(l:State, val:Dynamic):Void {
		switch (Type.typeof(val)) {
			case TNull:
				Lua.pushnil(l);
			case TInt:
				Lua.pushinteger(l, val);
			case TFloat:
				Lua.pushnumber(l, val);
			case TBool:
				Lua.pushboolean(l, val ? 1 : 0);
			case TClass(Array):
				Lua.createtable(l, val.length, 0);

				for (i in 0...val.length) {
					Lua.pushinteger(l, i + 1);
					toLua(l, val[i]);
					Lua.settable(l, -3);
				}
			case TClass(ObjectMap) | TClass(StringMap):
				var map:Map<String, Dynamic> = val;

				Lua.createtable(l, Lambda.count(map), 0);

				for (key => value in map) {
					Lua.pushstring(l, Std.isOfType(key, String) ? key : Std.string(key));
					toLua(l, value);
					Lua.settable(l, -3);
				}
			case TClass(String):
				Lua.pushstring(l, cast(val, String));
			case TObject:
				Lua.createtable(l, Reflect.fields(val).length, 0);

				for (key in Reflect.fields(val)) {
					Lua.pushstring(l, key);
					toLua(l, Reflect.field(val, key));
					Lua.settable(l, -3);
				}
			default:
				Sys.println('Couldn\'t convert "${Type.typeof(val)}" to Lua.');
		}
	}

	private static function toHaxe(l:State, idx:Int):Dynamic {
		switch (Lua.type(l, idx)) {
			case type if (type == Lua.TNIL):
				return null;
			case type if (type == Lua.TBOOLEAN):
				return Lua.toboolean(l, idx) == 1;
			case type if (type == Lua.TNUMBER):
				return Lua.tonumber(l, idx);
			case type if (type == Lua.TSTRING):
				return cast(Lua.tostring(l, idx), String);
			case type if (type == Lua.TTABLE):
				var count:Int = 0;
				var array:Bool = true;

				Lua.pushnil(l);

				while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0) {
					if (array) {
						if (Lua.isnumber(l, -2) != 0)
							array = false;
						else {
							final index:Float = Lua.tonumber(l, -2);
							if (index < 0 || Std.int(index) != index)
								array = false;
						}
					}

					count++;
					Lua.pop(l, 1);
				}

				if (count == 0)
					return {};
				else if (array) {
					var ret:Array<Dynamic> = [];

					Lua.pushnil(l);

					while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0) {
						ret[Std.int(Lua.tonumber(l, -2)) - 1] = toHaxe(l, -1);

						Lua.pop(l, 1);
					}

					return ret;
				} else {
					var ret:DynamicAccess<Dynamic> = {};

					Lua.pushnil(l);

					while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0) {
						switch (Lua.type(l, -2)) {
							case type if (type == Lua.TSTRING):
								ret.set(cast(Lua.tostring(l, -2), String), toHaxe(l, -1));

								Lua.pop(l, 1);
							case type if (type == Lua.TNUMBER):
								ret.set(Std.string(Lua.tonumber(l, -2)), toHaxe(l, -1));

								Lua.pop(l, 1);
						}
					}

					return ret;
				}
			default:
				Sys.println('Couldn\'t convert "${cast (Lua.typename(l, idx), String)}" to Haxe.');
		}

		return null;
	}

	private static function print(l:State):Int {
		final nargs:Int = Lua.gettop(l);

		for (i in 0...nargs)
			Sys.println('(Lua) : ' + cast(Lua.tostring(l, i + 1), String));

		Lua.pop(l, nargs);
		return 0;
	}

	private static function callback(l:State):Int {
		final nargs:Int = Lua.gettop(l);

		var args:Array<Dynamic> = [];

		for (i in 0...nargs)
			args[i] = toHaxe(l, i + 1);

		Lua.pop(l, nargs);

		final name:String = Lua.tostring(l, Lua.upvalueindex(1));

		if (callbacks.exists(name)) {
			var ret:Dynamic = Reflect.callMethod(null, callbacks.get(name), args);

			if (ret != null) {
				toLua(l, ret);
				return 1;
			}
		}

		return 0;
	}

	public function setVariables() {
		set('name', this.scriptName);
		set('curStep', 0);
		set('curBeat', 0);
		set('songPosition', 0);
		set('Function_Stop', LuaTools.Function_Stop);
		set('Function_Continue', LuaTools.Function_Continue);
	}

	public function setFunctions() {
		addCallback('close', function() {
			closed = true;
			trace("script closed");
			return closed;
		});

		addCallback('makeLuaSprite', function(tag:String, image:String, x:Float = 0, y:Float = 0) {
			if (!PlayState.instance.luaSprites.exists(tag)) {
				var sprite:FlxSprite = new FlxSprite(x, y, Paths.image(image));
				PlayState.instance.luaSprites[tag] = sprite;
			}
		});
		addCallback('addLuaSprite', function(tag:String) {
			if (PlayState.instance.luaSprites.exists(tag))
				PlayState.instance.add(PlayState.instance.luaSprites.get(tag));
		});
		addCallback('bop', function(tag:String) {
			if (PlayState.instance.luaSprites.exists(tag))
				PlayState.instance.add(PlayState.instance.luaSprites.get(tag));
		});

		addCallback('setScrollFactor', function(tag:String, factor:Float = 1, factor2:Float = 1) {
			if (PlayState.instance.luaSprites.exists(tag))
				PlayState.instance.luaSprites.get(tag).scrollFactor.set(factor, factor2);
		});

		addCallback('setGraphicSize', function(tag:String, widder1:Float = 1, widder2:Float = 1, updateHitbox:Bool = false) {
			if (PlayState.instance.luaSprites.exists(tag))
				PlayState.instance.luaSprites.get(tag).setGraphicSize(widder1, widder2);

			if (PlayState.instance.luaSprites.exists(tag) && updateHitbox)
				PlayState.instance.luaSprites.get(tag).updateHitbox();
		});

		addCallback('screenCenter', function(tag:String) {
			if (PlayState.instance.luaSprites.exists(tag))
				PlayState.instance.luaSprites.get(tag).screenCenter();
		});

		addCallback('scaleObject', function(tag:String, factor:Float = 1, factor2:Float = 1) {
			if (PlayState.instance.luaSprites.exists(tag))
				PlayState.instance.luaSprites.get(tag).scale.set(factor, factor2);
		});

		addCallback('removeLuaSprite', function(tag:String, destroy:Bool = true) {
			if (PlayState.instance.luaSprites.exists(tag)) {
				PlayState.instance.remove(PlayState.instance.luaSprites.get(tag), true);
				PlayState.instance.luaSprites.get(tag).kill();
				PlayState.instance.luaSprites.get(tag).destroy();
				var spr = PlayState.instance.luaSprites.get(tag);
				spr = null;
				PlayState.instance.luaSprites.remove(tag);
			}
		});
		ReflectionFuncs.copyTo(this);

	}

	public static function getShader(obj:String):Shader {
		return PlayState.instance.luaShaders.get(obj);
	}

}


