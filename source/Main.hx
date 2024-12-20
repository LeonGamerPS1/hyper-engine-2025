package;

import ofl.fps.FPS_Mem;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var fpsVar:FPS_Mem = new FPS_Mem(10,10);
	public function new()
	{
		super();
		PolymodHandler.init();
		addChild(new FlxGame(0, 0, SongSel));
		addChild(fpsVar);
		PlayerSettings.init();
	}
}
