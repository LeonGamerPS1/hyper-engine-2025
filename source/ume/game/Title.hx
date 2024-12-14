package ume.game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileSquare;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import ume.assets.UMEAssets;
import ume.backend.SongConductor;

class Title extends MusicBeatState {
	public var fatRamEater:FlxSprite;
	public var titleText:FlxSprite;
	public var logoBl:FlxSprite;
	public var fuckingtomain:Bool = false;

	public override function create() {
		SongConductor.changeBPM(102);
		FlxG.sound.playMusic(UMEAssets.sound('freakyMenu'));

		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileSquare);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

		fatRamEater = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		fatRamEater.frames = UMEAssets.getSparrowAtlas('title/gfDanceTitle');
		fatRamEater.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		fatRamEater.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		fatRamEater.antialiasing = true;
		fatRamEater.animation.play('danceRight');
		add(fatRamEater);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = UMEAssets.getSparrowAtlas('title/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = UMEAssets.getSparrowAtlas('title/logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		add(logoBl);

		super.create();
		FlxG.camera.flash();
	}

	public var danceLeft(get, null):Bool;

	function get_danceLeft():Bool {
		return (curBeat % 2 == 0);
	}

	override function beatHit() {
		super.beatHit();
		logoBl.animation.play('bump', true);

		if (danceLeft)
			fatRamEater.animation.play('danceLeft', true);
		else
			fatRamEater.animation.play('danceRight', true);
	}

	override function update(elapsed:Float) {
		SongConductor.time = FlxG.sound.music.time;
		super.update(elapsed);
		if (controls.ACCEPT && !fuckingtomain) {
			fuckingtomain = true;
			yay();
		}
	}

	function yay() {
		FlxG.camera.flash(FlxColor.WHITE, 1, null, true);
		FlxG.sound.play(UMEAssets.sound('confirmMenu'), 1);
		titleText.animation.play('press');
		new FlxTimer().start(1, function(tmr:FlxTimer) {
			tmr.cancel();
			if (tmr != null)
				tmr.destroy();
			FlxG.switchState(new MainMenu());
		});
	}
}
