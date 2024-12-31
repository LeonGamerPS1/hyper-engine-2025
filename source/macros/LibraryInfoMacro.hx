package macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
#end

class LibraryInfoMacro {
	public static function setLibrarys() {
		#if macro
		var fields = Context.getBuildFields();
		var librarys:Field = [for (field in fields) if (field.name == 'get_librarys') field][0];

		switch (librarys.kind) {
			case FFun(f):
				librarys.kind = FFun({
					args: f.args,
					params: f.params,
					ret: f.ret,
					expr: macro {
						var openfl:String = '\nOpenFL: ${haxe.macro.Compiler.getDefine("openfl")}';
						var lime:String = '\nLime: ${haxe.macro.Compiler.getDefine("lime")}';
						var flixel:String = '\nFlixel: ${haxe.macro.Compiler.getDefine("flixel")}';

						return lime + openfl + flixel;
					}
				});
			default:
		}
		return fields;
		#end
	}
}
