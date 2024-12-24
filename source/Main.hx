package;

import backend.AlsoftConfig.ALSoftConfig;
import lime.app.Application;
import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileCircle;
import flixel.graphics.FlxGraphic;
import backend.DiscordClient;
import ofl.fps.FPS_Mem;
import flixel.FlxGame;
import openfl.display.Sprite;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite {
	public static var fpsVar:FPS_Mem = new FPS_Mem(10, 10);

	public function new() {
		super();
		PolymodHandler.init();
		DiscordClient.init();
		ALSoftConfig.init();

		addChild(new FlxGame(0, 0, Title));
		addChild(fpsVar);
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileCircle);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

		PlayerSettings.init();
		Options.CheckDefaults();

		#if web
		Application.current.window.element.style.setProperty("image-rendering", "pixelated");
		#end
	}
}
