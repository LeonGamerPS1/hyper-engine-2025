package objects;

import flixel.FlxSprite;


class MenuItem extends FlxSprite {
	public function new(key:String = 'story') {
		super();
		frames = Paths.getSparrowAtlas('menu/$key');
		animation.addByPrefix('idle', '$key idle', 24);
		animation.addByPrefix('selected', '$key selected', 24);
		animation.play('selected');
		antialiasing = true;
	}
}