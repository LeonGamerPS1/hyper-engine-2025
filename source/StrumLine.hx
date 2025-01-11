package;

import flixel.group.FlxSpriteGroup;

class StrumLine extends FlxSpriteGroup {
	public function new(x:Float = 0, y:Float = 50, isPixel:Bool = false, downScroll:Bool = false) {
		super(x, y);
		for (i in 0...4) {
			var num:Receptor = new Receptor(i, isPixel == true ? true : false);
			num.x += Note.swagWidth * i * Receptor.strumScale;
			num.downScroll = downScroll;
			add(num);
		}
	}

	public function playStrumAnim(anim:String = "static", id:Int = 0) {
		id = id % members.length;
		forEach(function(sprite) {
			if (sprite is Receptor && cast(sprite, Receptor).noteData == id) {
				cast(sprite, Receptor).playAnim(anim, true);
			}
		});
	}

	public function getReceptorOfID(id:Int = 0):Receptor {
		id = id % members.length;
		var returnVal:Receptor = null;
		forEach(function(sprite) {
			if (sprite is Receptor && cast(sprite, Receptor).noteData == id)
				returnVal = cast(sprite, Receptor);
		});
		return returnVal;
	}
}
