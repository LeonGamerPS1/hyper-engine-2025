package ume.objects;

import flixel.FlxSprite;
import ume.assets.UMEAssets;

class MenuItem extends FlxSprite
{
	public function new(key:String = 'story')
	{
		super();
		frames = UMEAssets.getSparrowAtlas('menu/$key');
		animation.addByPrefix('idle', '$key idle');
		animation.addByPrefix('selected', '$key selected');
		animation.play('selected');
	}
}
