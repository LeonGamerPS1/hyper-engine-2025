package;

import backend.DiscordClient;
import lime.app.Application;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.text.FlxBitmapText;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

class SongSel extends MusicBeatState {
	var songs:Array<String> = [];

	var items:FlxTypedGroup<Alphabet> = new FlxTypedGroup();
	var curSel:Int = 0;

	var camFollow:FlxObject;
	var curSelected(get, null):Alphabet;

	var selSom:Bool = false;

	override function create():Void {
		super.create();

		songs = FileUtil.readDirectory("assets/music", 2).filter(function(ffe:String) {
			return !ffe.contains(".txt");
		});
		var i:Int = 0;
		for (song in songs) {
			var item:Alphabet = new Alphabet(0,0,song,true);
			item.screenCenter();
			item.y += (70 * i);
			//item.scale.set(2, 2);
			items.add(item);
			i++;
		}

		add(items);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.screenCenter();
		FlxG.camera.follow(camFollow, FlxCameraFollowStyle.LOCKON);
		changeSel();

		DiscordClient.changePresence("In the Menus");
	}

	override function update(elapsed:Float):Void {
		//super.update(elapsed);
		if (controls.UI_DOWN_P)
			changeSel(1);
		if (controls.UI_UP_P)
			changeSel(-1);

		if (controls.ACCEPT && !selSom) {
			selSom = true;
			FlxFlicker.flicker(curSelected, 1, 0.04, false, true, function(flick) {
				try {
					PlayState.SONG = Song.loadFromJson(curSelected.text, curSelected.text);
					FlxG.switchState(new PlayState());
				} catch (e:Dynamic) {
					Application.current.window.alert("The game has failed Loading the song" + curSelected.text + '.\n Error Info: $e ',"Error" );
				}
			});
		}

		for (i in 0...items.length) {
			var item = items.members[i];
			item.alpha = item == curSelected ? 1 : 0.7;

		}
	}

	function changeSel(i:Int = 0) {
		curSel += i;

		if (curSel < 0)
			curSel = items.members.length - 1;
		if (curSel > items.members.length - 1)
			curSel = 0;

		if (curSelected != null)
			FlxTween.tween(camFollow, {x: 300, y: curSelected.getGraphicMidpoint().y}, 0.2);
	}

	function get_curSelected():Alphabet {
		return items.members[curSel];
	}
}
