package loading;

import editors.Events;
import flixel.FlxG;
import backend.AlsoftConfig.ALSoftConfig;
import backend.WeekData;
import flixel.FlxState;

class Init extends FlxState {
	override public function create() {
		PolymodHandler.init();
		WeekData.init();
		ALSoftConfig.init();
		PlayerSettings.init();
		Options.CheckDefaults();
		Events.init();

		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null)
						@:privateAccess
						Main.resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				@:privateAccess
				Main.resetSpriteCache(FlxG.game);
		});

		FlxG.switchState(new Title());
	}
}
