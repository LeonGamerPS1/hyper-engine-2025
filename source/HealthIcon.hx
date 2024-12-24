package;

import flixel.util.FlxColor;
import openfl.utils.Assets;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite {
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var char:String = '';
	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false) {
		super(0, 0);

		this.isPlayer = isPlayer;

		changeIcon(char);
		antialiasing = true;
		scrollFactor.set();
	}

	public var isOldIcon:Bool = false;

	public function swapOldIcon():Void {
		isOldIcon = !isOldIcon;

		if (isOldIcon)
			changeIcon('bf-old');
		else
			changeIcon(PlayState.SONG.player1);
	}

	private var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(newChar:String):Void {
		if (newChar != char) {
			if (animation.getByName(newChar) == null) {
				if (Assets.exists(Paths.img('icons/icon-' + newChar)))
					loadGraphic(Paths.image('icons/icon-' + newChar), true, 150, 150);
				else {
					trace(Paths.img('icons/icon-' + newChar) + " doesn't exist. Loading Default Face icon.");
					loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);
				}
				animation.add(newChar, [0, 1], 0, false, isPlayer);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				updateHitbox();
			}
			animation.play(newChar);
			char = newChar;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	override function updateHitbox() {
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
}
