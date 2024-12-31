package;

import android.AndroidControls;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;


class Freeplay extends MusicBeatSubState {
	var funnyCamera:FlxCamera;
	var leftBar:FlxSprite = new FlxSprite(-FlxG.width / 2, 0).makeGraphic(Std.int(FlxG.width / 2), FlxG.height, FlxColor.GRAY).loadGraphic(Paths.image('freeplay/pinkBack'));
	var rightBar:FlxSprite = new FlxSprite(FlxG.width, 0).makeGraphic(Std.int(FlxG.width / 2), FlxG.height, FlxColor.BLACK).loadGraphic(Paths.image('freeplay/freeplayBGdad'));

	public var fuckyBlueBall:FlxSparrow = new FlxSparrow(-FlxG.width / 2, 100, 'freeplay/BFfreeplay');

	override function create() {
		super.create();
		funnyCamera = new FlxCamera();
		funnyCamera.bgColor.alpha = 0;
		FlxG.cameras.add(funnyCamera, false);
		add(leftBar);
		add(rightBar);
		fuckyBlueBall.addAnim("intro", "boyfriend dj intro", 650, 50, 24, false);
		fuckyBlueBall.addAnim("confirm", "Boyfriend DJ Confirm", 650, 50, 24, false);
		fuckyBlueBall.addAnim("loop", "Boyfriend DJ0", 650, 50, 24, true);

		add(fuckyBlueBall);

		for (index => value in members) {
			value.cameras = [funnyCamera];
		}
		fuckyBlueBall.playAnim("intro", true);
		fuckyBlueBall.animation.callback = function(name:String, frame:Int, frameIndex:Int) {
			if (name == "intro" && fuckyBlueBall.animation.finished) {
				fuckyBlueBall.playAnim("loop", true);
				fuckyBlueBall.offset.y -= 170;
			}
		};

		FlxTween.tween(fuckyBlueBall, {x: 0}, 0.0001, {ease: FlxEase.sineInOut});
		FlxTween.tween(leftBar, {x: 0}, 1.2, {ease: FlxEase.sineInOut});
		FlxTween.tween(rightBar, {x: rightBar.x - FlxG.width / 2}, 1.2, {ease: FlxEase.sineInOut});

		if (AndroidControls.isEnabled)
			add(AndroidControls.createVirtualPad(UP_DOWN, A_B)).cameras = [funnyCamera];
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			new FlxTimer().start(1, function(e) {
				FlxTween.tween(leftBar, {x: -FlxG.width / 2}, 1.2, {ease: FlxEase.sineInOut});
				FlxTween.tween(rightBar, {x: FlxG.width}, 1.2, {ease: FlxEase.sineInOut});
				FlxTween.tween(fuckyBlueBall, {x: -FlxG.width / 2}, 1, {ease: FlxEase.sineInOut});
				new FlxTimer().start(0, function(e) {
					FlxG.cameras.remove(funnyCamera);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					FlxG.switchState(new MainMenu());
					close();
				});
			});
		}
	}
}