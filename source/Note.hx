package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxRect;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var distance:Float = 2000;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var isPixel:Bool = false;

	public static var colArray:Array<String> = ["purple", "blue", "green", "red"];
	public static var pixArray:Array<Int> = [4, 5, 6, 7];
	public static var swagWidth:Float = 160 * 0.7;

	public var prevNote:Note;
	public var isSustainNote:Bool = false;
	public var multSpeed:Float = 1;

	public function new(strumTime:Float = 0, noteData:Int = 0, isSustainNote:Bool = false, ?prevNote:Note, mustPress:Bool = false, pixelNote:Bool = true)
	{
		super(0, -2000);
		this.strumTime = strumTime;
		this.noteData = noteData;
		this.isSustainNote = isSustainNote;
		this.prevNote = prevNote;
		this.mustPress = mustPress;

		if (pixelNote)
			pixel();
		else
			normal();
		updateHitbox();
		if (!isSustainNote)
			animation.play('arrow');
	}

	public function followStrumNote(myStrum:Receptor, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll)
			distance *= -1;

		if (isSustainNote)
			flipY = myStrum.downScroll;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if (copyAlpha)
			alpha = strumAlpha * multAlpha;

		if (copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if (copyY)
		{
			y = strumY + offsetY + 0 + Math.sin(angleDir) * distance;
			if (myStrum.downScroll && isSustainNote)
			{
				y -= (frameHeight * scale.y) - (swagWidth / 2);
			}
		}
	}

	function normal()
	{
		frames = FlxAtlasFrames.fromSparrow(AssetPaths.arrow__png, AssetPaths.arrow__xml);
		animation.addByPrefix('arrow', '${colArray[noteData % colArray.length]}0');
		animation.addByPrefix('hold', '${colArray[noteData % colArray.length]} hold piece');
		animation.addByPrefix('holdend', '${colArray[noteData % colArray.length]} hold end');
		antialiasing = true;

		setGraphicSize(width * 0.7);

		if (isSustainNote && prevNote != null)
		{
			multAlpha = 0.6;
			offsetX = Note.swagWidth / 4;
			offsetX += 8;
			animation.play('holdend');
			updateHitbox();
			if (prevNote.isSustainNote)
			{
				prevNote.animation.play('hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
			}
		}
	}

	function pixel()
	{
		if (isSustainNote)
		{
			loadGraphic(AssetPaths.pixelends__png);
			width = width / 4;
			height = height / 5;
			loadGraphic(AssetPaths.pixelends__png, true, 7, 5);

			antialiasing = false;
			setGraphicSize(Std.int(width * 6));

			animation.add('hold', [noteData]);
			animation.add('holdend', [noteData + 4]);

			if (prevNote != null)
			{
				multAlpha = 0.6;
				offsetX = Note.swagWidth / 2;
				animation.play('holdend');
				updateHitbox();
				offsetX -= Note.swagWidth / 4;
				if (prevNote.isSustainNote)
				{
					prevNote.animation.play('hold');

					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
					prevNote.updateHitbox();
				}
			}
		}
		else
		{
			loadGraphic(AssetPaths.pixelArrow__png);
			width = width / 4;
			height = height / 5;
			loadGraphic(AssetPaths.pixelArrow__png, true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * 6));
			animation.add('arrow', [pixArray[noteData % 4]]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}
	}

	public function clipToStrumNote(myStrum:Receptor)
	{
		var center:Float = myStrum.y + offsetY + swagWidth / FlxG.random.float(2,2.0);
		if ((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if (swagRect == null)
				swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if (y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
