package modding;

import hxluajit.Lua;

class HscriptRuntime {
	public static function copyTo(fnc:LuaScript) {
		var addCallback = fnc.addCallback;

		addCallback("runHaxeCode", function(code:String) {
			#if hscript
			fnc.initHaxeModule();
			try {
				LuaScript.hscript.execute(code);
			} catch (e:Dynamic) {}
			#else
			trace("runHaxeCode: HScript isn't supported on this platform!");
			#end
		});

		addCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			#if hscript
			fnc.initHaxeModule();
			try {
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				LuaScript.hscript.variables.set(libName, Type.resolveClass(str + libName));
			} catch (e:Dynamic) {}
			#end
		});
	}
}
