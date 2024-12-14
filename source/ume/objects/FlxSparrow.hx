package ume.objects;

import flixel.FlxSprite;
import ume.assets.UMEAssets;

class FlxSparrow extends FlxSprite {
	public function new(X:Float = 0, Y:Float = 0, folder:String) {
		super(X, Y);
		frames = UMEAssets.getSparrowAtlas(folder);
		antialiasing = true;
	}

	public function playAnim(Anim:String, ?Force:Bool = false, ?Reversed:Bool = false, ?Frame:Int = 0) {
		animation.play(Anim, Force, Reversed, Frame);

		centerOffsets();
		centerOrigin();
	}

	public function addAnim(Anim:String = "", Prefix:String = "", offsetX:Float = 0, offsetY:Float = 0, Framerate:Int = 24, Looped:Bool = true) {
		animation.addByPrefix(Anim, Prefix, Framerate, Looped);
	}
}
