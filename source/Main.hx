package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		PolymodHandler.init();
		addChild(new FlxGame(0, 0, PlayState,60));
		PlayerSettings.init();
	}
}
