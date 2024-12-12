package ume.objects;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import ume.assets.UMEAssets;
import ume.backend.SongConductor;
import ume.game.PlayState;

class GameNote extends FlxSprite
{
	public var dataNote:Int;
	public var hitTime:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var sustainLength:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var distance:Float = 2000;
	public var hitCausesMiss:Bool = false;
	public var hitByOpponent:Bool = false;

	public var isSustainNote:Bool = false;

	public static var colArray:Array<String> = ["purple0", "blue0", "green0", "red0"];
	public static var seyCol:Array<String> = ["purple hold", "blue hold", "green hold", "red hold"];

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;

	public var ignoreNote:Bool = false;
	public var tooLate:Bool = false;

	public var multSpeed(default, set):Float = 1;

	public static var swagWidth:Float = 160 * 0.7;

	public var wasGoodHit:Bool = false;
	public var willMiss:Bool = false;

	public var prevNote:GameNote;

	private function set_multSpeed(value:Float):Float
	{
		multSpeed = value;
		return value;
	}

	public function new(hitTime:Float = 0.0, dataNote:Int = 0, isSustainNote:Bool = false, ?prevNote:GameNote)
	{
		super();

		this.dataNote = dataNote;
		this.hitTime = hitTime;
		this.isSustainNote = isSustainNote;
		this.prevNote = prevNote;

		antialiasing = true;
		frames = UMEAssets.getSparrowAtlas('NOTE_assets');

		y += 2000; // offscreen

		setGraphicSize(width * 0.7);
		updateHitbox();

		animation.addByPrefix('arrow', colArray[dataNote % colArray.length]);
		animation.addByPrefix('holdend', seyCol[dataNote % seyCol.length] + " end");
		animation.addByPrefix('holdpiece', seyCol[dataNote % seyCol.length] + " piece");
		playAnim('arrow');

		if (isSustainNote && prevNote != null)
		{
			multAlpha = 0.6;

			offsetX += width / 2;

			animation.play('holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play('holdpiece');

				prevNote.scale.y *= SongConductor.stepCrochet / 100 * 1.5 * PlayState.song.speed;
				prevNote.updateHitbox();
			}
		}
	}

	public function followStrumNote(myStrum:Receptor, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (SongConductor.time - hitTime) * songSpeed * multSpeed);
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

	public function playAnim(Anim, Force = false, Reversed = false, Frame:Int = 0)
	{
		animation.play(Anim, Force, Reversed, Frame);

		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
	}

	override function update(elapsed:Float)
	{
		if (mustPress)
		{
			// miss on the NEXT frame so lag doesnt make u miss notes
			if (willMiss && !wasGoodHit)
			{
				tooLate = true;
				canBeHit = false;
			}
			else
			{
				if (hitTime > SongConductor.time - SongConductor.safeZoneOffset)
				{ // The * 0.5 is so that it's easier to hit them too late, instead of too early
					if (hitTime < SongConductor.time + (SongConductor.safeZoneOffset * 0.5))
						canBeHit = true;
				}
				else
				{
					canBeHit = true;
					willMiss = true;
				}
			}
		}
		else
		{
			canBeHit = false;

			if (hitTime <= SongConductor.time)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
		super.update(elapsed);
	}

	public function clipToStrumNote(myStrum:Receptor)
	{
		var center:Float = myStrum.y + offsetY + swagWidth / 2;
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
	/*
	override function set_clipRect(rect:FlxRect)
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
	 */
}
