package states;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;

class ModsMenu extends MusicBeatState {
	var mods:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

	public var items:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	public var curSel:Int = 0;
	public var descriptions:Array<String> = [];
	public var box:FlxSprite;
	public var text:FlxText;

	override function create() {
		super.create();
		var bg:FlxSprite = new FlxSprite(0, Paths.image('menu/menuBG'));
		add(bg);

		add(mods);
		add(items);

		box = new FlxSprite(50,0).makeGraphic(Std.int(FlxG.width * 0.9),50,FlxColor.BLACK);
		box.alpha = 0.7;
		add(box);

		if (PolymodHandler.loadedMods.length > 0)
			doLoadedModsCreate();
		else
			displayNoMods();
	}

	function displayNoMods() {
		var flxtext:FlxText = new FlxText(0, 0, 0, "NO MODS LOADED.", 32);
		flxtext.color = FlxColor.BLACK;
		flxtext.screenCenter();
		add(flxtext);
	}

	function doLoadedModsCreate() {
		for (i => value in PolymodHandler.loadedMods) {
			var item:Alphabet = new Alphabet(0, 0, value.title, true);
			item.x = 300 + (25 * i);
			item.isMenuItem = true;
			item.y += 80 * i; // 30 + (25 * i);
			items.add(item);

			var bitmap:BitmapData = BitmapData.fromBytes(value.icon);
			var modIcon:ModSprite = new ModSprite(100 + (25 * i), 300, FlxGraphic.fromBitmapData(bitmap), item);
			modIcon.setGraphicSize(150, 150);
			modIcon.updateHitbox();
			mods.add(modIcon);

			descriptions.push(value.description);
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_DOWN_P)
			changeSel(1);
		if (controls.UI_UP_P)
			changeSel(-1);

		if (controls.BACK)
			FlxG.switchState(new MainMenu());
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
