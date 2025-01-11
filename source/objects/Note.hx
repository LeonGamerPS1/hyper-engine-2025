package objects;
import effects.shaders.RGBPalette;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRect;

typedef PreloadNote = {
	var strumTime:Float;
	var noteData:Int;

	var targetReceptor:Receptor;

	var earlyHitMult:Float;
	var lateHitMult:Float;

	var mustPress:Bool;

	var wasHit:Bool;
	var isSustainNote:Bool;
	var wasGoodHit:Bool;
	var ignoreNote:Bool;

	var altNote:Bool;
	var isPixel:Bool;
}

class Note extends FlxSprite {
	public static var pixelPerMs:Float = 0.45;

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

	public var altNote:Bool = false;

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

	public var susNote:Float = 0;

	public static var waveThing:Float = 0;

	public var unheldTime:Float;

	public var length(default, set):Float = 0;

	public var sustain(default, set):Sustain;
	public var parent:Note;
	public var targetReceptor:Receptor;
	public var scrollSpeed:Float = 1;
	public var texture(default, set):String;
	public var sustainLength:Float = 0;

	public var rgbShader:RGBShaderReference;
	public var noteType(default, set):String;
	public var tails:Array<Note> = [];

	public static var globalRgbShaders:Array<RGBPalette> = [];

