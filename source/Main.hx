package;

import loading.Init;
import display.DebugDisplay;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite {
	public static var fpsVar:DebugDisplay = new DebugDisplay(10, 10, 0xFFFFFF);

	public function new() {
		super();

		addChild(new FlxGame(0, 0, Init, 60, 60, true));
		addChild(fpsVar);
	}

	private static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
