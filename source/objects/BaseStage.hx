package objects;

import flixel.FlxBasic;
import flixel.FlxState;

class BaseStage extends FlxBasic {
	var parent:FlxState;

	public function new(parentState:FlxState, autoCreate:Bool = false) {
		super();
		parent = parentState;
		if (parent is MusicBeatState)
			cast(parent, MusicBeatState).addStage(this);
		parent.add(this);

		if (autoCreate == true)
			create();
	}

	public function create() {}

	public function createPost() {}

	public function add(basic:FlxBasic) {
		if (parent != null)
			parent.add(basic);
	}

	public function remove(basic:FlxBasic) {
		if (parent != null)
			parent.remove(basic);
	}

	public function setDefaultGF(name:String) // Fix for the Chart Editor on Base Game stages
	{
		var gfVersion:String = PlayState.SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) {
			gfVersion = name;
			PlayState.SONG.gfVersion = gfVersion;
		}
	}

	public function updatePost(elapsed:Float) {}
	public function stepHit() {}
	public function beatHit() {}
	public function sectionHit() {}
}