	public static function initializeGlobalRGBShader(noteData:Int, isPixel:Bool = false) {
		if (isPixel)
			noteData += 4;
		if (globalRgbShaders[noteData] == null) {
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;

			var arr:Array<FlxColor> = (!isPixel) ? ClientPrefs.data.arrowRGB[noteData % 4] : ClientPrefs.data.arrowRGBPixel[noteData % 4];
			if (noteData > -1 && noteData % 4 <= arr.length) {
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		} else {
			var oldRGB = globalRgbShaders[noteData];
			var arr:Array<FlxColor> = (!isPixel) ? ClientPrefs.data.arrowRGB[noteData % 4] : ClientPrefs.data.arrowRGBPixel[noteData % 4];
			if (noteData > -1 && noteData % 4 <= arr.length) {
				if (oldRGB.r != arr[0])
					oldRGB.r = arr[0];
				if (oldRGB.g != arr[1])
					oldRGB.g = arr[1];
				if (oldRGB.b != arr[2])
					oldRGB.b = arr[2];
			}
		}
		return globalRgbShaders[noteData];
	}

	function set_sustain(v:Sustain):Sustain {
		if (v != null)
			v.parent = this;

		return sustain = v;
	}

	function set_length(v:Float):Float {
		return length = Math.max(v, 0);
	}

	public inline function isHoldWindowLate():Bool {
		return unheldTime > 1;
	}

	public function new(strumTime:Float = 0, noteData:Int = 0, isSustainNote:Bool = false, ?prevNote:Note, mustPress:Bool = false, pixelNote:Bool = false,
			susnote:Float = 0, noteType:String = "hurt") {
		super(0, -2000);

		this.strumTime = strumTime;
		this.noteData = noteData;
		this.isSustainNote = isSustainNote;
		this.prevNote = prevNote;
		this.mustPress = mustPress;
		this.susNote = susnote;
		this.isPixel = pixelNote;
		this.texture = "NOTE_assets";

		rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, isPixel));
		this.noteType = noteType;
	}

	function set_noteType(value:String):String {
		switch (value) {
			case 'hurt':
				ignoreNote = true;
				rgbShader.r = 0xC41A1A;
				rgbShader.g = 0x521C1C;
				rgbShader.b = 0x640101;
			default:
				ignoreNote = false;
				rgbShader.r = initializeGlobalRGBShader(noteData, isPixel).r;
				rgbShader.g = initializeGlobalRGBShader(noteData, isPixel).g;
				rgbShader.b = initializeGlobalRGBShader(noteData, isPixel).b;
		}

		return noteType = value;
	}

	public function followStrumNote(myStrum:Receptor, fakeCrochet:Float, songSpeed:Float = 1) {
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = Math.floor((0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed));
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

		if (copyY) {
			y = strumY + offsetY + 0 + Math.sin(angleDir) * distance;
			if (myStrum.downScroll && isSustainNote) {
				if (isPixel) {
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth);
			}
		}
	}

	public function defaultRGB() {
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
		if (isPixel)
			arr = ClientPrefs.data.arrowRGBPixel[noteData];

		if (noteData > -1 && noteData <= arr.length) {
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	function normal(tex:String = "NOTE_assets") {
		frames = Paths.getSparrowAtlas(tex);
		animation.addByPrefix('arrow', '${colArray[noteData % colArray.length]}0');
		animation.addByPrefix('hold', '${colArray[noteData % colArray.length]} hold piece');
		animation.addByPrefix('holdend', '${colArray[noteData % colArray.length]} hold end');
		antialiasing = true;

		setGraphicSize(width * 0.7 * Receptor.strumScale);

		if (isSustainNote && prevNote != null) {
			multAlpha = 0.6;
			offsetX += swagWidth / 3 * Receptor.strumScale;

			animation.play('holdend');
			scale.y = 1 * Receptor.strumScale;
			updateHitbox();
			offsetX = swagWidth / 3 * Receptor.strumScale;
			if (prevNote.isSustainNote) {
				prevNote.animation.play('hold');
				prevNote.scale.y = 0.7 * (Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed);
				prevNote.updateHitbox();
			}
		}
	}

	function pixel(tex:String = "NOTE_assets") {
		if (isSustainNote) {
			loadGraphic(Paths.image('pixelUI/${tex}ENDS'));
			width = width / 4;
			height = height / 5;

			loadGraphic(Paths.image('pixelUI/${tex}ENDS'), true, 7, 6);

			antialiasing = false;
			setGraphicSize(Std.int(width * 6 * Receptor.strumScale));

			animation.add('hold', [noteData]);
			animation.add('holdend', [noteData + 4]);

			if (prevNote != null) {
				multAlpha = 0.6;
				offsetX = Note.swagWidth / 2 * Receptor.strumScale;
				offsetY = -height / 2;
				animation.play('holdend');
				updateHitbox();
				offsetX -= Note.swagWidth / 4 * Receptor.strumScale;
				if (prevNote.isSustainNote) {
					prevNote.animation.play('hold');

					prevNote.scale.y = 6 * Conductor.stepCrochet / 100 * 1.254 * PlayState.SONG.speed;
					prevNote.updateHitbox();
				}
			}
		} else {
			loadGraphic(Paths.image('pixelUI/$tex'));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/$tex'), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * 6 * Receptor.strumScale));
			animation.add('arrow', [pixArray[noteData % 4]]);
		}
	}

	public function setupNote() {
		return this;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (isHoldable() && sustain != null && sustain.exists && sustain.active)
			sustain.update(elapsed);

		if (mustPress) {
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		} else {
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult)) {
				if (strumTime <= Conductor.songPosition || isSustainNote && prevNote.wasGoodHit)
					wasGoodHit = true;
			}
		}

		if (tooLate)
			alpha = 0.3;
	}

	public function clipToStrumNote(myStrum:Receptor) {
		var center:Float = myStrum.y + myStrum.height / 2;
		if ((mustPress || !mustPress) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))) {
			var swagRect:FlxRect = clipRect;
			if (swagRect == null)
				swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll) {
				if (y - offset.y * scale.y + height >= center) {
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			} else if (y + offset.y * scale.y <= center) {
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	/**
	 * Returns whether this note can be held.
	 * @return Bool
	 */
	public inline function isHoldable():Bool {
		return length > 0;
	}

	function set_texture(value:String):String {
		reloadNote(value);

		return texture = value;
	}

	function reloadNote(tex:String = "NOTE_assets") {
		if (isPixel == false)
			normal(tex);
		else
			pixel(tex);

		x += Note.swagWidth / 2;
		if (!isSustainNote)
			animation.play('arrow'); // fix because fuck you
		updateHitbox();
	}

	override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return clipRect = rect;
	}
}
