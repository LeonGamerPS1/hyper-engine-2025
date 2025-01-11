package objects;

import flixel.addons.display.FlxTiledSprite;


class Sustain extends FlxTiledSprite {
	public var parent:Note;

	public function new(parent:Note) {
		super(Paths.image("NOTE_assets"), parent.width, parent.height, false);
		frames = Paths.getSparrowAtlas("NOTE_assets");

		setGraphicSize(width * 0.7);
		updateHitbox();
		animation.addByPrefix("hold", "purple hold piece");
		animation.play("hold");
		scrollY = 100;
		scale.y = 5;
	}
}
