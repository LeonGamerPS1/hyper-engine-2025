package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Receptor extends FlxSprite
{
	public var noteData:Int;
	public var resetAnim:Float = 0;

	public var downScroll:Bool = false;

	public var sustainReduce:Bool = true;
	public var direction:Float = 90;

	public static var colArray:Array<String> = ["arrowLEFT", "arrowDOWN", "arrowUP", "arrowRIGHT"];

	public function new(noteData:Int = 0, isPixel:Bool = false)
	{
		super(0, 50);
		this.noteData = noteData;
		if (isPixel == false)
			normal();
		else
			pixel();

		x += Note.swagWidth / 2;
		playAnim('static');
		updateHitbox();
	}

	function pixel()
	{
		loadGraphic(AssetPaths.pixelArrow__png);
		width = width / 4;
		height = height / 5;
		loadGraphic(AssetPaths.pixelArrow__png, true, Math.floor(width), Math.floor(height));


		antialiasing = false;
		setGraphicSize(Std.int(width * 6));

		animation.add('green', [6]);
		animation.add('red', [7]);
		animation.add('blue', [5]);
		animation.add('purple', [4]);
		switch (Math.abs(noteData))
		{
			case 0:
				animation.add('static', [0]);
				animation.add('pressed', [4, 8], 24, false);
				animation.add('confirm', [12, 16], 24, false);
			case 1:
				animation.add('static', [1]);
				animation.add('pressed', [5, 9], 24, false);
				animation.add('confirm', [13, 17], 24, false);
			case 2:
				animation.add('static', [2]);
				animation.add('pressed', [6, 10], 24, false);
				animation.add('confirm', [14, 18], 24, false);
			case 3:
				animation.add('static', [3]);
				animation.add('pressed', [7, 11], 24, false);
				animation.add('confirm', [15, 19], 24, false);
		}
	}

	function normal()
	{
		frames = FlxAtlasFrames.fromSparrow(AssetPaths.arrow__png, AssetPaths.arrow__xml);
		animation.addByPrefix('static', '${colArray[noteData % colArray.length]}0');
		animation.addByPrefix('pressed', '${colArray[noteData % colArray.length].split("arrow")[1].toLowerCase()} press', 24, false);
		animation.addByPrefix('confirm', '${colArray[noteData % colArray.length].split("arrow")[1].toLowerCase()} confirm', 24, false);

		setGraphicSize(width * 0.7);

		antialiasing = true;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
	}
}
