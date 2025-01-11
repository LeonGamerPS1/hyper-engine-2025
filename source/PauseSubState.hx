package;

import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;

class PauseSubState extends MusicBeatSubState {
	var cam:FlxCamera;

	public var menuItemsOG:Array<String> = ["Resume", "Restart", "Chart Editor","Botplay", "Back"];
	public var items:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	public var curSel:Int = 0;
	public var introDone:Bool = false;

	public function new(cam:FlxCamera) {
		super();
		this.cam = cam;
	}

	override function create() {
		super.create();
		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.5;
		FlxTween.tween(bg, {alpha: 0.5}, 0.5);
		add(bg);
		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			introDone = true;
		});

		for (i in 0...menuItemsOG.length) {
			var item:Alphabet = new Alphabet(0, 0, menuItemsOG[i], true);
			item.x = 300 + (25 * i);
			item.isMenuItem = true;
			item.y += 80 * i; // 30 + (25 * i);
			items.add(item);
		}
		add(items);
		changeSel();

		cameras = [cam];
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_DOWN_P)
			changeSel(1);
		if (controls.UI_UP_P)
			changeSel(-1);

		if (controls.ACCEPT && introDone) {
			switch (menuItemsOG[curSel]) {
				case "Resume":
					close();
					if (PlayState.instance != null)
						PlayState.instance.unpause();
			
				case "Restart":
					FlxG.resetState();

				case "Botplay":
					if (PlayState.instance != null)
						PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;	
				case "Chart Editor":
					FlxG.switchState(new editors.ChartEditorState());
				case "Back":
					FlxG.switchState(new MainMenu());
			}
		}

		if (controls.BACK) {
			close();
			if (PlayState.instance != null)
				PlayState.instance.unpause();
		}

		//	close();
	}

	function changeSel(add:Int = 0) {
		curSel += add;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		if (curSel < 0)
			curSel = items.members.length - 1;
		if (curSel > items.members.length - 1)
			curSel = 0;
		var bullShit:Int = 0;

		for (item in items.members) {
			item.targetY = bullShit - curSel;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}

	function get_curSelected():Alphabet {
		return items.members[curSel];
	}
}
