package ume.objects;

import flixel.FlxSprite;
import flixel.util.FlxTimer;
import ume.assets.UMEAssets;

class Receptor extends FlxSprite
{
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

	public function new(id:Int)
	{
		super();
		antialiasing = true;
		frames = UMEAssets.getSparrowAtlas('NOTE_assets');
		ID = id;
		dataNote = id;
		setGraphicSize(width * 0.7);
		updateHitbox();

		animation.addByPrefix('static', 'arrow${receptorNim[id % receptorNim.length]}', 24, false);
		animation.addByPrefix('press', '${receptorNim[id % receptorNim.length].toLowerCase()} press', 24, false);
		animation.addByPrefix('confirm', '${receptorNim[id % receptorNim.length].toLowerCase()} confirm', 24, false);
		playAnim('static');
		holdCover = new FlxSprite(x, y);
		holdCoverEnd = new FlxSprite(x, y);

		holdCover.visible = false;
		holdCoverEnd.visible = false;
	}

	public function splashfuck()
	{
		holdCoverEnd.visible = true;

		holdCoverEnd.visible = false;
	}

	override function update(elapsed:Float)
	{
		holdCover.setPosition(x, y);
		holdCoverEnd.setPosition(x, y);

		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (holdTimer > 0)
		{
			holdTimer -= elapsed;
			holdCover.visible = true;
			if (holdTimer <= 0)
			{
				holdCover.visible = false;
				splashfuck();
				holdTimer = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(Anim, Force = false, Reversed = false, Frame:Int = 0)
	{
		animation.play(Anim, Force, Reversed, Frame);

		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
	}
}
