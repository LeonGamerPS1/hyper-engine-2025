package states;

import backend.Conductor.BPMChangeEvent;
import flixel.addons.ui.FlxUISubState;


class MusicBeatSubState extends FlxUISubState {
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var totalSection:Int = 0;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float) {
		// everyStep();
		var oldStep:Int = curStep;
		var oldSection:Int = totalSection;
		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		if (oldSection != totalSection && totalSection >= 0)
			sectionHit();

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
		for (i in 0...Conductor.bpmChangeMap.length) {
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);

		totalSection = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / (Conductor.crochet * 4));
	}

	public function stepHit():Void {
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void {}

	public function sectionHit():Void {}
}
