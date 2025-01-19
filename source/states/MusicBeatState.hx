package states;

import backend.Conductor.BPMChangeEvent;
import flixel.FlxG;
import openfl.system.System;
import flixel.addons.ui.FlxUIState;
import backend.FunkinState;

class MusicBeatState extends FunkinState {
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var totalSection:Int = 0;

	public var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public var stages:Array<BaseStage> = [];

	var loops:Float = 30;

	override  function create() {
		super.create();
		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float) {
		// everyStep();

		openfl.system.System.gc();
		var oldStep:Int = curStep;
		var oldSection:Int = totalSection;
		updateCurStep();
		updateBeat();
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		if (oldSection != totalSection && totalSection >= 0)
			sectionHit();

		super.update(elapsed);
		if(FlxG.keys.justPressed.FIVE) {
			PolymodHandler.forceReloadAssets();
			FlxG.switchState(new Title());
		}
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
		System.gc();
	}

	public function beatHit():Void {
		openfl.system.System.gc();
	
		stagesFunc(function(stage:BaseStage) {
			stage.beatHit();
		});
	}

	public function stagesFunc(?func:(stage:BaseStage) -> Void) {
		if (func == null)
			return;
		for (i in 0...stages.length) {
			var stage:BaseStage = stages[i];
			func(stage);
		}
	}

	public function sectionHit():Void {}

	public function addStage(stage:BaseStage) {
		if (!stages.contains(stage))
			stages.push(stage);
	}
}
