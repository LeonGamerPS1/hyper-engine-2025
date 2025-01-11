package;

import flixel.FlxG;
import loading.Init;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.display.FPS;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite {
	public static var fpsVar:FPS = new FPS(3, 3, 0xFFFFFF);

	public function new() {
		super();

		addChild(new FlxGame(0, 0, Init));
		addChild(fpsVar);
	}

	private static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
