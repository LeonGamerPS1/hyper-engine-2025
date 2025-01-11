package;

import android.AndroidControls;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class MainMenu extends MusicBeatState {
	var items = ["story_mode", "freeplay", "options"];
	var menuItems:FlxTypedGroup<MenuItem> = new FlxTypedGroup<MenuItem>();
	var camFollow:FlxObject;

	public var curSelected:Int = 0;
	public var selectedSomethin:Bool = false;

	public var magenta:FlxSprite;

	override function create() {
		super.create();
		var yScroll:Float = Math.max(0.25 - (0.05 * (items.length - 4)), 0.1);

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menu/menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menu/menuBGMagenta'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.antialiasing = true;
		magenta.visible = false;
		add(magenta);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		var offset:Float = 108 - (Math.max(items.length, 4) - 4) * 80;
		for (i => value in items) {
			var menuItem:MenuItem = new MenuItem(value);
			menuItem.setPosition(0, (i * 140) + offset);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (items.length - 4) * 0.135;
			if (items.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
		}
		add(menuItems);
		FlxG.camera.follow(camFollow, null, 0);

		var versionShit:FlxText = new FlxText(0, FlxG.height - 20, 0, "Hyper Engine v0.2.0", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat('assets/font/bookantiqua_bold.ttf', 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK, true);
		versionShit.antialiasing = true;
		add(versionShit);

		changeItem();
		if (AndroidControls.isEnabled)
			add(AndroidControls.createVirtualPad(UP_DOWN, A_B));
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);
		menuItems.forEach(function(spr:FlxSprite) {
			spr.screenCenter(X);
		});

		if (!selectedSomethin) {
			if (controls.UI_UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(new Title());
			}
			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxFlicker.flicker(magenta, 1.1, 0.15, false);
				FlxG.sound.play(Paths.sound('confirmMenu'));

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween) {
								spr.kill();
							}
						});
					} else {
						FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker) {
							var daChoice:String = items[curSelected];

							switch (daChoice) {
								case 'story_mode':
									FlxG.sound.music.stop();
									Conductor.songPosition = -10;
									FlxG.switchState(new PlayState());

								case 'freeplay':
									FlxG.sound.music.stop();
									Conductor.songPosition = 0;
									FlxG.switchState(new SongSel());

								case 'options':
									FlxG.switchState(new OptionsMenu());
							}
						});
					}
				});
			}
		}
	}

	function changeItem(huh:Int = 0) {
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:MenuItem) {
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected) {
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
