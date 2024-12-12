package ume.backend;

import flixel.FlxGame;
import openfl.display.Sprite;
import ume.game.*;
import ume.objects.FPS_Mem;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, Title, 120, 60, true));

		var fps_mem:FPS_Mem = new FPS_Mem(10, 10, 0xffffff);
		addChild(fps_mem);

		PlayerSettings.init();
	}
}
