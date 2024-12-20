package ofl.fps;

import haxe.Timer;
import openfl.display.FPS;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FPS_Mem extends TextField {
	private var times:Array<Float>;

	private var memPeak:Float = 0;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0xFFFFFF) {
		super();

		x = inX / 2;
		y = inY /2;

		selectable = false;

		defaultTextFormat = new TextFormat("_sans", 13, inCol);

		text = "FPS: ";

		times = [];

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 150;

		height = 70;
	}

	private function onEnter(_) {
		var now = Timer.stamp();

		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;

		if (mem > memPeak)
			memPeak = mem;

		if (visible) {
			text = "FPS: " + times.length + "\nMemory: " + mem + "MB";
		}
	}
}
