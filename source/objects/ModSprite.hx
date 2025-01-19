package objects;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;

class ModSprite extends FlxSprite {
	public var sprTracker:FlxSprite;

	public function new(x:Float, y:Float, bmp:FlxGraphicAsset, ?sprTracker:FlxSprite) {
		super(x, y, bmp);
		this.sprTracker = sprTracker;
	}

	override function update(elapsed:Float) {
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);

		super.update(elapsed);
	}
}
