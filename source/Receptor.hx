package;

import effects.shaders.RGBPalette.RGBShaderReference;
import flixel.FlxG;
import flixel.FlxSprite;

class Receptor extends FlxSprite {
	public var noteData:Int;
	public var resetAnim:Float = 0;

	public var downScroll:Bool = false;

	public var sustainReduce:Bool = true;
	public var direction:Float = 90;
	public var texture(default, set):String;
	public var isPixel:Bool = false;

	public static var strumScale:Float = 1;

	public var rgbShader:RGBShaderReference;

	public static var colArray:Array<String> = ["arrowLEFT", "arrowDOWN", "arrowUP", "arrowRIGHT"];

	public function new(noteData:Int = 0, isPixel:Bool = false) {
		super(0, 0);
		this.noteData = noteData;
		this.isPixel = isPixel;

		texture = "NOTE_assets";
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData, isPixel));
		playAnim('static', true);
	}

	function pixel(tex:String = "NOTE_assets") {
		loadGraphic(Paths.image('pixelUI/$tex'));
		width = width / 4;
		height = height / 5;
		loadGraphic(Paths.image('pixelUI/$tex'), true, Math.floor(width), Math.floor(height));

		antialiasing = false;
		setGraphicSize(Std.int(width * 6 * strumScale));

		animation.add('green', [6]);
		animation.add('red', [7]);
		animation.add('blue', [5]);
		animation.add('purple', [4]);
		switch (Math.abs(noteData % 4)) {
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

	function normal(tex:String = "NOTE_assets") {
		frames = Paths.getSparrowAtlas(tex);
		animation.addByPrefix('static', '${colArray[noteData % colArray.length]}0');
		animation.addByPrefix('pressed', '${colArray[noteData % colArray.length].split("arrow")[1].toLowerCase()} press', 24, false);
		animation.addByPrefix('confirm', '${colArray[noteData % colArray.length].split("arrow")[1].toLowerCase()} confirm', 24, false);

		setGraphicSize(width * 0.7 * strumScale);

		antialiasing = FlxG.save.data.antialias;
	}

	override function update(elapsed:Float) {
		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				playAnim('static', true);
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function getAnimationName():String {
		return (animation.curAnim != null ? animation.curAnim.name : null);
	}

	public function playAnim(anim:String = 'static', ?force:Bool = false) {
		animation.play(anim, force);

		if (rgbShader != null)
			rgbShader.enabled = anim != 'static';
		if (animation.curAnim != null) {
			centerOffsets();
			centerOrigin();
		}
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
		playAnim('static');
		updateHitbox();
	}
}
