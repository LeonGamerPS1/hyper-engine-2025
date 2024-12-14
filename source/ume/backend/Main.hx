package ume.backend;

import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;
import ume.game.*;

class Main extends Sprite
{
	public static var fps:FPS = new FPS(10, 10, 0xffffff);
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, Title, 60, 60, true));
		addChild(fps);

		PlayerSettings.init();
	}
}
