package backend;

import haxe.PosInfos;

class Log {
	public static function trace(v:Dynamic, ?infos:PosInfos):Void {
		var str = formatOutput(v, infos);
		#if js
		if (js.Syntax.typeof(untyped console) != "undefined" && (untyped console).log != null)
			(untyped console).log(str);
		#elseif sys
		Sys.println(str);
		#end
	}

	static function formatOutput(v:Dynamic, infos:PosInfos):String {
		return '(${infos.className}:${infos.lineNumber}): $v';
	}
}
