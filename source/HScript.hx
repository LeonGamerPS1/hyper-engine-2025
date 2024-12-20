package;

import openfl.utils.Assets;
import flixel.FlxG;
import hscript.Parser;
import hscript.Interp;

class HScript {
	var parser:Parser;
	var interp:Interp;

	public var name = "";

	public function new(path:String, name:String = "") {
		var expr:String;

		expr = Assets.getText(path);

		this.name = name;
		parser = new hscript.Parser();
		parser.allowTypes = true;
		parser.allowMetadata = true;
		parser.allowJSON = true;
		parser.resumeErrors = true;
		var ast = parser.parseString(expr);

		interp = new hscript.Interp();

		set('game', PlayState.instance);
        set('null', null);
		set('FlxTween', flixel.tweens.FlxTween);
		set('Conductor', Conductor);
		set('FlxG', FlxG);
		set('Math', Math);
        set('Note', Note);
        interp.execute(ast);
	}

	public function call(func:String, ?var1, ?var2, ?var3) {
		if (interp.variables.exists(func))
			interp.variables.get(func)(var1, var2, var3);
		else
			return;
	}

	public function destroy() {
		interp.variables.clear();
		interp.variables = null;
		interp = null;
		parser = null;
		//  this = null;
	}

	public function set(obj:String, val:Dynamic) {
		interp.variables.set(obj, val);
	}
}
