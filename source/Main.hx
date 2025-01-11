package;

import loading.Init;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.display.FPSK;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite {
	public static var fpsVar:FPSK = new FPSK(3, 3, 0xFFFFFF);

	public function new() {
		backend.Log.init();
		super();

		addChild(new FlxGame(0, 0, Init));
		addChild(fpsVar);
		#if (windows && cpp) 
		native.NativeUtil.Windows.setWindowDarkMode("Friday Night Funkin': Hyper Engine",true);
		native.NativeUtil.Windows.setDPIAware();
		#end
	}

	private static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
