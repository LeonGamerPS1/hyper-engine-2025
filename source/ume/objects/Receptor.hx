package ume.objects;

import flixel.FlxSprite;
import flixel.util.FlxTimer;
import ume.assets.UMEAssets;
import ume.game.PlayState;

class Receptor extends FlxSprite {
	public var dataNote:Int;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var reduceSustains:Bool = true;
	public var holdTimer:Float = 0;

	public static var receptorNim:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];

	var notedatas:Array<String> = ["Purple", "Blue", "Green", "Red"];

	public static var dirArray:Array<String> = ["Left", "Down", "Up", "Right"];

	public var resetAnim:Float = 0;

	public var holdCoverEnd:FlxSprite;
	public var holdCover:FlxSprite;

	public function new(id:Int) {
		super();
		antialiasing = true;

		ID = id;
		dataNote = id;
		loadSkinAndVariant();

		holdCover = new FlxSprite(x, y);
		holdCoverEnd = new FlxSprite(x, y);

		holdCover.visible = false;
		holdCoverEnd.visible = false;
	}

	public function loadSkinAndVariant(skin:String = "arrow", ?variant:String) {
		variant ??= "normal";
		if (skin == "")
			skin = "arrow";
		if (PlayState.noteVariant != "")
			variant = PlayState.noteVariant;

		var tex = UMEAssets.getSparrowAtlas('notes/$variant/$skin') != null ? UMEAssets.getSparrowAtlas('notes/$variant/$skin') : UMEAssets.getSparrowAtlas('notes/normal/arrow');
		frames = tex;

		animation.addByPrefix('static', 'arrow${receptorNim[dataNote % receptorNim.length]}', 24, false);
		animation.addByPrefix('press', '${receptorNim[dataNote % receptorNim.length].toLowerCase()} press', 24, false);
		animation.addByPrefix('confirm', '${receptorNim[dataNote % receptorNim.length].toLowerCase()} confirm', 24, false);
		playAnim('static');
		setGraphicSize(width * 0.7);
		updateHitbox();
	}

	public function splashfuck() {
		holdCoverEnd.visible = true;

		holdCoverEnd.visible = false;
	}

	override function update(elapsed:Float) {
		holdCover.setPosition(x, y);
		holdCoverEnd.setPosition(x, y);

		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (holdTimer > 0) {
			holdTimer -= elapsed;
			holdCover.visible = true;
			if (holdTimer <= 0) {
				holdCover.visible = false;
				splashfuck();
				holdTimer = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(Anim, Force = false, Reversed = false, Frame:Int = 0) {
		animation.play(Anim, Force, Reversed, Frame);

		if (animation.curAnim != null) {
			centerOffsets();
			centerOrigin();
		}
	}
}
