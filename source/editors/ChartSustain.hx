package editors;

import flixel.math.FlxMath;
import flixel.FlxSprite;

class ChartSustain extends FlxSprite {
	public var endPiece:FlxSprite = new FlxSprite();
	public var note:Note;

	public static var sustain:Note;

	public function new(note:Note, gridBG:FlxSprite, daSus:Float = 0) {
		super(note.x + (note.width / 3), note.y + (note.height / 2));
		if (sustain == null)
			sustain = new Note(0, note.noteData, true);
		else {
			if(sustain.isPixel != note.isPixel)
			{
				sustain.isPixel = note.isPixel;
				sustain.reloadNote();
			}
		}

		frames = sustain.frames;
		animation.copyFrom(sustain.animation);
		animation.play('hold');
		alpha = 0.6;
		shader = note.shader;

		setGraphicSize(note.width / 3, FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height));
		updateHitbox();

		endPiece.frames = frames;
		endPiece.animation.copyFrom(animation);
		endPiece.animation.play('holdend');
		endPiece.alpha = 0.6;
		endPiece.setGraphicSize(width, note.height * 0.6);
		endPiece.updateHitbox();
		endPiece.y = y + height;
		endPiece.shader = shader;
		this.note = note;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		endPiece.y = y + height;
		alpha = 0.6;
		endPiece.alpha = alpha;
		x = note.x + (note.width / 3);
		endPiece.x = x;
	}
}
