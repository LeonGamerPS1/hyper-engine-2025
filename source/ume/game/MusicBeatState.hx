package ume.game;

import flixel.addons.ui.FlxUIState;
import ume.backend.Controls;
import ume.backend.PlayerSettings;
import ume.backend.SongConductor;

class MusicBeatState extends FlxUIState {
	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create() {
		super.create();
	}

	override function update(elapsed:Float) {
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...SongConductor.bpmChangeMap.length) {
			if (SongConductor.time >= SongConductor.bpmChangeMap[i].songTime)
				lastChange = SongConductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((SongConductor.time - lastChange.songTime) / SongConductor.stepCrochet);
	}

	public function stepHit():Void {
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void {
		// do literally nothing dumbass
	}
}
