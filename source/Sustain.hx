package;

import flixel.util.FlxDestroyUtil;

/**
 * Object which displays a hold trail behind a sustain note.
 */
class Sustain extends TiledSprite {
	/**
	 * Parent note.
	 */
	public var parent(default, set):Note;

	/**
	 * Creates a new `Sustain`.
	 * @param parent Parent note.
	 */
	public function new(parent:Note):Void {
		super();
		this.parent = parent;
	}

	override function update(elapsed:Float):Void {
		var receptor:Receptor = parent.targetReceptor;

		// we're making the sustain a bit longer here so it ends properly when it's about to be behind the receptor.
		height = (parent.length * Note.pixelPerMs * parent.scrollSpeed) + (receptor.height * 0.5);
		this.y = parent.y + parent.height * 0.5;

		if (parent.targetReceptor.downScroll)
			y -= height;

		if (parent.wasGoodHit) {
			// update sustain clipping
			clipRegion.y = receptor.y + receptor.height * 0.5 - y;

			if (parent.targetReceptor.downScroll)
				clipRegion.y = height - clipRegion.y;
		}

		if (animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1)
			animation.update(elapsed);

		//#if FLX_DEBUG
		//FlxBasic.activeCount++;
		//#end
	}

	/**
	 * Reloads this `Sustain`'s frames, scale and such.
	 */
	function refreshVisuals():Void {
		// var dir:String = Note.directions[parent.direction];

		frames = parent.frames;
		animation.copyFrom(parent.animation);
		animation.play("hold", true);
		setTail("holdend");

		scale.set(parent.scale.x, parent.scale.y);
		updateHitbox();

		flipY = parent.flipY;
		if (parent.targetReceptor?.downScroll)
			flipY = !flipY;

		x = parent.x + (parent.width - width) * 0.5;
		antialiasing = parent.antialiasing;
		alpha = parent.multAlpha * 0.6;
		flipX = parent.flipX;
	}

	override function kill():Void {
		clipRegion = FlxDestroyUtil.put(clipRegion);
		super.kill();
	}

	override function destroy():Void {
		parent = null;
		super.destroy();
	}

	function set_parent(v:Note):Note {
		parent = v;

		if (v != null)
			refreshVisuals();

		return v;
	}
}
