package loading;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxState;

class LoadingScreen extends FlxState {
	var logoBl:FlxSprite;
    var loadingCircle:LoadingCircle;

	override public function create() {
		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.scale.set(0.5, 0.5);
		logoBl.updateHitbox();
		logoBl.screenCenter();
        logoBl.y -= logoBl.height / 4;
		add(logoBl);

        loadingCircle = new LoadingCircle();
        add(loadingCircle);

		FlxG.camera.flash(FlxColor.BLACK, 0.4);
	}
}
