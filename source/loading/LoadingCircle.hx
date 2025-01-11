package loading;


import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class LoadingCircle extends FlxSprite {
	

	public function new() {
		super(0, 0, Paths.image("loadingcircle"));
		updateHitbox();
		antialiasing = true;
		setPosition(FlxG.width - width - 10, FlxG.height - height - 10);
		alpha = 0;
		
	}

	override function update(elapsed:Float) {
		angle += 45 * elapsed;
		alpha += 5 * elapsed;
	}
}
